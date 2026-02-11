#!/bin/bash

# Prompt for TV IP address
read -p "Enter your TV's IP address: " tv_ip

# Prompt for TV MAC address
read -p "Enter your TV's MAC address: " tv_mac

# Prompt for PC input
read -p "Enter your PC's input (e.g., HDMI_1, HDMI_4): " pc_input

# Update configuration files
echo "Updating configuration files..."

# LG_Buddy_Startup
sed -i "s/tv_ip=\"[^\"]*\"/tv_ip=\"$tv_ip\"/" bin/LG_Buddy_Startup
sed -i "s/tv_mac=\"[^\"]*\"/tv_mac=\"$tv_mac\"/" bin/LG_Buddy_Startup
sed -i "s/input=\"[^\"]*\"/input=\"$pc_input\"/" bin/LG_Buddy_Startup

# LG_Buddy_Shutdown
sed -i "s/tv_ip=\"[^\"]*\"/tv_ip=\"$tv_ip\"/" bin/LG_Buddy_Shutdown
sed -i "s/input=\"[^\"]*\"/input=\"$pc_input\"/" bin/LG_Buddy_Shutdown

# LG_Buddy_sleep
sed -i "s/tv_ip=\"[^\"]*\"/tv_ip=\"$tv_ip\"/" bin/LG_Buddy_sleep
sed -i "s/input=\"[^\"]*\"/input=\"$pc_input\"/" bin/LG_Buddy_sleep

# LG_Buddy_Screen_Off
sed -i "s/tv_ip=\"[^\"]*\"/tv_ip=\"$tv_ip\"/" bin/LG_Buddy_Screen_Off
sed -i "s/input=\"[^\"]*\"/input=\"$pc_input\"/" bin/LG_Buddy_Screen_Off

# LG_Buddy_Screen_On
sed -i "s/tv_ip=\"[^\"]*\"/tv_ip=\"$tv_ip\"/" bin/LG_Buddy_Screen_On
sed -i "s/tv_mac=\"[^\"]*\"/tv_mac=\"$tv_mac\"/" bin/LG_Buddy_Screen_On
sed -i "s/input=\"[^\"]*\"/input=\"$pc_input\"/" bin/LG_Buddy_Screen_On

echo "Configuration updated successfully."
