#!/bin/bash
# Cobbler install script

# 清空界面
clear

# 输入本机IP，作为cobbler的服务IP
while true;do
    read -p "请输入一个本机IP，作为cobbler的服务IP: " LOCAL_IP
    if `ifconfig |grep "$LOCAL_IP" &> /dev/null`;then
        break
    else
        echo "输入的IP不存在，请从新输入"
	continue
    fi
done

# 关闭SElinux
setenforce 0
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config


# 检查epel源是否安装
echo "检查epel源..."
if [ ! -f /etc/yum.repos.d/epel.repo ];then
	echo "正在安装epel源..."
	yum install -y epel-release
	sed -i "s/^#baseurl/baseurl/g" /etc/yum.repos.d/epel.repo
	sed -i "s/^mirrorlist/#mirrorlist/g" /etc/yum.repos.d/epel.repo
	yum clean all
	yum makecache
	echo "epel源安装成功！"
fi

# 安装cobbler和依赖组件
yum install cobbler cobbler-web dhcp tftp-server pykickstart httpd xinetd rsync openssl -y

# 启动xinetd httpd cobblerd服务并加入开机自动启动

start_server() {
    SERVER=(xinetd httpd cobblerd)
    for I in `seq 0 2`;do
        if `systemctl start ${SERVER[$I]}`;then
	    echo "${SERVER[$I]}启动成功..."
	else
	    echo "${SERVER[$I]}启动失败!"
	    exit 1
	fi
	
	if `systemctl enable ${SERVER[$I]}`;then
	    echo "${SERVER[$I]}加入开机自动启动成功..."
	else
	    echo "${SERVER[$I]}加入开机自动启动失败！"
	    exit 1
	fi
    done
}
start_server



# 修改/etc/cobbler/settings配置文件
echo "正在修改配置文件..."
sed -i "s/^server: 127.0.0.1/server: $LOCAL_IP/g"  /etc/cobbler/settings
sed -i "s/^next_server: 127.0.0.1/next_server: $LOCAL_IP/g" /etc/cobbler/settings
sed -i "s/^manage_dhcp: 0/manage_dhcp: 1/g" /etc/cobbler/settings

# 生成一个安装系统后的默认密码，密码为cobbler
PASSWD=`openssl passwd -1 -salt 'salt' 'cobbler'`

# 修改系统安装后的默认密码
sed -i "s/^default_password_crypted.*/default_password_crypted: $PASSWD/g" /etc/cobbler/settings

# 启动rsync
echo "启动rsync..."
systemctl start rsyncd && echo "rsyncd启动成功..." || echo "rsyncd启动失败！请查看日志" || exit 1
systemctl enable rsyncd && echo "rsyncd添加开机自动启动成功..." || echo "rsyncd添加开机自动启动失败！请查看日志" || exit 1
    
# 安装cobbler相关的包
echo "安装cobbler相关包..."
cobbler get-loaders

# 重启cobbler
echo "正在重启cobblerd..."
systemctl restart cobblerd

# 修改dhcp配置
echo "修改dhcp配置"
sed -i "s/subnet 192.168.1.0/subnet $LOCAL_IP/g" /etc/cobbler/dhcp.template
sed -i "s/option routers             192.168.1.5;/option routers             $LOCAL_IP;/g" /etc/cobbler/dhcp.template
sed -i "s/option domain-name-servers 192.168.1.1;/option domain-name-servers 202.103.24.68;/g" /etc/cobbler/dhcp.template

DHCP_IP=`echo "$LOCAL_IP" |sed  -E "s/\.[0-9]+$//g"`

sed -i "s/range dynamic-bootp        192.168.1.100 192.168.1.254/range dynamic-bootp        $DHCP_IP.100 $DHCP_IP.254/g" /etc/cobbler/dhcp.template

echo "同步cobbler..."
cobbler sync && 安装完成！
