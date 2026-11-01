# g14chargefix

Re-applies the battery charge limit on an ASUS ROG Zephyrus G14 whenever the charger is plugged in or unplugged.

Tested on a GA403WW (BIOS 310) with Arch-based Linux and asusctl 6.5.0.

## The problem

With a limit set through `rog-control-center` or `asusctl`, the battery still charged to 100%. `charge_control_end_threshold` kept reading the limit the whole time, because it only shows the last value the kernel sent, not what the firmware is enforcing.

A limit sent while on AC power takes effect within seconds. A limit set while unplugged did not hold after plugging in. asusd only sends the limit at boot and when the setting changes, so the suspected cause is the firmware dropping it on AC plug events. This has not been fully confirmed.

## The fix

A udev rule runs on every AC state change, waits 3 seconds, then writes the current limit back to `charge_control_end_threshold`. It reads the value at that moment, so changing the limit in ROG Control Center or with `asusctl battery limit N` keeps working.

## Install

```
./install.sh
```

This needs `sudo`. It installs:

- `/usr/local/bin/asus-reapply-charge-limit`
- `/etc/udev/rules.d/99-asus-charge-limit.rules`

## Check it works

Unplug and replug the charger, then:

```
journalctl -t asus-charge-limit -n 5
```

You should see a `re-applied charge limit N%` line for each plug and unplug.

To see whether the battery is charging, read `current_now`. `status` can say `Charging` while no current is flowing.

```
cat /sys/class/power_supply/BAT1/current_now
```

## Status

- Confirmed: the rule fires on plug and unplug, and the battery holds when plugged in above the limit.
- Not yet confirmed: stopping at the limit when charging up from well below it.

The firmware may count percentage against the battery's original capacity, so on a worn battery the charge can stop a few percent above the limit on screen.

## Uninstall

```
sudo rm /usr/local/bin/asus-reapply-charge-limit /etc/udev/rules.d/99-asus-charge-limit.rules
sudo udevadm control --reload
```
