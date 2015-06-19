#!/bin/bash

yum install -y epel-release pygpgme curl
curl --fail -sSLo /etc/yum.repos.d/passenger.repo https://oss-binaries.phusionpassenger.com/yum/definitions/el-passenger.repo

#chown root: /etc/yum.repos.d/passenger.repo
chmod 600 /etc/yum.repos.d/passenger.repo

yum install -y nginx passenger

# override default config (remove server block, use passenger, don't daemonize)
cp /imgbuild/resources/nginx.conf /etc/nginx/
cp /imgbuild/resources/passenger.conf /etc/nginx/conf.d/
mkdir -p /etc/nginx/main.d
cp /imgbuild/resources/nginx_main.conf /etc/nginx/main.d/

# redirect logs to std*, as is customary on Docker
ln -sf /dev/stdout /var/log/nginx/access.log
ln -sf /dev/stderr /var/log/nginx/error.log
