# LG Buddy Troubleshooting Summary

This document outlines the steps taken to implement screen-based power control for the LG Buddy application on Pop!_OS with the COSMIC desktop.

### Initial Setup

*   **Problem:** The core application was not installed or configured correctly.
*   **Solution:** An interactive `configure.sh` script was created to handle user-specific settings (IP/MAC address). The main `install.sh` was rewritten to handle all prerequisites, including Python virtual environment creation and `bscpylgtv` installation.
*   **Outcome:** `SUCCESS` - The application is now correctly installed and the base scripts (`LG_Buddy_Startup`, `LG_Buddy_Shutdown`) are functional.

---

### Screen On/Off Implementation Attempts

The goal was to make the TV power off when the screen idles and power on when the user interacts with the mouse or keyboard.

#### Attempt 1: Standard ScreenSaver D-Bus Signal

*   **Method:** Listen for the `ActiveChanged` signal on the `org.freedesktop.ScreenSaver` interface on the user's **session** D-Bus. This is the most common and standard approach.
*   **Outcome:** `FAIL` - It was determined through monitoring that the COSMIC desktop environment does not emit this signal.

#### Attempt 2: `login1` Lock/Unlock D-Bus Signals

*   **Method:** Listen for signals on the `org.freedesktop.login1.Session` interface on the **system** D-Bus.
*   **Discovery:** The `Lock` signal is reliably emitted every time the screen blanks.
*   **Assumption:** The corresponding `Unlock` signal would be emitted on screen wake.
*   **Outcome:** `PARTIAL SUCCESS`
    *   The `Lock` signal proved to be a perfect trigger for turning the TV **OFF**.
    *   Extensive, filtered monitoring proved that the system **never** emits an `Unlock` signal, making this method unworkable for turning the TV **ON**.

#### Attempt 3: Polling `loginctl` IdleHint

*   **Method:** Since D-Bus signals were unreliable for wake-up, a polling script was created. This script repeatedly checked the value of the `IdleHint` property for the user's session via the `loginctl show-session` command.
*   **Discovery:** Direct testing of the command (`loginctl show-session <id> --property=IdleHint --value`) showed that the output was always `no`, regardless of whether the screen was active or idle.
*   **Outcome:** `FAIL` - The COSMIC desktop does not update the `IdleHint` property, so a change in state could never be detected.

#### Attempt 4: `UPower` DeviceChanged D-Bus Signal

*   **Method:** A full analysis of the system D-Bus log revealed a `DeviceChanged` signal from the `org.freedesktop.UPower` interface that appeared to coincide with the wake-up event.
*   **Outcome:** `FAIL` - While the signal was present, it did not work as a trigger for turning the TV on. It may fire for other reasons or at the wrong time.

#### Attempt 5: Polling `loginctl is-locked-session`

*   **Method:** A new polling script was created to use the `loginctl is-locked-session <id>` command. This was believed to be a more direct and reliable way to check the screen's lock state compared to the `IdleHint` property.
*   **Outcome:** `FAIL` - Inexplicably, this method also failed to detect the screen becoming idle. It seems that on this specific OS version, the screen blanks/locks without this status being reflected by `loginctl`.

---

### Attempt 6: swayidle with ext-idle-notify-v1 Wayland Protocol (SUCCESS!)

*   **Method:** Instead of relying on D-Bus or systemd/loginctl, use the Wayland-native `ext-idle-notify-v1` protocol via `swayidle`. This protocol is designed specifically for idle/resume detection on Wayland compositors.
*   **Discovery:**
    *   COSMIC's compositor (cosmic-comp) supports `ext_idle_notifier_v1` (verified via `wayland-info | grep idle`)
    *   `swayidle` can listen for both `idle` AND `resume` events from the compositor
*   **Implementation:**
    ```bash
    swayidle -w timeout 120 '/usr/bin/LG_Buddy_Screen_Off' resume '/usr/bin/LG_Buddy_Screen_On'
    ```
*   **Key Fixes Required:**
    1. **Screen Off:** Use `power_off` command directly instead of checking `get_power_state` first (the check was timing out and incorrectly assuming TV was off)
    2. **Screen On:** Wake-on-LAN must be sent first, then wait 8 seconds for TV to accept WebSocket connections before sending `set_input`. The `turn_on` command does NOT work on newer WebOS versions.
    3. **IP Stability:** DHCP reservation by MAC address prevents IP changes that break connectivity
*   **Outcome:** `SUCCESS` - Both TV power off (on idle) and power on (on resume) now work reliably!

---

### Final Working Solution

**LG_Buddy_Screen_Monitor** now uses:
```bash
exec swayidle -w \
    timeout "$IDLE_TIMEOUT" '/usr/bin/LG_Buddy_Screen_Off' \
    resume '/usr/bin/LG_Buddy_Screen_On'
```

**LG_Buddy_Screen_Off:**
- Simply calls `bscpylgtvcommand <ip> power_off`
- No state checking needed (idempotent)

**LG_Buddy_Screen_On:**
- Sends Wake-on-LAN packet
- Waits 8 seconds for TV to boot
- Calls `set_input HDMI_X` (this also wakes the TV)

**Dependencies added:**
- `swayidle` - Wayland idle daemon
- `wayland-utils` - For debugging protocol support

### Lessons Learned

1. **COSMIC desktop does not follow freedesktop standards** for idle/lock signaling via D-Bus
2. **Wayland-native protocols** (`ext-idle-notify-v1`) are more reliable than D-Bus for desktop-compositor interactions
3. **LG WebOS TV quirks:**
   - `turn_on` command doesn't work on newer TVs - use WoL + `set_input` instead
   - `get_power_state` can timeout even when TV is on - don't rely on it for state checks
   - TV needs ~8 seconds after WoL before accepting WebSocket commands
   - Rate limiting ("Try Again Later") occurs if commands sent too quickly after standby
