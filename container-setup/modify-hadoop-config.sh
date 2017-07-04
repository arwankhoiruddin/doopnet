#!/bin/bash

usage() {
	echo -e "\nUsage: $0 <hadoop cluster configuration folder>\n"
	exit 1
}

get_one_line () {
	CONFIG=$1
	[ ! -e "$CONFIG" ] && return
	cat $CONFIG | while read LINE ; do
		[ -n "$LINE" ] && echo $LINE && break
	done
}

##################

[ $# != 1 ] && usage
HADOOP_CLUSTER_CONFIG_DIR=$1

HADOOP_ETC_DIR=/home/hduser/hadoop/etc/hadoop
CORE_SITE_XML=$HADOOP_ETC_DIR/core-site.xml
HDFS_SITE_XML=$HADOOP_ETC_DIR/hdfs-site.xml
MAPRED_SITE_XML=$HADOOP_ETC_DIR/mapred-site.xml
YARN_SITE_XML=$HADOOP_ETC_DIR/yarn-site.xml

NAMENODE=`get_one_line $HADOOP_CLUSTER_CONFIG_DIR/namenode` 
SECONDARYNAMENODE=`get_one_line $HADOOP_CLUSTER_CONFIG_DIR/secondarynamenode` 
RESOURCEMANAGER=`get_one_line $HADOOP_CLUSTER_CONFIG_DIR/resourcemanager` 
PROXYSERVER=`get_one_line $HADOOP_CLUSTER_CONFIG_DIR/proxyserver` 
HISTORYSERVER=`get_one_line $HADOOP_CLUSTER_CONFIG_DIR/historyserver` 

if [ -n "$NAMENODE" ] ; then
	sed -i "/<name>.*fs\.defaultFS.*<\/name>/{n;s/<value>.*<\/value>/<value>hdfs:\/\/$NAMENODE:9000<\/value>/;}" $CORE_SITE_XML
	sed -i "/<name>.*dfs\.namenode\.http-address.*<\/name>/{n;s/<value>.*<\/value>/<value>$NAMENODE:50070<\/value>/;}" $HDFS_SITE_XML
fi

[ -n "$SECONDARYNAMENODE" ] && sed -i "/<name>.*dfs\.namenode\.secondary\.http-address.*<\/name>/{n;s/<value>.*<\/value>/<value>$SECONDARYNAMENODE:50090<\/value>/;}" $HDFS_SITE_XML

if [ -n "$RESOURCEMANAGER" ] ; then
	sed -i "/<name>.*yarn\.resourcemanager\.hostname.*<\/name>/{n;s/<value>.*<\/value>/<value>$RESOURCEMANAGER<\/value>/;}" $YARN_SITE_XML
fi

if [ -n "$PROXYSERVER" ] ; then 
	sed -i "/<name>.*yarn\.web-proxy\.address.*<\/name>/{n;s/<value>.*<\/value>/<value>$PROXYSERVER:8081<\/value>/;}" $YARN_SITE_XML
elif [ -n "$RESOURCEMANAGER" ] ; then
	sed -i "/<name>.*yarn\.web-proxy\.address.*<\/name>/{n;s/<value>.*<\/value>/<value>$RESOURCEMANAGER:8081<\/value>/;}" $YARN_SITE_XML
fi

if [ -n "$HISTORYSERVER" ] ; then
	sed -i "/<name>.*mapreduce\.jobhistory\.address.*<\/name>/{n;s/<value>.*<\/value>/<value>$HISTORYSERVER:10020<\/value>/;}" $MAPRED_SITE_XML
	sed -i "/<name>.*mapreduce\.jobhistory\.webapp\.address.*<\/name>/{n;s/<value>.*<\/value>/<value>$HISTORYSERVER:19888<\/value>/;}" $MAPRED_SITE_XML
fi	

