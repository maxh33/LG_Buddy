#!/bin/bash

# Prompt for TV IP address
read -p "Enter your TV's IP address: " tv_ip

# Prompt for TV MAC address
read -p "Enter your TV's MAC address: " tv_mac

# Prompt for PC input
read -p "Enter your PC's input (e.g., HDMI_1): " pc_input

# Update configuration files
echo "Updating configuration files..."
sed -i "s/tv_ip=\"192.168.X.X\"/tv_ip=\"$tv_ip\"/" bin/LG_Buddy_Startup
sed -i "s/tv_mac=\"XX:XX:XX:XX:XX:XX\"/tv_mac=\"$tv_mac\"/" bin/LG_Buddy_Startup
sed -i "s/input=\"HDMI_1\"/input=\"$pc_input\"/" bin/LG_Buddy_Startup

sed -i "s/tv_ip=\"192.168.X.X\"/tv_ip=\"$tv_ip\"/" bin/LG_Buddy_Shutdown

sed -i "s/tv_ip=\"192.168.X.X\"/tv_ip=\"$tv_ip\"/" bin/LG_Buddy_sleep
echo "Configuration updated successfully."

