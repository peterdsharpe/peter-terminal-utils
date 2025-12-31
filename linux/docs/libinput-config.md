# libinput-config: Scroll Speed Adjustment

## What It Does

Adjusts scroll speed for mouse/touchpad via libinput interception.
Current setting: `scroll-factor=0.5` (half speed)

## How It Works

Uses LD_PRELOAD to inject a shim library that intercepts libinput scroll events and applies a multiplier before passing them to applications.

**Files:**
- `/usr/local/lib64/libinput-config.so` - the preload library
- `/etc/ld.so.preload` - tells the dynamic linker to load it for all processes
- `/etc/libinput.conf` - configuration (scroll-factor setting)

## The "Cannot Be Preloaded" Error

When launching sandboxed apps (Flatpak/Snap) from a terminal, you may see:

```
ERROR: ld.so: object '/usr/local/lib64/libinput-config.so' from /etc/ld.so.preload cannot be preloaded (cannot open shared object file): ignored.
```

**This is harmless.** Sandboxed apps:

1. Have isolated filesystems and can't see `/usr/local/lib64`
2. Bundle their own libinput library anyway
3. Would never benefit from the preload even if they could access it

Native apps work correctly with the adjusted scroll speed. The error only appears when launching sandboxed apps from a terminal - it doesn't affect functionality.

## Configuration

Edit `/etc/libinput.conf` to change the scroll factor:

```ini
scroll-factor=0.5
```

Values less than 1.0 slow scrolling; values greater than 1.0 speed it up.

Changes take effect for newly launched applications (no reboot required).

## Uninstall

To remove libinput-config entirely:

```bash
sudo rm /usr/local/lib64/libinput-config.so
sudo sed -i '/libinput-config.so/d' /etc/ld.so.preload
sudo rm /etc/libinput.conf
```

## Source

https://gitlab.com/warningnonpotablewater/libinput-config
