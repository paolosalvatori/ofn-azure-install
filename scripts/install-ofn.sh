#!/bin/bash

# Variables
gitUsername=$1
gitEmail=$2
gitBranch=$3

# Install packages
#
install_packages() {
  # Set current directory
  cd

  # Install packages
  sudo apt-get install -y --fix-missing at
  sudo apt-get install -y --fix-missing zip unzip
  sudo apt-get install -y --fix-missing python-pip python3-pip 
  sudo apt-get install -y --fix-missing software-properties-common
  sudo apt-get install -y --fix-missing make build-essential libssl-dev zlib1g-dev libbz2-dev libpq-dev
  sudo apt-get install -y --fix-missing libreadline-dev libyaml-dev libsqlite3-dev sqlite3 libxml2-dev libxslt1-dev
  sudo apt-get install -y --fix-missing libcurl4-openssl-dev wget curl llvm libncurses5-dev libncursesw5-dev libpq-dev
  sudo apt-get install -y --fix-missing xz-utils tk-dev libffi-dev liblzma-dev python-openssl git-core git dialog
  sudo apt-get install -y --fix-missing libssl1.0-dev 2>/dev/null

  # Autoremove non-essential packages
  sudo apt-get autoremove -y
}

# Install postgres
#
install_postgres() {
  # Install Postgres
  sudo apt-get install wget ca-certificates
  wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
  sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
  sudo apt-get update -y
  #sudo apt-get install -y postgresql postgresql-contrib 
  sudo apt-get install -y postgresql-9.5 postgresql-common
  #sudo apt-get install -y postgresql-9.5 postgresql-contrib-9.5
  version=$(ls /usr/lib/postgresql)

  # Add postgres path to PATH environment variable
  echo 'export PATH="/usr/lib/postgresql/'$version'/bin:$PATH"' >>~/.bashrc
}

# Install postgres
#
install_pyenv() {
  # Install pyenv
  if [ ! -d "$HOME/.pyenv" ]; then
    echo "$HOME/.pyenv folder does not exist. Cloning pyenv from github..."
    curl https://pyenv.run | bash
    printf 'if [ -d "$HOME/.pyenv" ]; then\n    PYENV_ROOT="$HOME/.pyenv"\n    PATH="$PYENV_ROOT/bin:$PATH"\n    eval "$(pyenv init -)"\n    eval "$(pyenv virtualenv-init -)"\n\nfi\n' >>~/.bashrc
    if [ ! -d "$HOME/.pyenv/plugins/pyenv-virtualenv" ]; then
      echo "$HOME/.pyenv/plugins/pyenv-virtualenv folder does not exist. Cloning pyenv-virtualenv from github..."
      git clone https://github.com/pyenv/pyenv-virtualenv.git $HOME/.pyenv/plugins/pyenv-virtualenv
    else
      echo "$HOME/.pyenv/plugins/pyenv-virtualenv folder already exists."
    fi
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init -)"
    eval "$(pyenv virtualenv-init -)"
    pyenv install -f 3.8.2
    pyenv virtualenv 3.8.2 ofn-install
  else
    echo "$HOME/.pyenv folder already exists."
  fi
}

# Install requirements
#
install_requirements() {
  # Install requirements
  if [ ! -f ~/requirements.txt ]; then
    echo "~/requirements.txt file does not exist. Downloading requirements.txt from github..."
    curl https://raw.githubusercontent.com/openfoodfoundation/ofn-install/master/requirements.txt --output requirements.txt
    pip3 install -r requirements.txt
  else
    echo "~/requirements.txt file already exists."
  fi
}

# Configure Git
#
configure_git() {
  echo 'configuring git...'
  git config --global color.ui true
  git config --global user.name $gitUsername
  git config --global user.email $gitEmail
}

# Install Ruby
#
install_ruby() {
  cd
  if [ ! -d "$HOME/.rbenv" ]; then
    echo "$HOME/.rbenv folder does not exist. Cloning rbenv from github..."
    git clone git://github.com/sstephenson/rbenv.git .rbenv
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >>~/.bashrc
    echo 'eval "$(rbenv init -)"' >>~/.bashrc
    export PATH="$HOME/.rbenv/bin:$PATH"
    eval "$(rbenv init -)"
    source .bashrc
  else
    echo "$HOME/.rbenv folder already exists."
  fi

  if [ ! -d "$HOME/.rbenv/plugins/ruby-build" ]; then
    echo "$HOME/.rbenv/plugins/ruby-build folder does not exist. Cloning ruby-build from github..."
    git clone git://github.com/sstephenson/ruby-build.git ~/.rbenv/plugins/ruby-build
    echo 'export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"' >>~/.bashrc
    export PATH="$HOME/.rbenv/plugins/ruby-build/bin:$PATH"
    source .bashrc
  else
    echo "$HOME/.rbenv/plugins/ruby-build folder already exists."
  fi

  if [ ! -d "$HOME/.rbenv/plugins/rbenv-gem-rehash" ]; then
    echo "$HOME/.rbenv/plugins/rbenv-gem-rehash folder does not exist. Cloning rbenv-gem-rehash from github..."
    git clone https://github.com/sstephenson/rbenv-gem-rehash.git ~/.rbenv/plugins/rbenv-gem-rehash
  else
    echo "$HOME/.rbenv/plugins/rbenv-gem-rehash folder already exists."
  fi

  echo 'Installing ruby...'
  rbenv install -f 2.3.7
  rbenv rehash
  rbenv global 2.3.7
  ruby -v
}

# Install node
#
install_node() {
  if [ ! -d "$HOME/.nodenv" ]; then
    git clone https://github.com/nodenv/nodenv ~/.nodenv --depth 1
    (cd ~/.nodenv && src/configure && make -C src)
    echo 'export PATH="$HOME/.nodenv/bin:$PATH"' >>.bashrc
    echo 'eval "$(nodenv init -)"' >>.bashrc
    export PATH="$HOME/.nodenv/bin:$PATH"
    eval "$(nodenv init -)"
    git clone https://github.com/nodenv/node-build.git "$(nodenv root)/plugins/node-build" --depth 1
    nodenv install -f 5.12.0
  fi
}

# Install gems
#
install_gems() {
  echo 'installing gems...'
  gem install bundler:1.17.3
  gem install zeus
}

# Install Google Chrome
#
install_google_chrome() {
  sudo curl -sS -o - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add
  sudo echo "deb [arch=amd64]  http://dl.google.com/linux/chrome/deb/ stable main" >>/etc/apt/sources.list.d/google-chrome.list
  sudo apt-get -y update
  sudo apt-get -y install google-chrome-stable
}

# Install Google Driver
#
install_google_driver() {
  if [ ! -f ~/chromedriver_linux64.zip ]; then
    echo "~/chromedriver_linux64.zip file does not exist. Downloading chromedriver_linux64.zip..."
    wget https://chromedriver.storage.googleapis.com/2.41/chromedriver_linux64.zip
    unzip chromedriver_linux64.zip
  else
    echo "~/chromedriver_linux64.zip file already exists."
  fi
}

# Install Open Food Network solution
#
install_ofn() {
  # Use git to clone to copy your fork onto the local machine.
  if [ ! -d "$HOME/openfoodnetwork" ]; then
    echo "$HOME/openfoodnetwork folder does not exist. Cloning openfoodnetwork from github..."
    git clone -b $gitBranch https://github.com/$gitUsername/openfoodnetwork.git
  else
    echo "$HOME/openfoodnetwork folder already exists."
  fi

  # Open the folder containing the local copy of the Open Food Network
  cd openfoodnetwork

  # Add an upstream remote that points to the main repo:
  git remote add upstream https://github.com/openfoodfoundation/openfoodnetwork

  # Fetch the latest version of master from upstream (ie. the main repo):
  git fetch upstream master

  # Install the dependencies specified in your Gemfile
  bundle install
}

# Configure Open Food Network solution
#
configure_ofn() {
  # Create the database user used by the app
  sudo -u postgres psql -c "CREATE USER ofn WITH SUPERUSER CREATEDB PASSWORD 'f00d'"

  # Run setup script
  curl https://raw.githubusercontent.com/openfoodfoundation/openfoodnetwork/master/script/setup | bash

  # Create run.sh
  if [ ! -f ~/run.sh ]; then
    echo "~/run.sh file does not exist. Creating run.sh..."
    printf 'cd $HOME/openfoodnetwork\nbundle exec rails server\n' >>~/run.sh
    chmod 777 ~/run.sh
  else
    echo "~/run.sh file already exists."
  fi

  # Schedule run.sh execution to avoid a blocking call
  at now + 1 minute -f $HOME/run.sh
}

# Configure log rotation
#
configure_logrotate() {
  # Create the logrotate configuration file
  cat > ofn <<EOL
/home/azadmin/openfoodnetwork/log/development.log /var/spool/cron/atspool/* {
    # keep 1 worth of backlogs
    rotate 1

    # If the log file is missing, go on to the next one
    # without issuing an error message.
    missingok

    # Do not rotate the log if it is empty,
    # this overrides the ifempty option.
    notifempty

    # Rotate log files daily
    daily

    # Old versions of log files are compressed with gzip by default.
    compress

    # Log files are rotated only if they grow bigger then 50M.
    size 50M

    # Truncate the original log file in place after creating a copy,
    # instead of moving the old log file and optionally creating a new one.
    copytruncate
}
EOL

  # Set read-write permissions on file
  sudo chmod 666 ofn

  # Copy the script to logrotate utility directory
  sudo cp ./ofn /etc/logrotate.d/ofn
}

setup() {
  # Install Packages
  install_packages

  # Install postgres
  install_postgres

  # Install postgres
  install_pyenv

  # Install requirements
  install_requirements

  # Configure Git
  configure_git

  # Install Ruby
  install_ruby

  # Install node
  install_node

  # Install gems
  install_gems

  # Install Google Chrome
  install_google_chrome

  # Install Google Driver
  install_google_driver

  # Install Open Food Network solution
  install_ofn

  # Configure Open Food Network solution
  configure_ofn

  # Configure log rotation
  configure_logrotate
}

# Setup the OFN environment
setup
