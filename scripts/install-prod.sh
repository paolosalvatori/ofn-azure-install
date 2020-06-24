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

json=$(echo $1 | base64 --decode) 
echo $json > json.txt

deployPostgreSQL=$(echo $json | jq -r '.deployPostgreSQL')
serverName=$(echo $json | jq -r '.serverName')
databaseName=$(echo $json | jq -r '.databaseName')
administratorLogin=$(echo $json | jq -r '.administratorLogin')
administratorPassword=$(echo $json | jq -r '.administratorPassword')
adminUsername=$(echo $json | jq -r '.adminUsername')

cat > ./parameters.txt <<EOL
deployPostgreSQL=${deployPostgreSQL}
serverName=${serverName}
databaseName=${databaseName}
administratorLogin=${administratorLogin}
administratorPassword=${administratorPassword}
adminUsername=${adminUsername}
EOL