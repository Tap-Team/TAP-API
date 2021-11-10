#!/bin/sh

# docker down
docker-compose down

# git pull
git pull

# docker build
docker-compose build

# docker up -d
docker-compose up -d