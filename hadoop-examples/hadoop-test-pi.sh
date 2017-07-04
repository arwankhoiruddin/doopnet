#!/bin/bash

. /etc/profile.d/java.sh
. /etc/profile.d/hadoop.sh
. $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
. $HADOOP_PREFIX/etc/hadoop/yarn-env.sh

$HADOOP_PREFIX/bin/hadoop jar $HADOOP_PREFIX/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.1.jar pi -Dmapreduce.clientfactory.class.name=org.apache.hadoop.mapred.YarnClientFactory -libjars $HADOOP_PREFIX/share/hadoop/mapreduce/hadoop-mapreduce-client-jobclient-2.7.1.jar 16 10000

