# Deploying a Backstage.io Sandbox Playground the easy way
Starting with Backstage.io from scratch is not always that easy, so to kickstart your journey in a **Data Drive Enterprise** with Backstage.io you can use this (almost fully) automated installation solution of Backstage.io. There are only a few steps you need to do yourself to get started, which will be explained in this document. Keep in mind that this project is work in progress and you can trap in to some bugs at this point. The development of this one-clicker is still in progress!

## Pre-requisites
### VS Code
* Remote SSH extension installed
### Have access to a virtual machine "somewhere"
* VMWare Fusion / Player
    * Free, after requesting a licence on the VMWare website
* Virtualbox
* AWS EC2 Instance - **TESTED**
    * if you have a private account you can use this, there is no Rabo specific data and no compliance / In Control regulations. Deployment will probably be smoother without weird errors or behaviour
    * Not tested (stopped testing) in Rabo environment (Development in Rabo subscription is unworkable due regulations and restrictions, even in development subscription.
* Azure VM Instance - **TESTED**
    * *working*  using Debian 12 VM, with *Standard D2s v3* Size
* Debian 12 - Minimal / Base install
    * Ubuntu and / or earlier versions of Debian is probably also working, but at this point not tested

## Deployment
1. Open VS Code
2. Connect to your VM with SSH
3. Make sure curl and netstat present. If not - install:
   ```
   sudo apt-get install curl
   sudo apt-get install net-tools
   ```   
5. run the following command as a regular user
```
curl -o- https://raw.githubusercontent.com/itmagix/backstage-oneclick/main/install.sh | bash
```
4. After above script is done, VM will restart, reconnect via VSCode SSH after restart is finished
5. Once VM is spun up, `bs-firstboot.sh` will run automatically and boot up Backstage. Monitor `firstboot.log` for verification:
   ```
   tail -f firstboot.log
   ```
   * **NOTE:** This will only happen the first time, next time you restart the VM you have to run `yarn dev` inside `backstage-playground` folder
7. After installation complete check that backstage is running on localhost:3000:
   ```
   netstat -tlpn
   ```
9. To connect to the front-end, open ports *3000* and *7007*. In Visual Studio Code this can be done from the ports tab.
10. Open localhost:3000 to find our deployed Backstage environment.
