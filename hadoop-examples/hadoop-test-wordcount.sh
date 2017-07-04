#!/bin/bash

usage() {
	echo -e "\nUsage: $0 [-r <#reducers>] <in-dir> [<in-dirs>] <out-dir>\n"
	exit 1
}

REDUCER_NUM=1
if [ "$1" = "-r" ] ; then
	[ $# = 1 ] && usage
	REDUCER_NUM=$2
	shift 2
fi 

[ $# -lt 2 ] && usage

SCRIPTS_HOME="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
DOOPNET_HOME=$( cd -P "$SCRIPTS_HOME/../" && pwd -P )

. /etc/profile.d/java.sh
. /etc/profile.d/hadoop.sh
. $HADOOP_PREFIX/etc/hadoop/hadoop-env.sh
. $HADOOP_PREFIX/etc/hadoop/yarn-env.sh

$HADOOP_PREFIX/bin/hadoop jar $HADOOP_PREFIX/share/hadoop/mapreduce/hadoop-mapreduce-examples-2.7.1.jar wordcount -Dmapreduce.job.reduces=$REDUCER_NUM $*

echo -e "\nCheck wordcount output results by:"
echo -e "$DOOPNET_HOME/hadoop-tools/node-hdfs -u <username> dfs -cat ${BASH_ARGV[0]}/*\n"

