#!/bin/bash

usage() {
	echo -e "\nUsage: $0 <docker image name, e.g. ubuntu:hadoop-cluster-test-1> [<users to run Hadoop applications in Dockers>]\n"
	exit 1
}

######

[ $# -lt 1 ] && usage

SCRIPTS_HOME="$( cd -P "$( dirname "${BASH_SOURCE[0]}" )" && pwd -P )"
DOOPNET_HOME=$( cd -P "$SCRIPTS_HOME/../" && pwd -P )

DOCKER_IMAGE=$1
shift
HADOOP_APP_USERS=$*
echo $HADOOP_APP_USERS > $SCRIPTS_HOME/hadoop-app-users.config

mkdir -p $DOOPNET_HOME/tmp
cd $DOOPNET_HOME
tar czf $DOOPNET_HOME/tmp/doopnet.tgz container-setup hadoop-tools netflow-tools hadoop-examples doopnet-examples utils

DOCKERFILE=$DOOPNET_HOME/tmp/Dockerfile
cat > $DOCKERFILE << EOF
FROM ubuntu:14.04
RUN mkdir -p /home/doopnet
COPY doopnet.tgz /home/doopnet
RUN tar xzf /home/doopnet/doopnet.tgz -C /home/doopnet
RUN rm -f /home/doopnet/doopnet.tgz
RUN /bin/bash /home/doopnet/container-setup/setup-hadoop-container.sh
CMD /bin/bash
EOF

#docker build -t ubuntu:hadoop-cluster-test-1 .
docker build -t $DOCKER_IMAGE $DOOPNET_HOME/tmp

rm -f $DOOPNET_HOME/tmp/doopnet.tgz
rm -f $DOCKERFILE
rm -f $SCRIPTS_HOME/hadoop-app-users.config


