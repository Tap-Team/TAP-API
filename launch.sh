#!/bin/sh

# IPFS
ipfs daemon

# Rails
/root/.rbenv/versions/3.0.1/bin/bundle exec /opt/rails/tap-api/bin/rails s -e production