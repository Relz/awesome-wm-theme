local awful = require("awful")
local gears = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup")

-- Common

run_command_sync = function(command)
  local result = ""

  local command_subprocess = io.popen(command)
  if command_subprocess ~= nil then
    result = command_subprocess:read('*all')
    command_subprocess:close()
  end

  return result
end

get_percent_number_digits_count = function(number)
  return number < 10 and 1 or (number < 100 and 2 or 3)
end

read_file_content_async = function(file_path, callback)
  awful.spawn.easy_async("cat " .. file_path, callback)
end

read_file_content = function(file_path)
  local file_content

  local file = io.open(file_path, "r")
  if file ~= nil then
    file_content = file:read("*all")
    file:close()
  end

  return file_content
end

write_file_content = function(file_path, content)
  local file = io.open(file_path, "w")
  if file ~= nil then
    file:write(content)
    file:close()
  end
end

table_map = function(tbl, f)
  local t = {}

  for k,v in pairs(tbl) do
      t[k] = f(v)
  end

  return t
end

get_clients_names = function()
  local client_names = {}

  for s in screen do
    for _,t in pairs(s.tags) do
      for _,c in pairs(t:clients()) do
        table.insert(client_names, c.name)
        break
      end
    end
  end

  return client_names
end

set_gtk_theme_mode = function(theme_mode)
  local is_dark_theme = theme_mode == "dark"
  awful.spawn("gsettings set org.gnome.desktop.interface color-scheme prefer-" .. theme_mode)

  local gtk2_settings_file_path = gears.filesystem.get_xdg_config_home() .. "../.gtkrc-2.0"
  local gtk2_settings_file_content = read_file_content(gtk2_settings_file_path)
  local new_gtk2_settings_file_content = gtk2_settings_file_content

  local gtk3_settings_file_path = gears.filesystem.get_xdg_config_home() .. "gtk-3.0/settings.ini"
  local gtk3_settings_file_content = read_file_content(gtk3_settings_file_path)

  if gtk3_settings_file_content ~= nil then
    local new_gtk3_settings_file_content = gtk3_settings_file_content

    local pattern = "gtk[-]application[-]prefer[-]dark[-]theme=(.-)%c"
    local new_setting = "gtk-application-prefer-dark-theme=" .. tostring(is_dark_theme) .. "\n"
    if new_gtk3_settings_file_content:match(pattern) ~= nil then
      new_gtk3_settings_file_content = new_gtk3_settings_file_content:gsub(pattern, new_setting)
    else
      new_gtk3_settings_file_content = new_gtk3_settings_file_content .. "\n" .. new_setting
    end

    local pattern = "gtk[-]theme[-]name=(.-)%c"
    local gtk_theme_name = new_gtk3_settings_file_content:match(pattern)

    if gears.filesystem.is_dir("/usr/share/themes/" .. gtk_theme_name) then
      local gtk_theme_base_name = gtk_theme_name:gsub("-dark", "")
      local gtk_theme_dark_name = gtk_theme_base_name .. "-dark"
      local gtk_theme_new_name = is_dark_theme and gtk_theme_dark_name or gtk_theme_base_name
      if gears.filesystem.is_dir("/usr/share/themes/" .. gtk_theme_new_name) then
        local new_setting = "gtk-theme-name=" .. tostring(gtk_theme_new_name) .. "\n"
        new_gtk3_settings_file_content = new_gtk3_settings_file_content:gsub(pattern, new_setting)
        awful.spawn("gsettings set org.gnome.desktop.interface gtk-theme " .. gtk_theme_new_name)


        local pattern = "include \"/usr/share/themes/.-/gtk[-]2.0/gtkrc\"%c"
        local new_setting = "include \"/usr/share/themes/" .. gtk_theme_new_name .. "/gtk-2.0/gtkrc\"" .. "\n"
        new_gtk2_settings_file_content = new_gtk2_settings_file_content:gsub(pattern, new_setting)
      end
    end

    local pattern = "gtk[-]icon[-]theme[-]name=(.-)%c"
    local gtk_icon_theme_name = new_gtk3_settings_file_content:match(pattern)

    if gears.filesystem.is_dir("/usr/share/icons/" .. gtk_icon_theme_name) then
      local gtk_icon_theme_base_name = gtk_icon_theme_name:gsub("-dark", "")
      local gtk_icon_theme_dark_name = gtk_icon_theme_base_name .. "-dark"
      local gtk_icon_theme_new_name = is_dark_theme and gtk_icon_theme_dark_name or gtk_icon_theme_base_name
      if gears.filesystem.is_dir("/usr/share/icons/" .. gtk_icon_theme_new_name) then
        local new_setting = "gtk-icon-theme-name=" .. tostring(gtk_icon_theme_new_name) .. "\n"
        new_gtk3_settings_file_content = new_gtk3_settings_file_content:gsub(pattern, new_setting)
        awful.spawn("gsettings set org.gnome.desktop.interface icon-theme " .. gtk_icon_theme_new_name)
      end
    end

    write_file_content(gtk3_settings_file_path, new_gtk3_settings_file_content)
    write_file_content(gtk2_settings_file_path, new_gtk2_settings_file_content)
  end
end

-- Brightness

get_system_brightness = function(callback)
  read_file_content_async("/sys/class/backlight/intel_backlight/brightness", function(current_brightness_string)
    read_file_content_async("/sys/class/backlight/intel_backlight/max_brightness", function(max_brightness_string)
      local current_brightness = tonumber(current_brightness_string)
      local max_brightness = tonumber(max_brightness_string)

      callback(math.floor(current_brightness / max_brightness * 100))
    end)
  end)
end

set_system_brightness = function(step_percent, increase, callback)
  read_file_content_async("/sys/class/backlight/intel_backlight/brightness", function(current_brightness_string)
    read_file_content_async("/sys/class/backlight/intel_backlight/max_brightness", function(max_brightness_string)
      local current_brightness = tonumber(current_brightness_string)
      local max_brightness = tonumber(max_brightness_string)

      local step = math.floor(step_percent * max_brightness / 100)

      local new_brightness = 0
      if increase then
        new_brightness = current_brightness + step;
      else
        new_brightness = current_brightness - step;
      end
      local new_brightness = math.min(math.max(new_brightness, 0), max_brightness)

      awful.spawn.easy_async("pkexec xfpm-power-backlight-helper --set-brightness=" .. new_brightness, function()
        callback(math.floor(new_brightness / max_brightness * 100))
      end)
    end)
  end)
end

-- Volume

set_system_volume = function(step, increase, callback)
  local command = "amixer set Master " .. step .. "%";
  if increase ~= nil then
      if increase then
      command = command .. "+";
      else
      command = command .. "-";
      end
  end
  awful.spawn.easy_async(command, callback)
end

-- Audio

audio_previous = function()
  awful.spawn("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Previous", false)
end

audio_next = function()
  awful.spawn("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Next", false)
end

audio_toggle_play_pause = function()
  awful.spawn("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.PlayPause", false)
end

audio_stop = function()
  awful.spawn("dbus-send --print-reply --dest=org.mpris.MediaPlayer2.spotify /org/mpris/MediaPlayer2 org.mpris.MediaPlayer2.Player.Stop", false)
end

-- Keyboard layout

set_keyboard_layout = function(value)
  awful.spawn("setxkbmap -display :0 -layout " .. value, false)
end

-- Show help

show_help = function()
  hotkeys_popup.show_help(nil, awful.screen.focused())
end

-- Change focused client

change_focused_client = function(direction)
  awful.client.focus.byidx(direction)
  if client.focus then client.focus:raise() end
end

-- Move client to next screen

move_client_to_next_screen = function(c)
  c:move_to_screen()
end

-- Minimize client

minimize_client = function(c)
  c.minimized = true
end

-- Maximize client

maximize_client = function(c)
  c.maximized_horizontal = not c.maximized_horizontal
  c.maximized_vertical = not c.maximized_vertical
end

maximize_client_to_multiple_monitor = function(c)
  c.floating = true
  local focused_screen_geometry = awful.screen.focused().geometry
  focused_screen_geometry.x2 = focused_screen_geometry.x + focused_screen_geometry.width
  focused_screen_geometry.y2 = focused_screen_geometry.y + focused_screen_geometry.height
  for s in screen do
    local screen_geometry = s.geometry
    focused_screen_geometry.x = math.min(focused_screen_geometry.x, screen_geometry.x)
    focused_screen_geometry.y = math.min(focused_screen_geometry.y, screen_geometry.y)
    focused_screen_geometry.x2 = math.max(focused_screen_geometry.x2, screen_geometry.x + screen_geometry.width)
    focused_screen_geometry.y2 = math.max(focused_screen_geometry.y2, screen_geometry.y + screen_geometry.height)
  end
  c:geometry{
    x = focused_screen_geometry.x,
    y = focused_screen_geometry.y,
    width = focused_screen_geometry.x2 - focused_screen_geometry.x,
    height = focused_screen_geometry.y2 - focused_screen_geometry.y
  }
end

-- Toggle client fullscreen

toggle_fullscreen = function(c)
  c.fullscreen = not c.fullscreen
end

-- Do action for tag by index if tag is defined

do_for_tag = function(tag_index, action)
  local screen = awful.screen.focused()
  local tag = screen.tags[tag_index]
  if tag then
    action(tag)
  end
end

-- Minimize all clients on focused tag

minimize_clients = function()
  local tag = awful.tag.selected()
  for i = 1, #tag:clients() do
    minimize_client(tag:clients()[i])
  end
end

-- Restore all clients on focused tag

restore_clients = function()
  local tag = awful.tag.selected()
  for i = 1, #tag:clients() do
    tag:clients()[i].minimized = false
  end
end

-- Toggle minimize/restore all clients on focused tag

toogle_minimize_restore_clients = function()
  if client.focus then
    minimize_clients()
  else
    restore_clients()
  end
end

-- Apply snap edge feature to client

snap_edge = function(client, where)
  local screen_workarea = screen[client.screen].workarea
  local workarea = {
    x_min = screen_workarea.x,
    x_max = screen_workarea.x + screen_workarea.width,
    y_min = screen_workarea.y,
    y_max = screen_workarea.y + screen_workarea.height,
    width = screen_workarea.width,
    height = screen_workarea.height,
    half_width = screen_workarea.width * 0.5,
    half_height = screen_workarea.height * 0.5
  }
  local client_geometry = client:geometry()
  local axis_border_width = client.border_width * 2

  if where == 'top' then
    client_geometry.width  = workarea.width
    client_geometry.height = workarea.half_height - axis_border_width
    client_geometry.x = workarea.x_min
    client_geometry.y = workarea.y_min
    awful.placement.center_horizontal(client)
  elseif where == 'top_right' then
    client_geometry.width  = workarea.half_width - axis_border_width
    client_geometry.height = workarea.half_height - axis_border_width
    client_geometry.x = workarea.x_max - client_geometry.width
    client_geometry.y = workarea.y_min
  elseif where == 'right' then
    client_geometry.width  = workarea.half_width - axis_border_width
    client_geometry.height = workarea.height
    client_geometry.x = workarea.x_max - client_geometry.width
    client_geometry.y = workarea.y_min
  elseif where == 'bottom_right' then
    client_geometry.width  = workarea.half_width - axis_border_width
    client_geometry.height = workarea.half_height - axis_border_width
    client_geometry.x = workarea.x_max - client_geometry.width
    client_geometry.y = workarea.y_max - client_geometry.height
  elseif where == 'bottom' then
    client_geometry.width  = workarea.width
    client_geometry.height = workarea.half_height - axis_border_width
    client_geometry.x = workarea.x_min
    client_geometry.y = workarea.y_max - client_geometry.height
    awful.placement.center_horizontal(client)
  elseif where == 'bottom_left' then
    client_geometry.width  = workarea.half_width - axis_border_width
    client_geometry.height = workarea.half_height - axis_border_width
    client_geometry.x = workarea.x_min
    client_geometry.y = workarea.y_max - client_geometry.height
  elseif where == 'left' then
    client_geometry.width  = workarea.half_width - axis_border_width
    client_geometry.height = workarea.height
    client_geometry.x = workarea.x_min
    client_geometry.y = workarea.y_min
  elseif where == 'top_left' then
    client_geometry.width  = workarea.half_width - axis_border_width
    client_geometry.height = workarea.half_height - axis_border_width
    client_geometry.x = workarea.x_min
    client_geometry.y = workarea.y_min
  elseif where == 'centered' then
    client_geometry.width  = workarea.half_width - axis_border_width
    client_geometry.height = workarea.half_height - axis_border_width
    client_geometry.x = workarea.x_min + (workarea.x_max - workarea.x_min - client_geometry.width) * 0.5
    client_geometry.y = workarea.y_min + (workarea.y_max - workarea.y_min - client_geometry.height) * 0.5
  elseif where == nil then
    client:geometry(client_geometry)
    return
  end

  client.floating = true
  if client.maximized then
    client.maximized = false
  end
  client:geometry(client_geometry)
  awful.placement.no_offscreen(client)
end
