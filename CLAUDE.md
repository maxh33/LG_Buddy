# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

LG Buddy is a Linux utility that automatically controls LG WebOS TVs (power on/off, input switching) in response to system events: startup, shutdown, sleep, wake, and screen lock/unlock. It uses the `bscpylgtv` Python library to communicate with the TV via WebOS API.

## Architecture

### Core Scripts (bin/)

All scripts are bash and share hardcoded TV configuration variables (tv_ip, tv_mac, input):

- **LG_Buddy_Startup** - Turns TV on at system startup/wake. Uses Wake-on-LAN if TV network is down, then sets input via bscpylgtv
- **LG_Buddy_Shutdown** - Turns TV off at shutdown (ignores reboots by checking systemctl jobs)
- **LG_Buddy_sleep** - Turns TV off when system sleeps. Placed in NetworkManager's pre-down.d dispatcher
- **LG_Buddy_Screen_Monitor** - Uses `swayidle` to detect screen idle/wake via the `ext-idle-notify-v1` Wayland protocol. Works on COSMIC desktop where D-Bus/loginctl methods fail.
- **LG_Buddy_Screen_On** - Wakes TV using Wake-on-LAN + `set_input` command
- **LG_Buddy_Screen_Off** - Puts TV in standby using `power_off` command

### Systemd Services (systemd/)

- **LG_Buddy.service** - System service: runs Startup on start, Shutdown on stop. Enabled at boot
- **LG_Buddy_wake.service** - Oneshot service triggered after suspend/hibernate targets to run Startup
- **LG_Buddy_screen.service** - User service running Screen_Monitor daemon

### Key Dependencies

- **bscpylgtv** - Python library for LG WebOS TV control, installed in `/usr/bin/LG_Buddy_PIP/` venv
- **wakeonlan** - Used to wake TV from deep standby when network is down
- **swayidle** - Wayland idle daemon for detecting screen idle/resume events
- **NetworkManager** - Sleep script relies on NM dispatcher mechanism

## Installation Commands

```bash
# Full installation (prompts for TV config)
./install.sh

# Configure TV settings only
./configure.sh

# Uninstall
./uninstall.sh
```

## Manual Testing Commands

```bash
# Test TV communication directly
/usr/bin/LG_Buddy_PIP/bin/bscpylgtvcommand <tv_ip> get_power_state
/usr/bin/LG_Buddy_PIP/bin/bscpylgtvcommand <tv_ip> power_off
/usr/bin/LG_Buddy_PIP/bin/bscpylgtvcommand <tv_ip> set_input HDMI_4

# Test swayidle detection (timeout in seconds)
swayidle -w timeout 10 'echo IDLE' resume 'echo RESUMED'

# Check if compositor supports ext-idle-notify-v1
wayland-info | grep -i idle

# Run individual scripts manually
/usr/bin/LG_Buddy_Screen_On
/usr/bin/LG_Buddy_Screen_Off

# Check service status
systemctl status LG_Buddy.service
systemctl status LG_Buddy_wake.service
systemctl --user status LG_Buddy_screen.service

# View service logs
journalctl -u LG_Buddy.service
journalctl --user -u LG_Buddy_screen.service -f
```

## Configuration

TV settings are hardcoded at the top of each script in bin/. The configure.sh script uses sed to update these values:
- `tv_ip` - TV's IP address (use DHCP reservation by MAC for stability)
- `tv_mac` - TV's MAC address for Wake-on-LAN
- `input` - HDMI input name (e.g., HDMI_1, HDMI_4)

**Important:** Set `IDLE_TIMEOUT` in `LG_Buddy_Screen_Monitor` to match your desktop's screen blank timeout.

## TV Requirements

For power-on to work reliably:
- **TV Settings → General → Devices → External Devices → Turn on via Wi-Fi** must be **ON**
- **Quick Start+** recommended for faster wake times
- Static IP or DHCP reservation recommended to prevent IP changes

## bscpylgtv Commands

Key commands that work on newer WebOS TVs:
- `power_off` - Put TV in standby (idempotent, safe to call when already off)
- `set_input HDMI_X` - Switch input and wake TV from standby
- `get_power_state` - Returns dict with state ('Active' or 'Active Standby')
- `button POWER` - Toggle power (avoid for automation - use power_off instead)

**Note:** `turn_on` command does NOT work on newer WebOS versions. Use Wake-on-LAN + `set_input` instead.

## Screen Idle Detection (COSMIC Desktop)

The standard D-Bus methods (`org.freedesktop.ScreenSaver`, `loginctl`) do not work on COSMIC desktop. The solution uses `swayidle` with the `ext-idle-notify-v1` Wayland protocol:

```bash
# Check protocol support
wayland-info | grep ext_idle_notifier

# swayidle provides both idle AND resume callbacks
swayidle -w timeout <seconds> '<idle_cmd>' resume '<wake_cmd>'
```

See [TROUBLESHOOTING_SUMMARY.md](TROUBLESHOOTING_SUMMARY.md) for the full history of attempted solutions.
