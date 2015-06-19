#!/bin/bash

set -ex

cp /imgbuild/resources/my_init /sbin/

mkdir /etc/my_init.d
mkdir /etc/container_environment
