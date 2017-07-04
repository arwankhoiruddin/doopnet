#!/usr/bin/python

"""
This example shows how to create a simple network and
how to create docker containers (based on existing images)
to it.
"""

import os, errno
from mininet.net import Mininet
from mininet.node import Controller, Docker, OVSSwitch
from mininet.cli import CLI
from mininet.log import setLogLevel, info

class Doopnet (Mininet):
    def __init__( self, dimage=None, hostExchangeFolder=None, *args, **kwargs ):
        self.ipToNameMap = {}
        self.hadoopClusterConfig = {}
        self.containerDoopnetPath = '/home/doopnet'
        self.containerHadoopClusterConfigPath = '/home/hduser/cluster-config'
        self.containerModifyHadoopConfigShell='/bin/bash %s/container-setup/modify-hadoop-config.sh %s' % (self.containerDoopnetPath, self.containerHadoopClusterConfigPath)
        self.setupSshKnownHostsShell = '/bin/bash %s/container-setup/setup-ssh-known-hosts' % self.containerDoopnetPath        
        self.dimage=dimage
        self.hostExchangeFolder=hostExchangeFolder
        Mininet.__init__(self, *args, **kwargs)

    def addDocker( self, name, **params ):
        """
        Wrapper for addHost method that adds a
        Docker container as a host.
        """
        defaults={'dimage': self.dimage, 'hostExchangeFolder': self.hostExchangeFolder}
        defaults.update(params)
        return self.addHost( name, cls=Docker, **defaults )
        
    def defaultHadoopClusterConfig(self):
        for host in self.hosts:
            if host.__class__.__name__ == 'Docker':
                if host.hostname is not None: 
                    docker1Hostname=host.hostname
                else:
                    docker1Hostname=host.name
                break
        self.hadoopClusterConfig={
            'namenode': [docker1Hostname],
            'secondarynamenode': [docker1Hostname],
            'resourcemanager': [docker1Hostname],
            'proxyserver': [docker1Hostname],
            'historyserver': [docker1Hostname]
            }
        allSlaves=[]
        for host in self.hosts:
            if host.__class__.__name__ == 'Docker':
                if host.hostname is not None: 
                    allSlaves += [host.hostname]
                else:
                    allSlaves += [host.name]
        self.hadoopClusterConfig['datanode'] = allSlaves
        self.hadoopClusterConfig['nodemanager'] = allSlaves
        
    def setupHadoopCluster(self, hadoopClusterConfig={}):
        if not self.hadoopClusterConfig:
            self.defaultHadoopClusterConfig()
        self.hadoopClusterConfig.update(hadoopClusterConfig)
        
    def generateHadoopConfig(self):
        for host in self.hosts:        
            if host.__class__.__name__ == "Docker":
                host.cmd('mkdir -p %s' % self.containerHadoopClusterConfigPath)                
                for daemonName in self.hadoopClusterConfig:
                    host.cmd('> %s/%s' % (self.containerHadoopClusterConfigPath, daemonName))
                    for hostname in self.hadoopClusterConfig[daemonName]:
                        host.cmd('echo %s >> %s/%s' % (hostname, self.containerHadoopClusterConfigPath, daemonName))
                host.cmd(self.containerModifyHadoopConfigShell)

    def generateEtcHosts(self):
        for host in self.hosts:
            if host.__class__.__name__ == "Docker":
                hostname = host.hostname
                if hostname is None:
                        hostname = host.name
                for intf in host.intfList():
                    if intf.IP() is not None:
                        self.ipToNameMap.update({intf.IP(): hostname})

        for host in self.hosts:
            if host.__class__.__name__ == "Docker":
                host.cmd('echo 127.0.0.1 localhost > /etc/hosts')
                for ip in sorted( self.ipToNameMap.iterkeys() ):
                    host.cmd('echo %s %s >> /etc/hosts' % (ip, self.ipToNameMap[ip]))

    def setupSshKnownHosts(self):
        for host in self.hosts:
            if host.__class__.__name__ == "Docker":
                host.cmd(self.setupSshKnownHostsShell)
        
    def start( self ):
        Mininet.start(self)
        info( '*** Generating /etc/hosts for dockers\n' )
        self.generateEtcHosts()
        info( '*** Generating Hadoop cluster configurations for dockers\n' )
        if not self.hadoopClusterConfig:
            self.defaultHadoopClusterConfig()
        self.generateHadoopConfig()
        info( '*** Setting up ssh known hosts for remote login between dockers\n' )
        self.setupSshKnownHosts()
        


def doopNetTest():

    "Create a network with some docker containers acting as hosts."

    #net = Mininet( controller=Controller, etcHostsFile='/tmp/mnEtcHosts', doopnetFolder='/home/qys/SFI-SIRG-2015-01-VidSDN/hadoop-on-mininet-testbed/doopnet' )
    #net = Mininet( controller=Controller, doopnetFolder='/home/qys/SFI-SIRG-2015-01-VidSDN/hadoop-on-mininet-testbed/doopnet' )
    #net = Mininet( controller=Controller, etcHostsFile='/tmp/mnEtcHosts' )
    #net = Mininet( controller=Controller)
    net = Doopnet( controller=Controller, autoSetMacs=True, dimage="ubuntu:hadoop-cluster-test-1", hostExchangeFolder='/home/qys/SFI-SIRG-2015-01-VidSDN/hadoop-on-mininet-testbed/doopnet/host-exchange')

    info( '*** Adding controller\n' )
    net.addController( 'c0' )

    # Normal hosts MUST be added before dockers, 
    # otherwise docker cannot exit normally.  
    #info( '*** Adding hosts\n' )
    #h1 = net.addHost( 'h1', ip='10.0.0.201' )
    #h2 = net.addHost( 'h2', ip='10.0.0.202' )
    #h1 = net.addHost( 'h1' )
    #h2 = net.addHost( 'h2' )

    info( '*** Adding docker containers\n' )
    #d1 = net.addDocker( 'd1', ip='10.0.0.1', dimage="ubuntu:hadoop-cluster-test-1" )
    #d2 = net.addDocker( 'd2', ip='10.0.0.2', dimage="ubuntu:hadoop-cluster-test-1" )
    #d3 = net.addDocker( 'd3', ip='10.0.0.3', dimage="ubuntu:hadoop-cluster-test-1" )
    #d1 = net.addDocker( 'd1', dimage="ubuntu:hadoop-cluster-test-1" )
    #d2 = net.addDocker( 'd2', dimage="ubuntu:hadoop-cluster-test-1" )
    #d3 = net.addDocker( 'd3', dimage="ubuntu:hadoop-cluster-test-1" )
    d1 = net.addDocker( 'd1' )
    d2 = net.addDocker( 'd2' )
    d3 = net.addDocker( 'd3' )

    info( '*** Adding switch\n' )
    s1 = net.addSwitch( 's1' )
    # s2 = net.addSwitch( 's2', cls=OVSSwitch )
    # s3 = net.addSwitch( 's3' )

    info( '*** Creating links\n' )
    #net.addLink( h1, s1 )
    #net.addLink( h2, s1 )
    net.addLink( d1, s1 )
    net.addLink( d2, s1 )
    net.addLink( d3, s1 )
    # try to add a second interface to a docker container
    # net.addLink( d2, s3, params1={"ip": "11.0.0.254/8"})
    # net.addLink( d3, s3 )

    info( '*** Setting up Hadoop Cluster\n')
    hadoopClusterConfig={
        'namenode': ['d1'],
        'secondarynamenode': ['d2'],
        'resourcemanager': ['d1'],
        'proxyserver': ['d1'],
        'historyserver': ['d1']
        }
    allSlaves=[]
    for host in net.hosts:
        if host.__class__.__name__ == 'Docker':
            if host.hostname is not None: 
                allSlaves += [host.hostname]
            else:
                allSlaves += [host.name]
    hadoopClusterConfig['datanode'] = allSlaves
    hadoopClusterConfig['nodemanager'] = allSlaves

    net.setupHadoopCluster(hadoopClusterConfig)
    
    info( '*** Starting network\n')
    net.start()

    info( '*** Running CLI\n' )
    CLI( net )

    info( '*** Stopping network' )
    net.stop()

if __name__ == '__main__':
    setLogLevel( 'info' )
    doopNetTest()
