#!/bin/bash

set -ex

# no docs/ref impl for gem (and bundle command that the user can run)
echo "gem: --no-rdoc --no-ri" > ~/.gemrc

gem install bundler

# for bundler to build native extensions
yum install -y ruby-devel gcc gcc-c++

# gem requirements that are pretty much standard
yum install -y nodejs sqlite-devel
