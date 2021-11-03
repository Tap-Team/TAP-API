#!/bin/sh

# Tapyrus-Core
systemctl start docker
docker start 70ca731e4c53

# IPFS
ipfs daemon &

# Rails
/root/.rbenv/versions/3.0.1/bin/bundle exec /opt/rails/tap-api/bin/rails s -e production