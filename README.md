# g14chargefix

Makes an ASUS ROG Zephyrus G14 respect its battery charge limit on Linux, by re-sending the limit to the firmware every time the charger is plugged in or unplugged.

Tested on a GA403WW (BIOS 310) on Arch-based Linux with asusctl 6.5.0. It should be safe to try on other ASUS laptops that use `BAT1` and `ACAD`, but it hasn't been tested on them.

## The problem

You set a limit such as 85% in ROG Control Center, but the battery still charges to 100%.

Nothing looks wrong when you check. `asusctl battery info` and `charge_control_end_threshold` both report 85%, because they show the last value sent to the firmware, not the limit the firmware is actually enforcing.

What testing showed:

- A limit sent while plugged in takes effect within seconds.
- A limit set while unplugged didn't hold: the battery charged from 57% to 100% after the charger was connected.
- asusd only sends the limit at boot and when the setting changes, not when the charger is connected.

The suspected cause is the firmware dropping the limit when the charger is connected. This isn't fully confirmed.

## How the fix works

1. A udev rule runs whenever the charger state changes.
2. The script waits 3 seconds, reads the current limit and writes the same value back, which sends it to the firmware again.
3. It logs the result to the system journal.

The script doesn't store a limit of its own. It re-sends whatever is currently set, so you can keep changing the limit the usual way.

## Requirements

- `asusctl` and its `asusd` service, which restores your limit at boot
- A battery at `BAT1` and a charger at `ACAD`. Check with `ls /sys/class/power_supply/`. If your names differ, edit `asus-reapply-charge-limit` and `99-asus-charge-limit.rules`.

## Install

```
git clone https://github.com/guruthechosen/g14chargefix.git
cd g14chargefix
./install.sh
```

The installer needs `sudo`. It takes effect immediately, with no reboot, and adds these two files:

- `/usr/local/bin/asus-reapply-charge-limit`
- `/etc/udev/rules.d/99-asus-charge-limit.rules`

## Usage

There's nothing to run day to day. Set your limit in ROG Control Center, or with:

```
asusctl battery limit 85
```

The limit stops charging but doesn't drain the battery. If the battery is already above the limit, it stays there until you use it on battery and it drops below the limit.

If you edit the script later, run `./install.sh` again to install the new copy.

## Check that it works

Unplug the charger, plug it back in, then run:

```
journalctl -t asus-charge-limit -n 5
```

You should see one line for each plug and unplug:

```
re-applied charge limit 85%
```

To test the limit itself, drain the battery well below your limit, plug in, and check again once it passes the limit:

```
cat /sys/class/power_supply/BAT1/current_now
```

`0` means no charging current is flowing. Use this instead of the `status` file, which can say `Charging` while no current is flowing.

## Things to know

- **It may stop a few percent above your limit.** The firmware may count percentage against the battery's original capacity, so a worn battery can stop higher on screen. With about 95% battery health, a limit of 85% may stop around 89–90%. To stop nearer 85%, try setting 80–81%.
- **You can see the last 24 hours of battery percentage** without root, to check whether it went past the limit. Each entry is a Unix timestamp, the percentage, and a state code (`1` charging, `2` discharging, `4` full):

  ```
  gdbus call --system --dest org.freedesktop.UPower \
    --object-path /org/freedesktop/UPower/devices/battery_BAT1 \
    --method org.freedesktop.UPower.Device.GetHistory charge 86400 100
  ```

## Status

- **Confirmed:** the rule runs on plug and unplug, and the battery holds when plugged in above the limit.
- **Not yet confirmed:** stopping at the limit when charging up from well below it.

## Uninstall

```
sudo rm /usr/local/bin/asus-reapply-charge-limit /etc/udev/rules.d/99-asus-charge-limit.rules
sudo udevadm control --reload
```
