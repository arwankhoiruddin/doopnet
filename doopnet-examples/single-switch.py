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
from doopnet import Doopnet

def doopNetTest1():

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
    doopNetTest1()
