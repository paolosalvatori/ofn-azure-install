#!/bin/bash

# Base path for data disk mount points
DATA_BASE="/datadisks"

# Mount options for data disk
MOUNT_OPTIONS="noatime,nodiratime,nodev,noexec,nosuid,nofail"

# log() was missing, added a basic one
log() {
  echo "$1"
}

is_partitioned() {
  OUTPUT=$(partx -s ${1} 2>&1)
  egrep "partition table does not contains usable partitions|failed to read partition table" <<<"${OUTPUT}" >/dev/null 2>&1
  if [ ${?} -eq 0 ]; then
    return 1
  else
    return 0
  fi
}

has_filesystem() {
  DEVICE=${1}
  OUTPUT=$(file -L -s ${DEVICE})
  grep filesystem <<<"${OUTPUT}" >/dev/null 2>&1
  return ${?}
}

scan_for_new_disks() {
  # Looks for unpartitioned disks
  declare -a RET
  DEVS=($(ls -1 /dev/sd* | egrep -v "[0-9]$"))
  for DEV in "${DEVS[@]}"; do
    # The disk will be considered a candidate for partitioning
    # and formatting if it does not have a sd?1 entry or
    # if it does have an sd?1 entry and does not contain a filesystem
    is_partitioned "${DEV}"
    if [ ${?} -eq 0 ]; then
      has_filesystem "${DEV}1"
      if [ ${?} -ne 0 ]; then
        RET+=" ${DEV}"
      fi
    else
      RET+=" ${DEV}"
    fi
  done
  echo "${RET}"
}

get_next_mountpoint() {
  DIRS=$(ls -1d ${DATA_BASE}/disk* 2>/dev/null | sort --version-sort)
  MAX=$(echo "${DIRS}" | tail -n 1 | tr -d "[a-zA-Z/]")
  if [ -z "${MAX}" ]; then
    echo "${DATA_BASE}/disk1"
    return
  fi
  IDX=1
  while [ "${IDX}" -lt "${MAX}" ]; do
    NEXT_DIR="${DATA_BASE}/disk${IDX}"
    if [ ! -d "${NEXT_DIR}" ]; then
      echo "${NEXT_DIR}"
      return
    fi
    IDX=$((${IDX} + 1))
  done
  IDX=$((${MAX} + 1))
  echo "${DATA_BASE}/disk${IDX}"
}

add_to_fstab() {
  UUID=${1}
  MOUNTPOINT=${2}
  grep "${UUID}" /etc/fstab >/dev/null 2>&1
  if [ ${?} -eq 0 ]; then
    echo "Not adding ${UUID} to fstab again (it's already there!)"
  else
    LINE="UUID=\"${UUID}\"\t${MOUNTPOINT}\text4\t${MOUNT_OPTIONS}\t1 2"
    echo -e "${LINE}" >>/etc/fstab
  fi
}

do_partition() {
  # This function creates one (1) primary partition on the
  # disk, using all available space
  _disk=${1}
  _type=${2}
  if [ -z "${_type}" ]; then
    # default to Linux partition type (ie, ext3/ext4/xfs)
    _type=83
  fi
  (
    echo n
    echo p
    echo 1
    echo
    echo
    echo ${_type}
    echo w
  ) | fdisk "${_disk}"

  #
  # Use the bash-specific $PIPESTATUS to ensure we get the correct exit code
  # from fdisk and not from echo
  if [ ${PIPESTATUS[1]} -ne 0 ]; then
    echo "An error occurred partitioning ${_disk}" >&2
    echo "I cannot continue" >&2
    exit 2
  fi
}
#end do_partition

scan_partition_format() {
  log "Begin scanning and formatting data disks"

  DISKS=($(scan_for_new_disks))

  if [ "${#DISKS}" -eq 0 ]; then
    log "No unpartitioned disks without filesystems detected"
    return
  fi
  echo "Disks are ${DISKS[@]}"
  for DISK in "${DISKS[@]}"; do
    echo "Working on ${DISK}"
    is_partitioned ${DISK}
    if [ ${?} -ne 0 ]; then
      echo "${DISK} is not partitioned, partitioning"
      do_partition ${DISK}
    fi
    PARTITION=$(fdisk -l ${DISK} | grep -A 1 Device | tail -n 1 | awk '{print $1}')
    has_filesystem ${PARTITION}
    if [ ${?} -ne 0 ]; then
      echo "Creating filesystem on ${PARTITION}."
      mkfs -j -t ext4 ${PARTITION}
    fi
    MOUNTPOINT=$(get_next_mountpoint)
    echo "Next mount point appears to be ${MOUNTPOINT}"
    [ -d "${MOUNTPOINT}" ] || mkdir -p "${MOUNTPOINT}"
    read UUID FS_TYPE < <(blkid -u filesystem ${PARTITION} | awk -F "[= ]" '{print $3" "$5}' | tr -d "\"")
    add_to_fstab "${UUID}" "${MOUNTPOINT}"
    echo "Mounting disk ${PARTITION} on ${MOUNTPOINT}"
    mount "${MOUNTPOINT}"
  done
}

# Updates the system
#
update_system() {
  # Update the system
  sudo apt-get update -y

  # Upgrade packages
  sudo apt-get upgrade -y

  # Install jq
  sudo apt-get install -y jq
  jq --version

  # Install some required libraries
  sudo apt-get install -y python-pip libgd-dev libgeoip-dev
}


# Variables
#deployPostgreSQL=$1
#serverName=$2
#databaseName=$3
#administratorLogin=$4
#administratorPassword=$5
#adminUsername=$6

#cat > ./parameters.txt <<EOL
#deployPostgreSQL=${deployPostgreSQL}
#serverName=${serverName}
#serverName=${serverName}
#databaseName=${databaseName}
#administratorLogin=${administratorLogin}
#administratorPassword=${administratorPassword}
#adminUsername=${adminUsername}
#EOL

# Install Packages
update_system

echo $1 > base64.txt
json=$(echo $1 | base64 --decode > json.txt)

deployPostgreSQL=$(jq -r '.deployPostgreSQL' json.txt)
serverName=$(jq -r '.serverName' json.txt)
databaseName=$(jq -r '.databaseName' json.txt)
administratorLogin=$(jq -r '.administratorLogin' json.txt)
administratorPassword=$(jq -r '.administratorLoginPassword' json.txt)
adminUsername=$(jq -r '.adminUsername' json.txt)
frontDoorHostname=$(jq -r '.frontDoorHostname' json.txt)

cat > ./parameters.txt <<EOL
deployPostgreSQL=${deployPostgreSQL}
serverName=${serverName}
databaseName=${databaseName}
administratorLogin=${administratorLogin}
administratorPassword=${administratorPassword}
adminUsername=${adminUsername}
EOL

mkdir -p /usr/local/src/ofn-install
git clone https://github.com/ne-msft/ofn-install /usr/local/src/ofn-install -b ofn-azure-v3

bash process-templates.sh secrets.template.yml /usr/local/src/ofn-install/inventory/host_vars/ofn.azure.cuteurl.net/secrets.yml \
    OFN_RANDOM_SECRET_TOKEN=$(openssl rand -hex 128) \
    OFN_DB_NAME=${databaseName} \
    OFN_DB_PASSWORD=${administratorPassword} \
    OFN_DB_HOST=${serverName} \
    OFN_DB_USER=${administratorLogin} \
    OFN_ADMIN_PASSWORD=${administratorPassword}

bash process-templates.sh config.template.yml /usr/local/src/ofn-install/inventory/host_vars/ofn.azure.cuteurl.net/config.yml\
    OFN_DOMAIN=${frontDoorHostname} \
    OFN_HOST_ID=ofn-azure \
    OFN_ADMIN_EMAIL=nierfurt@microsoft.com \
    OFN_MAIL_DOMAIN=ofn.azure.cuteurl.com

cd /usr/local/src/ofn-install
pip install -r requirements.txt
bin/setup
# Due to timing issues the ansible playbook sometimes fails on requesting lets encrypt certificates
# Just re-running the playbook solves the isses
ansible-playbook site.yml --limit=azure -vvv -c local || \
    ansible-playbook site.yml --limit=azure -vvv -c local

