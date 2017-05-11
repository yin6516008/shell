#!/bin/bash
#
yum -y install wget

mv /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.backup

wget -O /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-6.repo

yum clean all

yum makecache

yum -y install vim net-tools epel-release lsof
sed -i "s/^#baseurl/baseurl/g"  /etc/yum.repos.d/epel.repo
sed -i "s/^mirrorlist/#mirrorlist/g" /etc/yum.repos.d/epel.repo
