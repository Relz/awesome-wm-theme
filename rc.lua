require("modules/create_class")
require("modules/screen")
require("modules/tag")
require("modules/panel")
require("modules/widgets/cpu_widget")
require("modules/widgets/memory_widget")
require("modules/widgets/network_widget")
require("modules/widgets/battery_widget")
require("modules/widgets/clock_calendar_widget")
require("modules/widgets/power_off_widget")
require("modules/widgets/keyboard_layout_widget")
require("modules/widgets/volume_widget")

require("awful.autofocus")

local awful           = require("awful")
local wibox           = require("wibox")
local gears           = require("gears")
local vicious         = require("vicious")
local beautiful       = require("beautiful")

require("modules/error_handling")

local executer        = require("modules/executer")
local screens_manager = require("modules/screens_manager")

-- | Variable definitions | --

local terminal             = "alacritty"
local browser              = "google-chrome-stable"
local file_manager         = "nautilus"
local graphic_text_editor  = "subl"
local music_player         = "spotify"
local session_lock_command = "dm-tool lock"

-- | Widgets | --

local config_path = awful.util.getdir("config")
beautiful.init(config_path .. "/themes/relz/theme.lua")

local cpu_widget = CpuWidget(beautiful.widget_cpu, beautiful.mode)
local memory_widget = MemoryWidget(beautiful.widget_memory, beautiful.mode)
local battery_widget = BatteryWidget(beautiful.widget_battery_default, beautiful.mode)
local clock_calendar_widget = ClockCalendarWidget(beautiful.widget_clock, beautiful.widget_calendar, beautiful.text_color)
local power_off_widget = PowerOffWidget(beautiful.widget_power_off, session_lock_command)
local network_widget = NetworkWidget(beautiful.widget_network_default, beautiful.mode)
local volume_widget = VolumeWidget(beautiful.widget_volume_default, beautiful.mode)
local keyboard_layout_widget = KeyboardLayoutWidget(beautiful.mode)

-- | Panels | --

local task_left_button_press_action = function(c)
  if c == client.focus then
    c.minimized = true
  else
    c:emit_signal(
      "request::activate",
      "tasklist",
      { raise = true }
    )
  end
end

local screen_0_panel = Panel()
screen_0_panel.position = "top"
screen_0_panel.tags.list = {
  Tag(" 1 ", awful.layout.suit.fair),
  Tag(" 2 ", awful.layout.suit.floating),
  Tag(" 3 ", awful.layout.suit.floating),
  Tag(" 4 ", awful.layout.suit.floating),
  Tag(" 5 ", awful.layout.suit.floating),
}
screen_0_panel.tags.key_bindings = awful.util.table.join(
  awful.button({}, 1, awful.tag.viewonly),
  awful.button({ "Mod4" }, 1, awful.client.movetotag)
)
screen_0_panel.tasks.key_bindings = awful.util.table.join(
  awful.button({}, 1, task_left_button_press_action)
)
screen_0_panel.widgets = {
  cpu_widget,
  memory_widget,
  battery_widget,
  network_widget,
  volume_widget,
  keyboard_layout_widget,
  clock_calendar_widget,
  power_off_widget
}

-- | Screens | --

screen0 = Screen()
screen0.wallpaper = config_path .. "/themes/relz/wallpapers/cosmos_purple.jpg"
screen0.panels = { screen_0_panel }

screen1 = Screen()
screen1.wallpaper = config_path .. "/themes/relz/wallpapers/cosmos_purple.jpg"
screen1.panels = { screen_0_panel }

screens_manager.set_screens({ screen0, screen1 })

screens_manager.apply_screens()

screen.connect_signal("property::geometry", awesome.restart)

-- | Functions | --

-- Brightness

local brightness = function(step, increase)
  local command = "xbacklight ";
  if increase then
    command = command .. "-inc ";
  else
    command = command .. "-dec ";
  end
  command = command .. step;
  awful.spawn(command, false)
end

-- Volume

local mute = function()
  awful.spawn("amixer -D pulse set Master 1+ toggle", false)
end

local volume = function(step, increase)
  local command = "amixer set Master " .. step .. "%";
  if increase then
    command = command .. "+";
  else
    command = command .. "-";
  end
  awful.spawn(command, false)
  vicious.force({ volume_widget.icon })
end

-- Audio

local audio_previous = function()
  awful.spawn("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous", false)
end

local audio_next = function()
  awful.spawn("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next", false)
end

local audio_toggle_play_pause = function()
  awful.spawn("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause", false)
end

local audio_stop = function()
  awful.spawn("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop", false)
end

-- Keyboard layout

local current_keyboard_layout = "us";
local toggle_keyboard_layout = function()
  local command = "setxkbmap -display :0 -layout ";
  if current_keyboard_layout == "us" then
    command = command .. "ru,us";
    current_keyboard_layout = "ru";
  else
    command = command .. "us,ru";
    current_keyboard_layout = "us";
  end
  awful.spawn(command, false)
end

-- Change focused client

local change_focused_client = function(direction)
  awful.client.focus.byidx(direction)
  if client.focus then client.focus:raise() end
end

-- Minimize client

local minimize_client = function(c)
  c.minimized = true  
end

-- Maximize client

local maximize_client = function(c)
  c.maximized_horizontal = not c.maximized_horizontal
  c.maximized_vertical = not c.maximized_vertical
end

-- Toggle client fullscreen

local toggle_fullscreen = function(c)
  c.fullscreen = not c.fullscreen
end

-- Do action for tag by index if tag is defined

local do_for_tag = function(tag_index, action)
  local screen = awful.screen.focused()
  local tag = screen.tags[tag_index]
  if tag then
    action(tag)
  end
end

-- Minimize all clients on focused tag

local minimize_clients = function()
  local tag = awful.tag.selected()
  for i = 1, #tag:clients() do
    minimize_client(tag:clients()[i])
  end
end

-- Restore all clients on focused tag

local restore_clients = function()
  local tag = awful.tag.selected()
  for i = 1, #tag:clients() do
    tag:clients()[i].minimized = false
  end
end

-- Toggle minimize/restore all clients on focused tag

local toogle_minimize_restore_clients = function()
  if client.focus then
    minimize_clients()
  else
    restore_clients()
  end
end

-- | Key bindings | --

local global_keys = awful.util.table.join(
  awful.key({ "Mod4" }, "Tab", function () change_focused_client(1) end, { description="Change focused client to next", group="Client" }),
  awful.key({ "Mod4", "Shift" }, "Tab", function () change_focused_client(-1) end, { description="Change focused client to previous", group="Client" }),

  awful.key({ "Mod4" }, "o", awful.client.movetoscreen, { description="Move to another screen", group="Client" }),
  awful.key({ "Mod4" }, "Cyrillic_shcha", awful.client.movetoscreen),

  awful.key({ "Mod4", "Control" }, "r", awesome.restart, { description="Restart awesome", group="Awesome" }),
  awful.key({ "Mod4", "Control" }, "Cyrillic_ka", awesome.restart),

  awful.key({ "Mod4", "Shift" }, "q", awesome.quit, { description="Quit awesome", group="Awesome" }),
  awful.key({ "Mod4", "Shift" }, "Cyrillic_shorti", awesome.quit),

  awful.key({ "Mod4" }, "l", function() awful.spawn(session_lock_command) end, { description="Lock the session", group="Session" }),
  awful.key({ "Mod4" }, "Cyrillic_de", function() awful.spawn(session_lock_command) end),

  awful.key({ "Mod4" }, "Return", function () awful.spawn(terminal) end, { description="Execute default terminal(" .. terminal .. ")", group="Application" }),

  awful.key({}, "XF86MonBrightnessUp", function () brightness(5, true) end, { description="Increase brightness by 5", group="Brightness" }),
  awful.key({}, "XF86MonBrightnessDown", function () brightness(5, false) end, { description="Decrease brightness by 5", group="Brightness" }),

  awful.key({ "Control" }, "XF86MonBrightnessUp", function () brightness(10, true) end, { description="Increase brightness by 10", group="Brightness" }),
  awful.key({ "Control" }, "XF86MonBrightnessDown", function () brightness(10, false) end, { description="Decrease brightness by 10", group="Brightness" }),

  awful.key({}, "XF86AudioMute", function () mute() end, { description="Toggle sound volume", group="Volume" }),

  awful.key({}, "XF86AudioRaiseVolume", function () volume(5, true) end, { description="Raise volume by 5", group="Volume" }),
  awful.key({}, "XF86AudioLowerVolume", function () volume(5, false) end, { description="Lower volume by 5", group="Volume" }),

  awful.key({ "Control" }, "XF86AudioRaiseVolume", function () volume(10, true) end, { description="Raise volume by 10", group="Volume" }),
  awful.key({ "Control" }, "XF86AudioLowerVolume", function () volume(10, false) end, { description="Lower volume by 10", group="Volume" }),

  awful.key({}, "XF86AudioPrev", function () audio_previous() end, { description="Previous audio", group="Audio" }),
  awful.key({}, "XF86AudioPlay", function () audio_toggle_play_pause() end, { description="Play/Pause audio", group="Audio" }),
  awful.key({}, "XF86AudioNext", function () audio_next() end, { description="Next audio", group="Audio" }),
  awful.key({}, "XF86AudioStop", function () audio_stop() end, { description="Stop audio", group="Audio" }),

  -- Applications running
  awful.key({ "Mod4", "Control", "Shift" }, "b", function() awful.spawn(browser) end, { description="Execute default web browser(" .. browser .. ")", group="Application" }),
  awful.key({ "Mod4", "Control", "Shift" }, "Cyrillic_i", function() awful.spawn(browser) end),

  awful.key({ "Mod4", "Control", "Shift" }, "t", function() awful.spawn("telegram-desktop") end, { description="Execute Telegram", group="Application" }),
  awful.key({ "Mod4", "Control", "Shift" }, "Cyrillic_ie", function() awful.spawn("telegram-desktop") end),

  awful.key({ "Mod4", "Control", "Shift" }, "l", function() awful.spawn("libreoffice") end, { description="Execute LibreOffice", group="Application" }),
  awful.key({ "Mod4", "Control", "Shift" }, "Cyrillic_de", function() awful.spawn("libreoffice") end),

  awful.key({ "Mod4", "Control", "Shift" }, "e", function() awful.spawn(graphic_text_editor) end, { description="Execute default graphic text editor(" .. graphic_text_editor .. ")", group="Application" }),
  awful.key({ "Mod4", "Control", "Shift" }, "Cyrillic_u", function() awful.spawn(graphic_text_editor) end),

  awful.key({ "Mod4", "Control", "Shift" }, "m", function() awful.spawn(music_player) end, { description="Execute default music player(" .. music_player .. ")", group="Application" }),
  awful.key({ "Mod4", "Control", "Shift" }, "Cyrillic_softsign", function() awful.spawn(music_player) end),

  awful.key({ "Mod4", "Control", "Shift" }, "f", function() awful.spawn(file_manager) end, { description="Execute default file manager(" .. file_manager .. ")", group="Application" }),
  awful.key({ "Mod4", "Control", "Shift" }, "Cyrillic_a", function() awful.spawn(file_manager) end),

  awful.key({ "Mod4", "Control", "Shift" }, "j", function() awful.spawn("jetbrains-toolbox") end, { description="Execute Jetbrains-Toolbox", group="Application" }),
  awful.key({ "Mod4", "Control", "Shift" }, "Cyrillic_o", function() awful.spawn("jetbrains-toolbox") end),

  awful.key({ "Mod4" }, "k", function() awful.spawn("xkill") end, { description="Execute XKill", group="Application" }),
  awful.key({ "Mod4" }, "Cyrillic_el", function() awful.spawn("xkill") end),

  awful.key({ "Mod4" }, "\\", function() awful.spawn("arandr") end, { description="Execute ARandr", group="Application" }),

  awful.key({ "Mod4", "Control", "Shift" }, "d", function() awful.spawn("discord") end, { description="Execute Discord", group="Application" }),
  awful.key({ "Mod4", "Control", "Shift" }, "Cyrillic_ve", function() awful.spawn("discord") end),

  awful.key({ "Mod4", "Control", "Shift" }, "]", function() awful.spawn("obs") end, { description="Execute OBS Studio", group="Application" }),
  awful.key({ "Mod4", "Control", "Shift" }, "Cyrillic_hardsign", function() awful.spawn("obs") end),

  awful.key({ "Mod4", "Control", "Shift" }, "s", function() awful.spawn("deepin-screenshot --no-notification") end, { description="Execute Deepin Screen Capture", group="Application" }),
  awful.key({ "Mod4", "Control", "Shift" }, "Cyrillic_yeru", function() awful.spawn("deepin-screenshot --no-notification") end),

  awful.key({ "Mod4", "Control", "Shift" }, "v", function() awful.spawn("viber") end, { description="Execute Viber", group="Application" }),
  awful.key({ "Mod4", "Control", "Shift" }, "Cyrillic_em", function() awful.spawn("viber") end),

  awful.key({ "Mod4", "Control", "Shift" }, "`", function() awful.spawn("deepin-system-monitor") end, { description="Execute Deepin System Monitor", group="Application" }),
  awful.key({ "Mod4", "Control", "Shift" }, "Cyrillic_io", function() awful.spawn("deepin-system-monitor") end),

  awful.key({ "Mod4" }, "w", function() awful.spawn("connman-gtk") end, { description="Execute Connman", group="Application" }),
  awful.key({ "Mod4" }, "Cyrillic_tse", function() awful.spawn("connman-gtk") end),

  awful.key({ "Mod4", "Control", "Shift" }, "k", function() awful.spawn("gitkraken") end, { description="Execute GitKraken", group="Application" }),
  awful.key({ "Mod4", "Control", "Shift" }, "Cyrillic_el", function() awful.spawn("gitkraken") end),

  awful.key({ "Mod4", "Control", "Shift" }, "c", function() awful.spawn("code") end, { description="Execute VSCode", group="Application" }),
  awful.key({ "Mod4", "Control", "Shift" }, "Cyrillic_es", function() awful.spawn("code") end),

  awful.key({}, "Alt_R", toggle_keyboard_layout, { description="Toggle keyboard layout", group="Keyboard" }),

  awful.key({ "Mod4" }, "d", toogle_minimize_restore_clients, { description="Toggle minimize restore clients", group="Client" }),
  awful.key({ "Mod4" }, "Cyrillic_ve", toogle_minimize_restore_clients)
)

local client_keys = awful.util.table.join(
  awful.key({ "Mod4" }, "f", toggle_fullscreen, { description="Toggle fullscreen", group="Client" }),
  awful.key({ "Mod4" }, "Cyrillic_a", toggle_fullscreen),

  awful.key({ "Mod4" }, "F4", function (c) c:kill() end, { description="Kill focused client", group="Client" }),

  awful.key({ "Mod4" }, "n", minimize_client, { description="Minimize client", group="Client" }),
  awful.key({ "Mod4" }, "Cyrillic_te", minimize_client),

  awful.key({ "Mod4" }, "m", maximize_client, { description="Maximize client", group="Client" }),
  awful.key({ "Mod4" }, "Cyrillic_softsign", maximize_client)
)

for i = 1, 9 do
  global_keys = awful.util.table.join(global_keys,
    awful.key({ "Mod4"            }, "#" .. i + 9, function () do_for_tag(i, function(tag) tag:view_only() end) end, { description="View only tag #", group="Tag" }),
    awful.key({ "Mod4", "Control" }, "#" .. i + 9, function () do_for_tag(i, function(tag) awful.tag.viewtoggle(tag) end) end, { description="Add view tag #", group="Tag" }),
    awful.key({ "Mod4", "Shift"   }, "#" .. i + 9, function () do_for_tag(i, function(tag) client.focus:move_to_tag(tag) end) end, { description="Move client to tag #", group="Tag" })
  )
end

awful.menu.menu_keys = {
  up    = { "Up" },
  down  = { "Down" },
  exec  = { "Return", "Space" },
  enter = { "Right" },
  back  = { "Left" },
  close = { "Escape" }
}

root.keys(global_keys)

-- | Rules | --

awful.rules.rules = {
  {
    rule = { },
    properties = {
      border_width = beautiful.border_width,
      border_color = beautiful.border_normal,
      focus = awful.client.focus.filter,
      raise = true,
      keys = client_keys,
      titlebars_enabled = true,
      placement = awful.placement.no_overlap+awful.placement.no_offscreen
    }
  },
  {
    rule = { class = "Ulauncher" },
    properties = {
      border_width = 0,
      titlebars_enabled = false
    }
  },
  {
    rule = { class = "Evince" },
    properties = {
      border_width = 0,
      titlebars_enabled = false
    }
  },
  {
    rule = { class = "Eog" },
    properties = {
      border_width = 0,
      titlebars_enabled = false
    }
  },
  {
    rule = { class = "Google-chrome" },
    properties = {
      border_width = 0,
      titlebars_enabled = false
    }
  },
  {
    rule = { class = "code-oss" },
    properties = {
      border_width = 0,
      titlebars_enabled = false
    }
  }
}

-- Add a titlebar if titlebars_enabled is set to true in the rules.
client.connect_signal("request::titlebars", function(c)
  -- Default buttons for the titlebar
  local buttons = awful.util.table.join(
    awful.button({ }, 1, function()
      client.focus = c
      c:raise()
      awful.mouse.client.move(c)
    end),
    awful.button({ }, 3, function()
      client.focus = c
      c:raise()
      awful.mouse.client.resize(c)
    end)
  )

  awful.titlebar(c, {size = 24}) : setup {
    { -- Left
      wibox.container.margin(awful.titlebar.widget.closebutton(c), 0, 0, 2, 2),
      wibox.container.margin(awful.titlebar.widget.maximizedbutton(c), 0, 0, 2, 2),
      wibox.container.margin(awful.titlebar.widget.minimizebutton(c), 0, 0, 2, 2),
      layout = wibox.layout.fixed.horizontal
    },
    { -- Middle
      { -- Title
        align  = "center",
        widget = awful.titlebar.widget.titlewidget(c)
      },
      buttons = buttons,
      layout  = wibox.layout.flex.horizontal
    },
    { -- Right
      buttons = buttons,
      layout = wibox.layout.fixed.horizontal()
    },
      layout = wibox.layout.align.horizontal
  }
end)

client.connect_signal("manage", function (c, startup)
  c:connect_signal("mouse::enter", function(c)
    if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier and awful.client.focus.filter(c) then
      client.focus = c
    end
  end)

  if not startup and not c.size_hints.user_position and not c.size_hints.program_position then
    awful.placement.no_overlap(c)
    awful.placement.no_offscreen(c)
  end
end)

-- | Autostart | --

executer.execute_commands({
  "wmname LG3D",
  "xfce4-power-manager",
  "picom",
  "/usr/lib/mate-polkit/polkit-mate-authentication-agent-1",
  "xfce4-clipman",
  "nm-applet",
  "ulauncher"
})
