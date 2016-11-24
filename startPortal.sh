#!/bin/bash
echo "Starting WebSphere Portal ........."

/opt/IBM/WebSphere/wp_profile/bin/startServer.sh WebSphere_Portal

sleep 30

while [ -f "/opt/IBM/WebSphere/wp_profile/logs/WebSphere_Portal/WebSphere_Portal.pid" ]
do
    echo "Waiting for portal to finish starting..."
    sleep 10
done
