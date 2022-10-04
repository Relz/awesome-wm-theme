# Awesome WM theme
A theme for the Awesome window manager 4.x.

# Screenshots

## Light mode

![clear_desktop](https://user-images.githubusercontent.com/15068331/185809772-29cfcdde-2436-4e4d-b68f-eebadc553b74.png)
![hotkeys_popup](https://user-images.githubusercontent.com/15068331/185809914-92d8d20d-410e-4f54-a648-757035480f1f.png)
![titlebar](https://user-images.githubusercontent.com/15068331/185809961-f05c41bf-7c3c-4966-bc40-da1041e0cdaa.png)
![panel_bottom](https://user-images.githubusercontent.com/15068331/185810214-0164360e-64f5-4fc3-9306-182b180b9fe3.png)
![panel_left](https://user-images.githubusercontent.com/15068331/185810249-34c180f6-72d4-45ec-82b1-658e7ffbbf9c.png)
![panel_right](https://user-images.githubusercontent.com/15068331/185810265-2eda131c-71be-4770-92c4-9aac2b8d7983.png)
![panel_widgets](https://user-images.githubusercontent.com/15068331/185811162-9843d1c5-aa07-4853-95c1-1084c723fa7c.gif)


## Dark mode

![clear_desktop_dark](https://user-images.githubusercontent.com/15068331/185811217-cce8cf27-4f8e-4ed7-a17e-2b50d2b1a329.png)
![hotkeys_popup_dark](https://user-images.githubusercontent.com/15068331/185811232-d00e821b-bc02-46f9-870e-beab08547eac.png)
![titlebar_dark](https://user-images.githubusercontent.com/15068331/185811256-539f638c-d20f-4e3e-82a7-6d80f4cbf297.png)

# Prerequisites

+ Awesome WM 4.x
+ Lain for Awesome WM 4.x
+ Vicious widgets for the Awesome WM 4.x
+ Droid Sans font (otherwise use another font in theme.lua)
+ LightDM (otherwise specify another session_lock_command in rc.lua)
+ wireless_tools (otherwise Network widget won't work)
+ redshift (otherwise Brightness widget won't let you setup color temperature)
+ geoclue (otherwise Brightness widget won't compute dusk time and dawn time for your geolocation)
+ PulseAudio or PipeWire (otherwise Volume widget won't let you choose input/output devices)

# Installation

```
> git clone https://github.com/Relz/awesome-wm-theme.git ~/.config/awesome
```

# Customization

## Default applications and tools

In rc.lua in section "Variable definitions" you can set some variables:
+ *terminal*. You can execute default terminal by pressing `<Mod4> + <Return>`. Default value: "alacritty".
+ *browser*. You can execute default browser by pressing `<Mod4> + <Control> + <Shift> + b`. Default value: "google-chrome-stable".
+ *file_manager*. You can execute default file manager by pressing `<Mod4> + <Control> + <Shift> + f`. Default value: "nautilus".
+ *graphic_text_editor*. You can execute default graphic text editor by pressing `<Mod4> + <Control> + <Shift> + e`. Default value: "subl".
+ *music_player*. You can execute default music player by pressing `<Mod4> + <Control> + <Shift> + m`. Default value: "spotify".
+ *session_lock_command*. You can lock your session by pressing `<Mod4> + l`. Also if you choose "Session lock" power off menu item, this command will be executed. Default value: "dm-tool lock".
+ *calendar_command*. Calendar will be opened by clicking on calendar and time widgets. Google calendar is used by default.
+ *power_manager_settings_command*. Power manager settings will be opened by clicking on battery widget. Xfce4 Power Manager Settings is used by default.
+ *system_monitor_command*. System monitor will be opened by clicking on CPU and memory widget. Gnome System Monitor is used by default.
+ *network_configuration_command*. Network configuration will be opened by clicking on network widget. NetworkManager Connection Editor is used by default.

## Panels

In rc.lua in section "Panels" you can declare panel(s). Object of class "Panel" has properties:
+ *position*. Panel's position. Possible values: "top", "bottom", "left", "right".
+ *tags.list*. Panel's list of tags. Constructor parameters of class "Tag": text and layout.
+ *widgets*. Panel's list of widgets. Widget must have properties *value* and/or *icon*.

## Screens

In rc.lua in section "Screens" you can declare screen(s). Object of class "Screen" has properties:

+ *wallpaper*. Path to wallpaper.
+ *panels*. List of panels.

## Widgets

In rc.lua in section "Widgets" you can setup widgets. Most widgets support single icon view and icon + label view. Setting first constructor argument to true enables icon + label view.

## Key bindings

In rc.lua in section "Key bindings" you can set key bindings. There are author's key binding, so you should leave only necessary ones for you, but don't remove awesome-specific, system-specific and default application specific key bindings.

## Client rules

In rc.lua in section "Rules" you can set rules for clients. For example, some applications have own titlebar so Awesome WM titlebar is needless for them.

![application_with_own_titlebar](https://user-images.githubusercontent.com/15068331/185811684-56762212-3826-49c1-8366-cb2d0b2cf162.png)


## Autostart

In rc.lua in section "Autostart" you can set commands to execute during Awesome WM startup.

## Theme mode

You can switch theme mode in menu.

PS: also in rc.lua and theme.lua you can make your own experiments, suggestions are appreciated. For example, you can create widget for bluetooth, add calendar popup to ClockCalendarWidget, extend theme modes. Let's make the world better together!

## Extend connected bluetooth device info with battery level

Bluetooth widget shows alias name for connected bluetooth device. There is a way to show battery level also. This feature is not enabled by default. You have to turn on it manually. To do it, edit `bluetooth.service` file by adding `--experimental` flag to bluetooth daemon executing:

```ini
ExecStart=/usr/lib/bluetooth/bluetoothd
```
change to

```ini
ExecStart=/usr/lib/bluetooth/bluetoothd --experimental
```

## Subscribe to Direct Rendering Manager change event

There is `update_screens` function in rc.lua that configures _xrandr_ output. It's useful to call this function when external monitors is connected/disconnected.

To make it happens, you need to add udev rule:
```
ACTION=="change", SUBSYSTEM=="drm", RUN+="notify-awesome %k"
```

Then add script which will be executed to _/lib/udev/notify-awesome_:

```bash
#!/bin/sh

_PID=$(pgrep -x awesome)
_UID=$(ps -o uid= -p $_PID)
USER=$(id -nu $_UID)
DBUS_ADDRESS_VAR=$(cat /proc/$_PID/environ | grep -z "^DBUS_SESSION_BUS_ADDRESS=")

notify() {
    su - $USER -c "/bin/bash \
        -c ' \
            export DISPLAY=:0; \
            export XAUTHORITY='/home/$USER/.Xauthority'; \
            export $DBUS_ADDRESS_VAR; \
            dbus-send --dest=org.awesomewm.awful --type=method_call \
                / org.awesomewm.awful.Remote.Eval string:"update_screens\\\(\\\"$1\\\"\\\)" \
        ' \
    "
}

notify $1 &
```

Then reload udev rules:

```
# udevadm control --reload-rules
```
