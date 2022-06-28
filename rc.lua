require("utils")
require("modules/create_class")
require("modules/screen")
require("modules/tag")
require("modules/panel")
require("modules/widgets/cpu_widget")
require("modules/widgets/memory_widget")
require("modules/widgets/network_widget")
require("modules/widgets/brightness_widget")
require("modules/widgets/battery_widget")
require("modules/widgets/calendar_widget")
require("modules/widgets/clock_widget")
require("modules/widgets/menu_widget")
require("modules/widgets/keyboard_layout_widget")
require("modules/widgets/volume_widget")

require("awful.autofocus")

local awful = require("awful")
local gears = require("gears")
local wibox = require("wibox")
local vicious = require("vicious")
local beautiful = require("beautiful")

require("modules/error_handling")

local executer = require("modules/executer")
local screens_manager = require("modules/screens_manager")

local config_path = gears.filesystem.get_configuration_dir()

-- | Variable definitions | --

local terminal = "alacritty"
local browser = "google-chrome-stable"
local file_manager = "nautilus"
local graphic_text_editor = "subl"
local music_player = "spotify"
local session_lock_command = "dm-tool lock"
local calendar_command = "/opt/google/chrome/google-chrome --profile-directory='Profile 2' --app=https://calendar.google.com/calendar"
local power_manager_settings_command = "xfce4-power-manager-settings"
local system_monitor_command = "gnome-system-monitor"
local network_configuration_command = "nm-connection-editor"

local wallpaper_image_path = config_path .. "/themes/relz/wallpapers/cosmos_purple.jpg";
local current_keyboard_layout = "us";

local numpad_key_codes = { 87, 88, 89, 83, 84, 85, 79, 80, 81 }

-- | Widgets | --

beautiful.init(config_path .. "/themes/relz/theme.lua")

local cpu_widget = CpuWidget(false, system_monitor_command)
local memory_widget = MemoryWidget(false, system_monitor_command)
local brightness_widget = BrightnessWidget(100)
local battery_widget = BatteryWidget(true, power_manager_settings_command)
local calendar_widget = CalendarWidget(beautiful.widget_calendar, beautiful.text_color, calendar_command)
local clock_widget = ClockWidget(beautiful.widget_clock, beautiful.text_color, calendar_command)
local menu_widget = MenuWidget(beautiful.widget_menu, session_lock_command)
local network_widget = NetworkWidget(false, network_configuration_command)
local volume_widget = VolumeWidget(true)
local keyboard_layout_widget = KeyboardLayoutWidget(beautiful.mode)

-- | Functions | --

-- Panels

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

-- Brightness

local set_brightness = function(step_percent, increase)
  set_system_brightness(
    step_percent,
    increase,
    function(new_value_percent)
      brightness_widget.update(new_value_percent)
    end
  )
end

-- Volume

local mute = function()
  local command = "amixer -D pulse set Master 1+ toggle"
  awful.spawn.easy_async(command, function() vicious.force({ volume_widget.icon }) end)
end

local set_volume = function(step, increase)
  set_system_volume(step, increase, function() vicious.force({ volume_widget.icon }) end)
end

-- Keyboard layout

local toggle_keyboard_layout = function()
  if current_keyboard_layout == "us" then
    set_keyboard_layout("ru,us");
    current_keyboard_layout = "ru";
  else
    set_keyboard_layout("us,ru");
    current_keyboard_layout = "us";
  end
end

-- | Panels | --

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
  network_widget,
  volume_widget,
  brightness_widget,
  battery_widget,
  keyboard_layout_widget,
  {
    calendar_widget,
    clock_widget,
  },
  menu_widget
}

-- | Screens | --

update_screens = function(card)
  local xrandr_output = run_command_sync("xrandr")
  local primary_output = xrandr_output:match("(eDP[0-9-]+) connected")
  local primary_output_rect = xrandr_output:match("eDP[0-9-]+ connected[a-z ]* ([0-9x+]+) [(]")
  local is_hdmi_in_use = string.match(xrandr_output, "HDMI[0-9-]+ connected [^(]") ~= nil
  local unused_hdmi = xrandr_output:match("(HDMI[0-9-]+) connected [(]")
  local used_hdmi = xrandr_output:match("(HDMI[0-9-]+) connected [^(]")
  local used_hdmi_rect = xrandr_output:match("HDMI[0-9-]+ connected[a-z ]* ([0-9x+]+) [(]")
  local disconnected_hdmi_rect = xrandr_output:match("HDMI[0-9-]+ disconnected[a-z ]* ([0-9x+]+) [(]")
  local is_hdmi_disconnected = unused_hdmi == nil and used_hdmi == nil
  local is_screen_duplicated = primary_output_rect == used_hdmi_rect


  if (not is_hdmi_in_use and unused_hdmi) or is_screen_duplicated then
    local hdmi = is_screen_duplicated and used_hdmi or unused_hdmi

    run_command_sync(
      "xrandr " ..
      "--output " .. primary_output .. " --preferred --primary " ..
      "--output " .. hdmi .. " --right-of " .. primary_output .. " --preferred "
    )
  else
    if is_hdmi_disconnected and disconnected_hdmi_rect then
      run_command_sync("xrandr --auto")
    end
  end

  if card == nil then
    local screen0 = Screen()
    screen0.wallpaper = wallpaper_image_path
    screen0.panels = { screen_0_panel }

    if is_hdmi_in_use and not is_screen_duplicated then
      local screen1 = Screen()
      screen1.wallpaper = wallpaper_image_path
      screen1.panels = { screen_0_panel }

      screens_manager.set_screens({ screen0, screen1 })
    else
      screens_manager.set_screens({ screen0 })
    end

    screens_manager.apply_screens()
  end
end

update_screens()

screen.connect_signal("added", function()
  if screen.count() > screens_manager.get_screen_count() then
    local newScreen = Screen()
    newScreen.wallpaper = wallpaper_image_path
    newScreen.panels = { screen_0_panel }

    screens_manager.add_screen(newScreen)
  end
  screens_manager.apply_screen(screens_manager.get_screen_count())
end)

-- | Key bindings | --

local global_keys = awful.util.table.join(
  awful.key({ "Mod4" }, "/", show_help, { description="Show hotkeys", group="Awesome" }),
  awful.key({ "Mod4" }, ".", show_help),

  awful.key({ "Mod4" }, "Tab", function () change_focused_client(1) end, { description="Change focused client to next", group="Client" }),
  awful.key({ "Mod4", "Shift" }, "Tab", function () change_focused_client(-1) end, { description="Change focused client to previous", group="Client" }),

  awful.key({ "Mod4", "Control" }, "r", awesome.restart, { description="Restart awesome", group="Awesome" }),
  awful.key({ "Mod4", "Control" }, "Cyrillic_ka", awesome.restart),

  awful.key({ "Mod4", "Shift" }, "q", awesome.quit, { description="Quit awesome", group="Awesome" }),
  awful.key({ "Mod4", "Shift" }, "Cyrillic_shorti", awesome.quit),

  awful.key({ "Mod4" }, "l", function() awful.spawn(session_lock_command) end, { description="Lock the session", group="Session" }),
  awful.key({ "Mod4" }, "Cyrillic_de", function() awful.spawn(session_lock_command) end),

  awful.key({ "Mod4" }, "Return", function () awful.spawn(terminal) end, { description="Execute default terminal(" .. terminal .. ")", group="Application" }),

  awful.key({}, "XF86MonBrightnessUp", function () set_brightness(5, true) end, { description="Increase brightness by 5", group="Brightness" }),
  awful.key({}, "XF86MonBrightnessDown", function () set_brightness(5, false) end, { description="Decrease brightness by 5", group="Brightness" }),

  awful.key({ "Control" }, "XF86MonBrightnessUp", function () set_brightness(10, true) end, { description="Increase brightness by 10", group="Brightness" }),
  awful.key({ "Control" }, "XF86MonBrightnessDown", function () set_brightness(10, false) end, { description="Decrease brightness by 10", group="Brightness" }),

  awful.key({}, "XF86AudioMute", function () mute() end, { description="Toggle sound volume", group="Volume" }),

  awful.key({}, "XF86AudioRaiseVolume", function () set_volume(5, true) end, { description="Raise volume by 5", group="Volume" }),
  awful.key({}, "XF86AudioLowerVolume", function () set_volume(5, false) end, { description="Lower volume by 5", group="Volume" }),

  awful.key({ "Control" }, "XF86AudioRaiseVolume", function () set_volume(10, true) end, { description="Raise volume by 10", group="Volume" }),
  awful.key({ "Control" }, "XF86AudioLowerVolume", function () set_volume(10, false) end, { description="Lower volume by 10", group="Volume" }),

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

  awful.key({ }, "Print", function() awful.spawn("deepin-screenshot --no-notification --fullscreen") end, { description="Take a screenshot the whole screen", group="Application" }),
  awful.key({ "Mod4" }, "Print", function() awful.util.spawn_with_shell("sleep 2 && deepin-screenshot --no-notification --fullscreen") end, { description="Take a screenshot the whole screen after 2 seconds", group="Application" }),

  awful.key({ "Mod4", "Control", "Shift" }, "s", function() awful.spawn("deepin-screenshot --no-notification") end, { description="Execute Deepin Screen Capture", group="Application" }),
  awful.key({ "Mod4", "Control", "Shift" }, "Cyrillic_yeru", function() awful.spawn("deepin-screenshot --no-notification") end),

  awful.key({ "Mod4", "Control", "Shift" }, "v", function() awful.spawn("viber") end, { description="Execute Viber", group="Application" }),
  awful.key({ "Mod4", "Control", "Shift" }, "Cyrillic_em", function() awful.spawn("viber") end),

  awful.key({ "Mod4", "Control", "Shift" }, "`", function() awful.spawn("deepin-system-monitor") end, { description="Execute Deepin System Monitor", group="Application" }),
  awful.key({ "Mod4", "Control", "Shift" }, "Cyrillic_io", function() awful.spawn("deepin-system-monitor") end),

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

  awful.key({ "Mod4" }, "o", move_client_to_next_screen, { description="Move to next screen", group="Client" }),
  awful.key({ "Mod4" }, "Cyrillic_shcha", move_client_to_next_screen),

  awful.key({ "Mod4" }, "n", minimize_client, { description="Minimize client", group="Client" }),
  awful.key({ "Mod4" }, "Cyrillic_te", minimize_client),

  awful.key({ "Mod4" }, "m", maximize_client, { description="Maximize client", group="Client" }),
  awful.key({ "Mod4" }, "Cyrillic_softsign", maximize_client),

  awful.key({ "Mod4", "Control" }, "m", maximize_client_to_multiple_monitor, { description="Maximize client to miltiple monitors", group="Client" }),
  awful.key({ "Mod4", "Control" }, "Cyrillic_softsign", maximize_client_to_multiple_monitor),

  -- Snap to edge/corner - Use arrow keys
  awful.key({ "Mod4", "Shift" }, "Down",  function (c) snap_edge(c, 'bottom') end),
  awful.key({ "Mod4", "Shift" }, "Left",  function (c) snap_edge(c, 'left') end),
  awful.key({ "Mod4", "Shift" }, "Right", function (c) snap_edge(c, 'right') end),
  awful.key({ "Mod4", "Shift" }, "Up",    function (c) snap_edge(c, 'top') end),

  -- Snap to edge/corner - Use numpad
  awful.key({ "Mod4", "Shift" }, "#" .. numpad_key_codes[1], function (c) snap_edge(c, 'bottom_left') end),
  awful.key({ "Mod4", "Shift" }, "#" .. numpad_key_codes[2], function (c) snap_edge(c, 'bottom') end),
  awful.key({ "Mod4", "Shift" }, "#" .. numpad_key_codes[3], function (c) snap_edge(c, 'bottom_right') end),
  awful.key({ "Mod4", "Shift" }, "#" .. numpad_key_codes[4], function (c) snap_edge(c, 'left') end),
  awful.key({ "Mod4", "Shift" }, "#" .. numpad_key_codes[5], function (c) snap_edge(c, 'centered') end),
  awful.key({ "Mod4", "Shift" }, "#" .. numpad_key_codes[6], function (c) snap_edge(c, 'right') end),
  awful.key({ "Mod4", "Shift" }, "#" .. numpad_key_codes[7], function (c) snap_edge(c, 'top_left') end),
  awful.key({ "Mod4", "Shift" }, "#" .. numpad_key_codes[8], function (c) snap_edge(c, 'top') end),
  awful.key({ "Mod4", "Shift" }, "#" .. numpad_key_codes[9], function (c) snap_edge(c, 'top_right') end)
)

for i = 1, 9 do
  client_keys = awful.util.table.join(client_keys,
    awful.key({ "Mod4", "Shift"   }, "#" .. i + 9, function (c) do_for_tag(i, function (tag) c:move_to_tag(tag) end) end, { description="Move focused client to tag #", group="Client" })
  )
end

for i = 1, 9 do
  global_keys = awful.util.table.join(global_keys,
    awful.key({ "Mod4"            }, "#" .. i + 9, function () do_for_tag(i, function(tag) tag:view_only() end) end, { description="View only tag #", group="Tag" }),
    awful.key({ "Mod4", "Control" }, "#" .. i + 9, function () do_for_tag(i, function(tag) awful.tag.viewtoggle(tag) end) end, { description="Add view tag #", group="Tag" })
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

function hide_dropdowns()
  menu_widget.hide_dropdown()
  volume_widget.hide_dropdown()
end

local client_buttons = awful.util.table.join(
  awful.button({ }, 1, hide_dropdowns),
  awful.button({ }, 2, hide_dropdowns),
  awful.button({ }, 3, hide_dropdowns)
)

awful.rules.rules = {
  {
    rule = { },
    properties = {
      border_width = beautiful.border_width,
      border_color = beautiful.border_normal,
      focus = awful.client.focus.filter,
      raise = true,
      keys = client_keys,
      buttons = client_buttons,
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
  },
  {
    rule = { class = "Code" },
    properties = {
      border_width = 0,
      titlebars_enabled = false
    }
  },
  {
    rule = { class = "TelegramDesktop" },
    properties = {
      border_width = 0,
      titlebars_enabled = false
    }
  },
  {
    rule = { class = "Org.gnome.Nautilus" },
    properties = {
      border_width = 0,
      titlebars_enabled = false
    }
  },
  {
    rule = { class = "Xfce4-power-manager-settings" },
    properties = {
      border_width = 0,
      titlebars_enabled = false
    }
  },
  {
    rule = { class = "Xfce4-clipman-settings" },
    properties = {
      border_width = 0,
      titlebars_enabled = false
    }
  },
  {
    rule = { class = "Gnome-system-monitor" },
    properties = {
      border_width = 0,
      titlebars_enabled = false
    }
  },
  {
    rule = { class = "gnome-calculator" },
    properties = {
      border_width = 0,
      titlebars_enabled = false
    }
  },
  {
    rule = { class = "Gcm-viewer" },
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

-- | Initialization | --

get_system_brightness(function(value_percent)
  brightness_widget.update(value_percent)
end)

-- | Autostart | --

executer.execute_commands({
  "wmname LG3D",
  "xfce4-power-manager",
  "picom --experimental-backends --backend glx",
  "/usr/lib/mate-polkit/polkit-mate-authentication-agent-1",
  "setxkbmap -option compose:paus",
  "xfce4-clipman",
  "nm-applet",
  "ulauncher"
})
