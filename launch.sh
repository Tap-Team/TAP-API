#!/bin/sh

# IPFS
ipfs daemon &

# Rails
rails s -e production