Doopnet
=======

## Introduction
#### Doopnet: Deploying a Hadoop cluster on Docker containers over Mininet and monitoring the Hadoop network traffic through Netflow
* Tested on Ubuntu-14.04
* Require: Docker Engine and Docker image Ubuntu-14.04

#### Doopnet is based on Containernet (formerly called Dockernet) and Hadoop 2.7.1 
* Containernet: https://github.com/mpeuster/containernet (Ref: Manuel Peuster, Holger Karl, and Steven van Rossem. "MeDICINE: Rapid Prototyping of Production-Ready Network Services in Multi-PoP Environments." in IEEE Conference on Network Function Virtualization and Software Defined Network (NFV-SDN), 2016. Link: http://ieeexplore.ieee.org/document/7919490/)
* Hadoop: http://hadoop.apache.org/
* **Note:** Doopnet requires a snapshot of Containernet (containernet.patch is based on the release on 16 Dec 2015). Hadoop-2.7.1 will be downloaded automatically.  

## Reference to this Work
For Doopnet design details, please check the paper below. Please cite this paper if you use Doopnet in your work. 
* Yuansong Qiao, Xueyuan Wang, Guiming Fang, Brian Lee, "Doopnet: An emulator for network performance analysis of Hadoop clusters using Docker and Mininet", IEEE Symposium on Computers and Communication (ISCC), 2016. http://ieeexplore.ieee.org/document/7543832/

## Procedure for running Doopnet

### 1) Install Docker Engine and pull Docker image Ubuntu-14.04
```
# Install Docker Engine. 
# Follow the instructions for Ubuntu Trusty 14.04 [LTS] on the page below:
# https://docs.docker.com/engine/installation/linux/ubuntulinux/

# Pull Docker image Ubuntu-14.04. 
# https://docs.docker.com/engine/reference/commandline/pull/
docker pull ubuntu:14.04
```

### 2) Compile and install containernet
```
# Download containernet
cd doopnet/
git clone https://github.com/mpeuster/containernet.git
cd containernet
git checkout "`git rev-list master  -n 1 --first-parent --before=2015-12-16`"
patch -p1 <../containernet.patch

# Follow the instructions on the Containernet page: https://github.com/mpeuster/containernet. 
cd doopnet/containernet/ansible/
sudo ansible-playbook install.yml 
```

### 3) Build a Docker image for Doopnet 
```
cd doopnet/container-setup/
cp hadoop-memory-default.config.template hadoop-memory-default.config

# Edit hadoop-memory-default.config based on your own preference
vi hadoop-memory-default.config

./build-hadoop-image.sh <Docker image name, e.g. ubuntu:hadoop-cluster-test-1>
# or 
./build-hadoop-image.sh <Docker image name, e.g. ubuntu:hadoop-cluster-test-1> <username to run Hadoop applications, e.g. user1> <user2> <......>
```

### 4) Start-up Mininet and containers
```
cd doopnet-examples/

# Edit doopnet.py: modify the docker image name; modify the host-exchange folder. The host-exchange folder will be mount to /mnt/host-exchange in every Docker container. 
vi doopnet.py

# Run Doopnet
# The default example in doopnet.py will create three containers (mn.d1, mn.d2, and mn.d3) and connect the containers to a switch.
sudo ./doopnet.py

# Inside Mininet console. Make sure all dockers are connected
pingall
```

### 5) Start Netflow, Hadoop cluster and run a test 

**Note:** The Netflow related steps can be skipped if you are not interested in monitoring network flows.

#### 5.1) Inside container mn.d1, start Netflow
```
# Example for entering a container:
docker exec -ti mn.d1 /bin/bash

cd /home/doopnet

# Start Netflow monitors in containers
./netflow-tools/cluster-start-netflow
```

#### 5.2) In the HOST, start the Netflow monitor
```
cd doopnet
sudo ./netflow-tools/host-node-start-netflow <the folder name to save netflow data, e.g. ~/host-exchange/test1>
```

#### 5.3) Inside container mn.d1, start Hadoop cluster
```
# Start Hadoop cluster in the created containers (e.g. mn.d1, mn.d2, and mn.d3)

# For the first time of starting Hadoop
./hadoop-tools/cluster-start-hadoop-first-time

# Otherwise
./hadoop-tools/cluster-start-hadoop
```

#### 5.4) Inside container mn.d1, run a test
```
cd hadoop-examples/
./run-hadoop-test hadoop-test-pi.sh
# or 
./run-hadoop-test -u <username> hadoop-test-pi.sh
```

### 6) Stop all the services

#### 6.1) Inside container mn.d1, stop Hadoop cluster
```
cd /home/doopnet/
./hadoop-tools/cluster-stop-hadoop
```

#### 6.2) Inside container mn.d1, stop the Netflow monitors
```
cd /home/doopnet/
./netflow-tools/cluster-stop-netflow
```

#### 6.3) In the HOST, stop the Netflow monitor
```
cd doopnet
sudo ./netflow-tools/host-node-stop-netflow <the folder name to save netflow data, e.g. ~/host-exchange/test1>
```

### 7) Inside container mn.d1, backup Netflow logs from containers to host
```
cd /home/doopnet/
./netflow-tools/cluster-backup-netflow-logs <Destination foler name, e.g. test1. Will be placed under /mnt/host-hostexchange>
# or 
./hadoop-tools/cluster-backup-everything <Destination foler name, e.g. test1.
 Will be placed under /mnt/host-hostexchange>
# or
./hadoop-tools/cluster-backup-hadoop-logs <Destination foler name, e.g. test1.
 Will be placed under /mnt/host-hostexchange>
```

### 8) Analyse netflow logs, either in the containers or in the HOST 
```
# For example:
nfdump -R /home/hduser/netflow/data | grep 13562
```

### 9) Quit the test
```
# In Mininet console on the HOST
exit
```

## Other useful commands 
```
# In a container
cd /home/doopnet

# Remove all netflow logs
./netflow-tools/cluster-rm-netflow-logs

# Remove all Hadoop logs
./hadoop-tools/cluster-rm-hadoop-logs
```

## Contact
ysqiao [at] research [dot] ait [dot] ie

