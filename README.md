# Deploying a Backstage.io Sandbox Playground the easy way
Starting with Backstage.io from scratch is not always that easy, so to kickstart your journey in a **Data Drive Enterprise** with Backstage.io you can use this (almost fully) automated installation solution of Backstage.io. There are only a few steps you need to do yourself to get started, which will be explained in this document. Keep in mind that this project is work in progress and you can trap in to some bugs at this point. The development of this one-clicker is still in progress!

## Pre-requisites
### VS Code
* Remote SSH extension installed
### Have access to a virtual machine "somewhere"
* VMWare Fusion / Player
** Free, achter requesting a licence on the VMWare website
* Virtualbox
* AWS EC2 Instance - TESTED
** if you have a private account you can use this, there is no Rabo specific data and no compliance / In Control regulations. Deployment will probably be smoother without weird errors or behaviour
** Not tested (stopped testing) in Rabo environment (Development in Rabo subscription is unworkable due regulations and restrictions, even in development subscription.
* Azure VM Instance
** See AWS EC2
* Debian 12 - Minimal / Base install
** Ubuntu and / or earlier versions of Debian is probably also working, but at this point not tested

## Deployment
1. Open VS Code
2. Connect to your VM with SSH
3. Set Environment variables
```
export BS_NAME="Backstage Engineers Hub"
export BS_APP_NAME="Backstage Playground"
```
4. run the following command as a regular user
```
curl -o- https://raw.githubusercontent.com/itmagix/backstage-oneclick/main/install.sh | bash
```

## If everything went well, a browser will be opened connected to the Backstage.io instance
