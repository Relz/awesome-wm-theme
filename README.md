# Awesome WM theme
A theme for the Awesome window manager 4.x.

# Screenshots

## Light mode

![clear_desktop](https://user-images.githubusercontent.com/15068331/154843667-11603245-25a2-425e-802d-2147bff8bedb.png)
![power_off_menu](https://user-images.githubusercontent.com/15068331/154843753-2479f2bb-8c08-4529-b736-6dd49b6c9b9e.png)
![hotkeys_popup](https://user-images.githubusercontent.com/15068331/154843771-451e975c-8b2a-4b52-bb1f-2628433f3cc0.png)
![clion_titlebar](https://user-images.githubusercontent.com/15068331/154844068-c2ee99bf-641a-47b5-8459-9ac4ae40c64c.png)
![panel_bottom](https://user-images.githubusercontent.com/15068331/154844476-3367c8ed-8e76-400c-87d9-807340a2d19d.png)
![panel_left](https://user-images.githubusercontent.com/15068331/154844669-c16061b8-b9b4-4ae2-80e8-81f2d08e0a80.png)
![panel_right](https://user-images.githubusercontent.com/15068331/154844687-64089518-1c0f-4472-9227-3c4b8416bb7c.png)
![panel_widgets](https://user-images.githubusercontent.com/15068331/154843949-d98b269f-5d5d-4f0c-9fe9-bdbbae9c6953.gif)


## Dark mode

![clear_desktop_dark](https://user-images.githubusercontent.com/15068331/154844205-361cbaed-20fd-4758-96eb-1cc85244bb2b.png)
![power_off_menu_dark](https://user-images.githubusercontent.com/15068331/154844237-49b03c82-0957-4a84-b905-beeb625e80fa.png)
![hotkeys_popup](https://user-images.githubusercontent.com/15068331/154844315-c7596597-156f-4d0a-8d2d-83264d9da8a9.png)
![clion_titlebar_dark](https://user-images.githubusercontent.com/15068331/154844274-2570186b-53c1-47a9-9a64-64996f3cfd1a.png)


# Customization

## Default applications and tools

In rc.lua in section "Variable definitions" you can set some variables:
+ *terminal*. You can execute default terminal by pressing `<Mod4> + <Return>`. Default value: "alacritty".
+ *browser*. You can execute default browser by pressing `<Mod4> + b`. Default value: "google-chrome-stable".
+ *file_manager*. You can execute default file manager by pressing `<Mod4> + f`. Default value: "nautilus".
+ *graphic_text_editor*. You can execute default graphic text editor by pressing `<Mod4> + e`. Default value: "subl".
+ *music_player*. You can execute default music player by pressing `<Mod4> + m`. Default value: "spotify".
+ *session_lock_command*. You can lock your session by pressing `<Mod4> + l`. Also if you choose "Session lock" power off menu item, this command will be executed. Default value: "dm-tool lock".
+ *calendar_command*. Calendar will be executed by clicking on calendar and time widgets. Google calendar is used by default.

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
