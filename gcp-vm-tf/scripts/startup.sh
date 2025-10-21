#!/bin/bash

# This script will run on startup of the VM instance.
# It can be used to install necessary software or configure the environment.

# Update the package list
sudo apt-get update

# Install necessary packages (example: nginx)
sudo apt-get install -y nginx

# Start the nginx service
sudo systemctl start nginx

# Enable nginx to start on boot
sudo systemctl enable nginx

# Additional configuration can be added here as needed.