#!/bin/bash
# Create SWAP File
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
sudo sysctl vm.swappiness=10

# Make SWAP Persistent on boot
sudo sh -c 'echo "/swapfile       swap    swap    defaults        0 0" >> /etc/fstab'

# Configure Persistent SWAP Priority
sudo sh -c 'echo "vm.swappiness=10" >> /etc/sysctl.conf'

# Upgrade system and install required packages
cat << EOF > base-upgrade.sh
#!/usr/bin/sh
sudo apt update
sudo UCF_FORCE_CONFFOLD=1 apt -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" dist-upgrade 
sudo UCF_FORCE_CONFFOLD=1 apt -yq -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" install build-essential git curl tmux zsh bpytop htop neovim
sudo apt-get -qy autoclean
EOF
bash ./base-upgrade.sh >> $HOME/phase1-install.log
rm -rf ./base-upgrade.sh

# Set Neovim as default editor
sudo update-alternatives --set editor $(update-alternatives --list editor | grep nvim) >> $HOME/phase1-install.log

# Remove unused packages
sudo apt-get -qy auto-remove >> $HOME/phase1-install.log
sudo apt-get -qy auto-remove nano >> $HOME/phase1-install.log

# Remove password requirement for regular sudo users
echo "root    ALL=(ALL:ALL) NOPASSWD: ALL" | (sudo su -c 'EDITOR="tee -a" visudo -f /etc/sudoers.d/nopasswd') >> $HOME/phase1-install.log

# Install Backstage.io Sandbox App
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash >> $HOME/phase1-install.log
export NVM_DIR=$HOME/.nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "Installing LTS version of NodeJS" >> $HOME/phase1-install.log
nvm install --lts >> $HOME/phase1-install.log

echo "Installing Yarn globally"
npm install --global yarn >> $HOME/phase1-install.log

echo "Installing Docker CE"
export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
sudo apt-get -yq update >> $HOME/phase1-install.log
sudo apt-get -yq -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install ca-certificates curl gnupg >> $HOME/phase1-install.log
sudo install -m 0755 -d /etc/apt/keyrings >> $HOME/phase1-install.log
sudo curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg >> $HOME/phase1-install.log
sudo chmod a+r /etc/apt/keyrings/docker.gpg >> $HOME/phase1-install.log

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get -qy update >> $HOME/phase1-install.log
sudo apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin >> $HOME/phase1-install.log
sudo gpasswd -a $USER docker >> $HOME/phase1-install.log
sudo systemctl enable --now docker >> $HOME/phase1-install.log


# Did you set the Environment variables?
if [ -z "$BS_APP_NAME" ]; then
    echo "Variable BS_APP_NAME not set, using default" >> $HOME/phase1-install.log
    export BS_APP_NAME="Playground"
    echo "Variable BS_APP_NAME is set to: $BS_APP_NAME" >> $HOME/phase1-install.log
else
    echo "Variable BS_APP_NAME is set to: $BS_APP_NAME" >> $HOME/phase1-install.log
fi

if [ -z "$BS_NAME" ]; then
    echo "Variable BS_APP_NAME not set, using default" >> $HOME/phase1-install.log
    export BS_NAME="My Kingdom"
    echo "Variable BS_NAME is set to: $BS_NAME" >> $HOME/phase1-install.log
else
    echo "Variable BS_NAME is set to: $BS_NAME" >> $HOME/phase1-install.log
fi

# Creating a first-boot script
echo "Creating first-boot script" >> $HOME/phase1-install.log

cat << EOF > bs-firstboot.sh
#!/bin/bash
# Install Backstage.io
export PATH=$PATH:$HOME/.nvm/versions/node/$(node --version)/bin
echo "Installing Backstage.io Playground" > $HOME/firstboot.log
cd $HOME
echo backstage-playground | npx @backstage/create-app@latest
cd backstage-playground

# Setting the correct baseUrl
# sed -i "s/baseUrl: http:\/\/localhost:3000/baseUrl: \"https:\/\/backstage.idpbuilder.cnoe.io.local:8443\"/g" app-config.yaml
sed -i "s/# host: 127.0.0.1/host: 0.0.0.0/g" app-config.yaml
sed -i "s/Scaffolded Backstage App/$BS_APP_NAME/g" app-config.yaml
sed -i "s/name: My Company/name: $BS_NAME/g" app-config.yaml

# Starting Backstage.io
echo "Starting Backstage.io" >> $HOME/firstboot.log

chown -R $USER:$USER $HOME/backstage-playground

echo "Installing new Yarn packages" >> $HOME/firstboot.log
wget -O $HOME/backstage-playground/package.json https://raw.githubusercontent.com/itmagix/backstage-oneclick/feature/first-boot-script-before-deploying-backstage/package.json >> $HOME/firstboot.log

echo "Installing new Yarn packages" >> $HOME/firstboot.log
yarn install >> $HOME/firstboot.log

echo "Starting Backstage.io local development environment" >> $HOME/firstboot.log
su -c 'yarn dev' $USER &

# Self-destruct first-boot script
echo "Self destruct first-boot script" >> $HOME/firstboot.log
systemctl disable --now bs-firstboot.service >> $HOME/phase1-install.log
EOF

cat << EOF > bs-firstboot.service
[Unit]
Description=Your Service Description

[Service]
ExecStart=$HOME/bs-firstboot.sh

[Install]
WantedBy=multi-user.target
EOF

chmod +x bs-firstboot.sh
# sudo mv bs-firstboot.sh /etc/init.d/
sudo mv bs-firstboot.service /etc/systemd/system/
sudo systemctl daemon-reload >> $HOME/phase1-install.log
sudo systemctl enable bs-firstboot.service >> $HOME/phase1-install.log

echo "Phase 1: Done! Rebooting Server!" >> $HOME/phase1-install.log
sudo reboot >> $HOME/phase1-install.log
