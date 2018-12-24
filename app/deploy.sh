#!/bin/sh

#This script deploys the timeoff-management application into a docker container
cd /data/timeoff-management
git pull
docker build --no-cache -t timeoff .
docker stop timeoff-app
docker run -d -it -p 80:3000 --name timeoff-app-tmp timeoff npm start

docker rm timeoff-app
docker rename timeoff-app-tmp timeoff-app