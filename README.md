# Awesome WM theme
A theme for the Awesome window manager 4.x.

# Screenshots

## Light mode

![clear_desktop](https://user-images.githubusercontent.com/15068331/65374092-87018000-dc8e-11e9-8b0a-c68f16d5f604.png)
![cpu_tooltip](https://user-images.githubusercontent.com/15068331/65374803-bfa55780-dc96-11e9-8c6e-2b48fff8cda4.png)
![memory_tooltip](https://user-images.githubusercontent.com/15068331/65374810-caf88300-dc96-11e9-87a5-0aef2d0bd354.png)
![battery_tooltip](https://user-images.githubusercontent.com/15068331/65374834-13b03c00-dc97-11e9-8f41-0224689e1495.png)
![wireless_tooltip](https://user-images.githubusercontent.com/15068331/65374846-20349480-dc97-11e9-93e1-62cc2674db5c.png)
![power_off_menu](https://user-images.githubusercontent.com/15068331/65374851-29256600-dc97-11e9-925b-5a9a39330ee2.png)
![clion_loading_titlebar](https://user-images.githubusercontent.com/15068331/65374885-8f11ed80-dc97-11e9-83b4-225fa622c844.png)
![clion_titlebar](https://user-images.githubusercontent.com/15068331/65374799-b4522c00-dc96-11e9-8049-53e857ead6ca.png)
![git_kraken_titlebar](https://user-images.githubusercontent.com/15068331/65374897-a4871780-dc97-11e9-917b-fb892873f968.png)
![libreoffice_titlebar](https://user-images.githubusercontent.com/15068331/65374904-b1a40680-dc97-11e9-897e-adc0c0f8fc07.png)
![panel_bottom](https://user-images.githubusercontent.com/15068331/65374920-d7311000-dc97-11e9-9f42-f1e066a6da8b.png)
![panel_left](https://user-images.githubusercontent.com/15068331/65374921-d8623d00-dc97-11e9-9321-42facaad9dd6.png)
![panel_right](https://user-images.githubusercontent.com/15068331/65374922-db5d2d80-dc97-11e9-91e2-3721d7bf9040.png)


## Dark mode

![clear_desktop_dark](https://user-images.githubusercontent.com/15068331/65374863-4fe39c80-dc97-11e9-93ee-413251eca201.png)
![cpu_tooltip_dark](https://user-images.githubusercontent.com/15068331/65374873-71dd1f00-dc97-11e9-9d63-7c1cca7fb3f2.png)
![memory_tooltip_dark](https://user-images.githubusercontent.com/15068331/65374866-596d0480-dc97-11e9-889c-7e5bc2a7d6ab.png)
![battery_tooltip_dark](https://user-images.githubusercontent.com/15068331/65374857-40645380-dc97-11e9-8985-832892d7cc2b.png)
![wireless_tooltip_dark](https://user-images.githubusercontent.com/15068331/65374868-612ca900-dc97-11e9-8c9b-8c2103a35426.png)
![power_off_menu_dark](https://user-images.githubusercontent.com/15068331/65374877-83262b80-dc97-11e9-853e-d62c6d0caa53.png)
![clion_loading_titlebar_dark](https://user-images.githubusercontent.com/15068331/65374894-9afdaf80-dc97-11e9-811c-14c8faf1b645.png)
![clion_titlebar_dark](https://user-images.githubusercontent.com/15068331/65374892-989b5580-dc97-11e9-9f7b-b2a11e3dc431.png)
![libreoffice_titlebar_dark](https://user-images.githubusercontent.com/15068331/65374907-b963ab00-dc97-11e9-97ab-4806b4a4a192.png)

# Customization

## Default applications and tools

In rc.lua in section "Variable definitions" you can set some variables:
+ *terminal*. You can execute default terminal by pressing `<Mod4> + <Return>`. Default value: "deepin-terminal".
+ *browser*. You can execute default browser by pressing `<Mod4> + b`. Default value: "firefox".
+ *file_manager*. You can execute default file manager by pressing `<Mod4> + f`. Default value: "dde-file-manager".
+ *graphic_text_editor*. You can execute default graphic text editor by pressing `<Mod4> + e`. Default value: "subl3".
+ *music_player*. You can execute default music player by pressing `<Mod4> + m`. Default value: "deepin-music".
+ *session_lock_command*. You can lock your session by pressing `<Mod4> + l`. Also if you choose "Session lock" power off menu item, this command will be executed. Default value: "dm-tool lock".

## Panels

In rc.lua in section "Panels" you can declare panel(s). Object of class "Panel" has properties:
+ *position*. Panel's position. Possible values: "top", "bottom", "left", "right".
+ *tags.list*. Panel's list of tags. Constructor parameters of class "Tag": text and layout.
+ *widgets*. Panel's list of widgets. Widget must have properties *value* and/or *icon*.

## Screens

In rc.lua in section "Screens" you can declare screen(s). Object of class "Screen" has properties:

+ *wallpaper*. Path to wallpapaer.
+ *panels*. List of panels.

Don't forget to add screens to *screens_manager*. Object *screens_manager* has *set_screens* method to pass list of screens. Multiple screens can be needed for multiple monitors.

## Key bindings

In rc.lua in section "Key bindings" you can set key bindings. There are author's key binding, so you should leave only necessary ones for you, but don't remove awesome-specific, system-specific and default application specific key bindings.

## Cleint rules

In rc.lua in section "Rules" you can set rules for clients. For example, some applications have own titlebar so Awesome WM titlebar is needless for them.

![application_with_own_titlebar](https://user-images.githubusercontent.com/15068331/65379046-78d15500-dcca-11e9-95d2-b570c4a10e0e.png)

## Autostart

In rc.lua in section "Autostart" you can set commands to execute during Awesome WM startup.

## Theme mode

In theme.lua you can set theme mode. Possible values: "light", "dark".

PS: also in rc.lua and theme.lua you can make your own experiments, suggestions are appreciated. For example, you can create widget for bluetooth, add calendar popup to ClockCalendarWidget, extend theme modes. Let's make the world better together!

# Prerequisites

+ Awesome WM 4.x
+ LightDM (if you use *dm-lock* as session lock tool)
+ wireless_tools (if you use NetworkWidget)
+ Lain for Awesome WM 4.x
+ Vicious widgets for the Awesome WM 4.x
+ Fonts: Droid, Noto (otherwise use another fonts in theme.lua instead)

# Installation

```
> git clone https://github.com/Relz/awesome-wm-theme.git
> mv -bv awesome-wm-theme/* ~/.config/awesome; rm -rf awesome-wm-theme
```

# Donate

Webmoney WMR: R120863502096<br>
Webmoney WMZ: Z711863997489<br>
Sberbank: 5469 3700 1107 4044<br>
