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
bash ./base-upgrade.sh
rm -rf ./base-upgrade.sh

# Set Neovim as default editor
sudo update-alternatives --set editor $(update-alternatives --list editor | grep nvim)

# Remove unused packages
sudo apt-get -qy auto-remove
sudo apt-get -qy auto-remove nano

# Remove password requirement for regular sudo users
echo "root    ALL=(ALL:ALL) NOPASSWD: ALL" | (sudo su -c 'EDITOR="tee -a" visudo -f /etc/sudoers.d/nopasswd')

# Install Backstage.io Sandbox App
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
export NVM_DIR=$HOME/.nvm
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

echo "Installing LTS version of NodeJS"
nvm install --lts

echo "Installing Yarn globally"
npm install --global yarn

echo "Installing Docker CE"
export DEBIAN_FRONTEND=noninteractive
export DEBIAN_PRIORITY=critical
sudo apt-get -yq update
sudo apt-get -yq -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get -qy update
sudo apt-get -qy -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo gpasswd -a admin docker
sudo systemctl enable --now docker


# Did you set the Environment variables?
if [ -z "$BS_APP_NAME" ]; then
    echo "Variable BS_APP_NAME not set, using default" >> /home/admin/phase1-install.log
    export BS_APP_NAME="Playground"
    echo "Variable BS_APP_NAME is set to: $BS_APP_NAME" >> /home/admin/phase1-install.log
else
    echo "Variable BS_APP_NAME is set to: $BS_APP_NAME" >> /home/admin/phase1-install.log
fi

if [ -z "$BS_NAME" ]; then
    echo "Variable BS_APP_NAME not set, using default" >> /home/admin/phase1-install.log
    export BS_NAME="My Kingdom"
    echo "Variable BS_NAME is set to: $BS_NAME" >> /home/admin/phase1-install.log
else
    echo "Variable BS_NAME is set to: $BS_NAME" >> /home/admin/phase1-install.log
fi

# Creating a first-boot script
echo "Creating first-boot script" >> /home/admin/phase1-install.log

cat << EOF > bs-firstboot.sh
#!/bin/bash
# Install Backstage.io
export PATH=$PATH:/home/admin/.nvm/versions/node/$(node --version)/bin
echo "Installing Backstage.io Playground" > /home/admin/firstboot.log
cd /home/admin
echo backstage-playground | npx @backstage/create-app@latest
cd backstage-playground

# Setting the correct baseUrl
# sed -i "s/baseUrl: http:\/\/localhost:3000/baseUrl: \"https:\/\/backstage.idpbuilder.cnoe.io.local:8443\"/g" app-config.yaml
sed -i "s/#host: 127.0.0.1/host: 0.0.0.0/g" app-config.yaml
sed -i "s/Scaffolded Backstage App/$BS_APP_NAME/g" app-config.yaml
sed -i "s/name: My Company/name: $BS_NAME/g" app-config.yaml

# Starting Backstage.io
echo "Starting Backstage.io" >> /home/admin/firstboot.log

chown -R admin:admin /home/admin/backstage-playground
cp /home/admin/backstage-oneclick/package.json /home/admin/backstage-playground

su -c 'yarn dev' admin &

# Self-destruct first-boot script
echo "Self destruct first-boot script" >> /home/admin/firstboot.log
systemctl disable --now bs-firstboot.service
EOF

cat << EOF > bs-firstboot.service
[Unit]
Description=Your Service Description

[Service]
ExecStart=/home/admin/backstage-oneclick/bs-firstboot.sh

[Install]
WantedBy=multi-user.target
EOF

chmod +x bs-firstboot.sh
# sudo mv bs-firstboot.sh /etc/init.d/
sudo mv bs-firstboot.service /etc/systemd/system/ 
sudo systemctl daemon-reload
sudo systemctl enable bs-firstboot.service

echo "Jippie het werkt tot zover" >> /home/admin/phase1-install.log
sudo reboot