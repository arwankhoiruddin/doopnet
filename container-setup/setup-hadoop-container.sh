#!/bin/bash

SCRIPTS_HOME="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
DOOPNET_HOME=$( cd -P "$SCRIPTS_HOME/../" && pwd -P )

HADOOP_MEMORY_DEFAULT_CONFIG=$SCRIPTS_HOME/hadoop-memory-default.config
###### Default settings from Hadoop
### hadoop-env.sh
HADOOP_HEAPSIZE="2000"
HADOOP_NAMENODE_INIT_HEAPSIZE="2000"
#### yarn-env.sh
JAVA_HEAP_MAX="-Xmx1000m"
YARN_HEAPSIZE="1000"
YARN_RESOURCEMANAGER_HEAPSIZE="1000"
YARN_TIMELINESERVER_HEAPSIZE="1000"
YARN_NODEMANAGER_HEAPSIZE="1000"
### mapred-env.sh
HADOOP_JOB_HISTORYSERVER_HEAPSIZE="1000"
### yarn-site.xml
YARN_NODEMANAGER_RESOURCE_MEMORY_MB="8192"
YARN_SCHEDULER_MINIMUM_ALLOCATION_MB="1024"
YARN_SCHEDULER_MAXIMUM_ALLOCATION_MB="8192"
YARN_NODEMANAGER_VMEM_PMEM_RATIO="2.1"
### mapred-site.xml
MAPREDUCE_MAP_MEMORY_MB="1024"
MAPREDUCE_REDUCE_MEMORY_MB="1024"
MAPREDUCE_MAP_JAVA_OPTS="-Xmx819m"
MAPREDUCE_REDUCE_JAVA_OPTS="-Xmx819m"
[ -e $HADOOP_MEMORY_DEFAULT_CONFIG ] && . $HADOOP_MEMORY_DEFAULT_CONFIG

### Install required software
apt-get update
apt-get -y install default-jdk ssh rsync
mkdir -p /var/run/sshd
chmod 0755 /var/run/sshd

# Parallel execution tool
apt-get -y install pdsh

# NetFlow tools
apt-get -y install fprobe
apt-get -y install nfdump

# For testing and debuging the network 
apt-get -y install iperf
apt-get -y install tcpdump
[ -e /usr/sbin/tcpdump ] && mv /usr/sbin/tcpdump /usr/bin/tcpdump

### Setup JAVA environment
echo export JAVA_HOME=/usr/lib/jvm/default-java > /etc/profile.d/java.sh
echo export JAVA_HOME=/usr/lib/jvm/default-java >> /root/.bashrc

### Create Hadoop user folder. All hadoop related configurations and run-time folders will be in this folder.
mkdir -p /home/hduser
cd /home/hduser

### Download hadoop-2.7.1 binary 
wget http://ftp.heanet.ie/mirrors/www.apache.org/dist/hadoop/common/hadoop-2.7.1/hadoop-2.7.1.tar.gz
tar xzvf hadoop-2.7.1.tar.gz
ln -s hadoop-2.7.1 hadoop 
rm hadoop-2.7.1.tar.gz

### Setup Hadoop environment
echo export HADOOP_PREFIX=/home/hduser/hadoop > /etc/profile.d/hadoop.sh
echo export HADOOP_PREFIX=/home/hduser/hadoop >> /root/.bashrc

### Setup startup scripts
echo /bin/bash /home/doopnet/container-setup/doopnet-container-init.sh >> /root/.bashrc

### Create hadoop system users
groupadd hadoop
useradd -g hadoop yarn
useradd -g hadoop hdfs
useradd -g hadoop mapred

chown -R hdfs:hadoop hadoop-2.7.1
chown -R hdfs:hadoop hadoop

### Create the hadoop application user
usermod -a -G hadoop root
if [ -e "$SCRIPTS_HOME/hadoop-app-users.config" ] ; then
	HADOOP_APP_USERS=$(cat $SCRIPTS_HOME/hadoop-app-users.config)
	for u in $HADOOP_APP_USERS ; do 
		[ -z "$u" ] && continue
		[ "$u" = "root" ] && continue
		useradd $u
		usermod -a -G hadoop $u

		# Create home folders the Hadoop application user
		mkdir /home/$u
		cp /etc/skel/.* /home/$u
		chown -R sdn:sdn /home/$u
	done
fi

### Create home folders for hadoop users
mkdir /home/hdfs
cp /etc/skel/.* /home/hdfs
chown -R hdfs:hadoop /home/hdfs

mkdir /home/yarn
cp /etc/skel/.* /home/yarn
chown -R yarn:hadoop /home/yarn

mkdir /home/mapred
cp /etc/skel/.* /home/mapred
chown -R mapred:hadoop /home/mapred

### Setup ssh keys for all users
su sdn -c "ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa"
su sdn -c 'cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys'

su hdfs -c "ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa"
su hdfs -c 'cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys'

su yarn -c "ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa"
su yarn -c 'cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys'

su mapred -c "ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa"
su mapred -c 'cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys'

ssh-keygen -t dsa -P '' -f ~/.ssh/id_dsa
cat ~/.ssh/id_dsa.pub >> ~/.ssh/authorized_keys

### Create Hadoop run-time folders
mkdir -p dfs/name
mkdir -p dfs/data
mkdir -p dfs/namesecondary
chown -R hdfs:hadoop dfs

mkdir -p log/hdfs
mkdir -p log/yarn
mkdir -p log/mapred
chown -R hdfs:hadoop log
chown -R yarn:hadoop log/yarn
chown -R mapred:hadoop log/mapred

mkdir -p run/hdfs
mkdir -p run/yarn
mkdir -p run/mapred
chown -R hdfs:hadoop run
chown -R yarn:hadoop run/yarn
chown -R mapred:hadoop run/mapred

mkdir -p tmp
chown hdfs:hadoop tmp
chmod 775 tmp

mkdir -p netflow/data/
mkdir -p netflow/run
chown -R hdfs:hadoop netflow

mkdir cluster-config
chown hdfs:hadoop cluster-config

### Modify hadoop configurations
cd hadoop/etc/hadoop

### hadoop-env.sh
sed -i 's/.*export JAVA_HOME=${JAVA_HOME}.*/export JAVA_HOME=\/usr\/lib\/jvm\/default-java\nexport HADOOP_PREFIX=\/home\/hduser\/hadoop\nexport HDUSER_PREFIX=\/home\/hduser/' hadoop-env.sh

sed -i 's/export HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-"\/etc\/hadoop"}/export HADOOP_CONF_DIR=${HADOOP_CONF_DIR:-"$HADOOP_PREFIX\/etc\/hadoop"}/' hadoop-env.sh

sed -i 's/#export HADOOP_LOG_DIR=${HADOOP_LOG_DIR}\/$USER/export HADOOP_LOG_DIR=$HDUSER_PREFIX\/log\/hdfs/' hadoop-env.sh

sed -i 's/export HADOOP_PID_DIR=${HADOOP_PID_DIR}/export HADOOP_PID_DIR=$HDUSER_PREFIX\/run\/hdfs/' hadoop-env.sh

sed -i "s/#export HADOOP_HEAPSIZE=/export HADOOP_HEAPSIZE=\"$HADOOP_HEAPSIZE\"/" hadoop-env.sh

sed -i "s/#export HADOOP_NAMENODE_INIT_HEAPSIZE=\"\"/export HADOOP_NAMENODE_INIT_HEAPSIZE=\"$HADOOP_NAMENODE_INIT_HEAPSIZE\"/" hadoop-env.sh

### yarn-env.sh
sed -i 's/# User for YARN daemons/export HADOOP_PREFIX=\/home\/hduser\/hadoop\nexport HDUSER_PREFIX=\/home\/hduser\n\n&/' yarn-env.sh

sed -i 's/export YARN_CONF_DIR="${YARN_CONF_DIR:-$HADOOP_YARN_HOME\/conf}"/export YARN_CONF_DIR="${YARN_CONF_DIR:-$HADOOP_PREFIX\/etc\/hadoop}"/' yarn-env.sh

sed -i 's/YARN_LOG_DIR="$HADOOP_YARN_HOME\/logs"/YARN_LOG_DIR="$HDUSER_PREFIX\/log\/yarn"/' yarn-env.sh

sed -i "s/JAVA_HEAP_MAX=-Xmx1000m/JAVA_HEAP_MAX=\"$JAVA_HEAP_MAX\"/" yarn-env.sh

sed -i "s/# YARN_HEAPSIZE=1000/YARN_HEAPSIZE=\"$YARN_HEAPSIZE\"/" yarn-env.sh

sed -i "s/#export YARN_RESOURCEMANAGER_HEAPSIZE=1000/export YARN_RESOURCEMANAGER_HEAPSIZE=\"$YARN_RESOURCEMANAGER_HEAPSIZE\"/" yarn-env.sh

sed -i "s/#export YARN_TIMELINESERVER_HEAPSIZE=1000/export YARN_TIMELINESERVER_HEAPSIZE=\"$YARN_TIMELINESERVER_HEAPSIZE\"/" yarn-env.sh

sed -i "s/#export YARN_NODEMANAGER_HEAPSIZE=1000/export YARN_NODEMANAGER_HEAPSIZE=\"$YARN_NODEMANAGER_HEAPSIZE\"/" yarn-env.sh

echo 'export YARN_PID_DIR="$HDUSER_PREFIX/log/yarn"' >> yarn-env.sh

### mapred-env.sh
sed -i 's/.*# export JAVA_HOME=\/home\/y\/libexec\/jdk1.6.0\/.*/export HADOOP_PREFIX=\/home\/hduser\/hadoop\nexport HDUSER_PREFIX=\/home\/hduser\n&/' mapred-env.sh

sed -i 's/#export HADOOP_MAPRED_LOG_DIR=""/export HADOOP_MAPRED_LOG_DIR="$HDUSER_PREFIX\/log\/mapred"/' mapred-env.sh

sed -i 's/#export HADOOP_MAPRED_PID_DIR=/export HADOOP_MAPRED_PID_DIR="$HDUSER_PREFIX\/log\/mapred"/' mapred-env.sh

sed -i "s/export HADOOP_JOB_HISTORYSERVER_HEAPSIZE=1000/export HADOOP_JOB_HISTORYSERVER_HEAPSIZE=\"$HADOOP_JOB_HISTORYSERVER_HEAPSIZE\"/" mapred-env.sh

### core-site.xml
cat > core-site.xml << EOF
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://d1:9000</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/home/hduser/tmp</value>
    </property>
    <property>
        <name>hadoop.http.staticuser.user</name>
        <value>hdfs</value>
    </property>
</configuration>
EOF

### hdfs-site.xml
cat > hdfs-site.xml << EOF
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/home/hduser/dfs/name</value>
    </property>
    <property>
        <name>dfs.namenode.checkpoint.dir</name>
        <value>/home/hduser/dfs/namesecondary</value>
    </property>
    <property>
        <name>dfs.namenode.checkpoint.edits.dir</name>
        <value>/home/hduser/dfs/namesecondary</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/home/hduser/dfs/data</value>
    </property>
    <property>
        <name>dfs.namenode.http-address</name>
        <value>d1:50070</value>
    </property>
    <property>
        <name>dfs.namenode.secondary.http-address</name>
        <value>d1:50090</value>
    </property>
</configuration>
EOF

### mapred-site.xml
cat > mapred-site.xml << EOF
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.map.memory.mb</name>
        <value>$MAPREDUCE_MAP_MEMORY_MB</value>
    </property>
    <property>
        <name>mapreduce.reduce.memory.mb</name>
        <value>$MAPREDUCE_REDUCE_MEMORY_MB</value>
    </property>
    <property>
        <name>mapreduce.map.java.opts</name>
        <value>$MAPREDUCE_MAP_JAVA_OPTS</value>
    </property>
    <property>
        <name>mapreduce.reduce.java.opts</name>
        <value>$MAPREDUCE_REDUCE_JAVA_OPTS</value>
    </property>
    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>d1:10020</value>
    </property>
    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>d1:19888</value>
    </property>
    <property>
        <name>yarn.app.mapreduce.am.staging-dir</name>
        <value>/mapred</value>
    </property>
</configuration>
EOF

### yarn-site.xml
cat > yarn-site.xml << EOF
<configuration>

<!-- Site specific YARN configuration properties -->
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>$YARN_NODEMANAGER_RESOURCE_MEMORY_MB</value>
    </property>
    <property>
        <name>yarn.scheduler.minimum-allocation-mb</name>
        <value>$YARN_SCHEDULER_MINIMUM_ALLOCATION_MB</value>
    </property>
    <property>
        <name>yarn.scheduler.maximum-allocation-mb</name>
        <value>$YARN_SCHEDULER_MAXIMUM_ALLOCATION_MB</value>
    </property>
    <property>
        <name>yarn.nodemanager.vmem-pmem-ratio</name>
        <value>$YARN_NODEMANAGER_VMEM_PMEM_RATIO</value>
    </property>
    <property>
        <name>yarn.web-proxy.address</name>
        <value>d1:8081</value>
    </property>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>d1</value>
    </property>
</configuration>
EOF


