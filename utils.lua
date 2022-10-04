local awful = require("awful")
local gears = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup")

-- Common

round_number = function(a)
  return math.floor(a + 0.5)
end

math_clamp = function(value, min, max)
  return math.max(min, math.min(value, max))
end

clamp_percent = function(value)
  return math.max(0, math.min(value, 100))
end

lpad_string = function(str, len, char)
  if char == nil then
    char = ' '
  end

  return string.rep(char, len - #str) .. str
end

rpad_string = function(str, len, char)
  if char == nil then
    char = ' '
  end

  return str .. string.rep(char, len - #str)
end

create_today = function()
  local now = os.date("*t")
  now.hour = 0
  now.min = 0
  now.sec = 0

  return os.time(now)
end

create_local_datetime = function(year, month, day, hour, min, sec)
  local now = os.date("*t")
  if year ~= nil then
    now.year = year
  end
  if month ~= nil then
    now.month = month
  end
  if day ~= nil then
    now.day = day
  end
  if hour ~= nil then
    now.hour = hour
  end
  if min ~= nil then
    now.min = min
  end
  if sec ~= nil then
    now.sec = sec
  end
  now.isdst = false

  return os.time(now) + get_timezone_offset()
end

get_timezone_offset = function()
  local date_utc   = os.date("!*t")
  local date_local = os.date("*t")
  date_local.isdst = false

  return os.difftime(os.time(date_local), os.time(date_utc))
end

get_color_between = function(color1Hex, color2Hex, weight)
  if color1Hex:len() ~= 7 or color2Hex:len() ~= 7 then
    return nil
  end

  local weight1 = 1 - weight
  local weight2 = weight
  local color1Rgb = hex_to_rgb(color1Hex)
  local color2Rgb = hex_to_rgb(color2Hex)

  return rgb_to_hex({
    round_number(color1Rgb[1] * weight1 + color2Rgb[1] * weight2),
    round_number(color1Rgb[2] * weight1 + color2Rgb[2] * weight2),
    round_number(color1Rgb[3] * weight1 + color2Rgb[3] * weight2),
  })
end

hex_to_rgb = function(hexColor)
  if hexColor:len() ~= 7 or string.sub(hexColor, 1, 1) ~= "#" then
    return nil
  end

  local redHex = string.sub(hexColor, 2, 3)
  local greenHex = string.sub(hexColor, 4, 5)
  local blueHex = string.sub(hexColor, 6, 7)
  local red = tonumber(redHex, 16)
  local green = tonumber(greenHex, 16)
  local blue = tonumber(blueHex, 16)

  return {red, green, blue}
end

rgb_to_hex = function(rgbColor)
  local result = "#"

  for _,value in pairs(rgbColor) do
		local hex = ''

		while (value > 0) do
			local index = math.fmod(value, 16) + 1
			value = math.floor(value / 16)
			hex = string.sub('0123456789ABCDEF', index, index) .. hex
		end

		if (string.len(hex) == 0) then
			hex = '00'
		elseif (string.len(hex) == 1) then
			hex = '0' .. hex
		end

		result = result .. hex
	end

	return result
end

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

get_screen = function(index)
  for s in screen do
    if s.index == index then
      return s
    end
  end

  return nil
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

is_client_in_tag = function(c, tag)
  local ctags = c:tags()
  for _, v in ipairs(ctags) do
    if v == tag then
      return true
    end
  end
  return false
end

get_program_installed = function(program_name, callback)
  awful.spawn.easy_async("which " .. program_name, function(stdout, stderr, exit_reason, exit_code)
    callback(exit_code == 0)
  end)
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

set_ulauncher_theme_mode = function(theme_mode)
  local is_dark_theme = theme_mode == "dark"
  local ulauncher_settings_file_path = gears.filesystem.get_xdg_config_home() .. "ulauncher/settings.json"
  local ulauncher_settings_file_content = read_file_content(ulauncher_settings_file_path)

  if ulauncher_settings_file_content == nil then
    return
  end

  local pattern = "\"theme[-]name\": \"(.-)\"%c"
  local ulauncher_theme_name = ulauncher_settings_file_content:match(pattern)
  local new_theme_name = ulauncher_theme_name:gsub(is_dark_theme and "light" or "dark", theme_mode)
  local new_setting = "\"theme-name\": \"" .. new_theme_name .. "\"" .. "\n"
  local new_ulauncher_settings_file_content = ulauncher_settings_file_content:gsub(pattern, new_setting)
  write_file_content(ulauncher_settings_file_path, new_ulauncher_settings_file_content)
  if new_theme_name ~= ulauncher_theme_name then
    awful.spawn("pkill ulauncher")
    awful.spawn("ulauncher --hide-window")
  end
end

set_obs_theme_mode = function(theme_mode)
  local is_dark_theme = theme_mode == "dark"
  local obs_settings_file_path = gears.filesystem.get_xdg_config_home() .. "obs-studio/global.ini"
  local obs_settings_file_content = read_file_content(obs_settings_file_path)

  if obs_settings_file_content == nil then
    return
  end

  local pattern = "CurrentTheme2=(.-)%c"
  local new_theme_name = is_dark_theme and "Dark" or "System"
  local new_setting = "CurrentTheme2=" .. new_theme_name .. "\n"
  local new_obs_settings_file_content = obs_settings_file_content:gsub(pattern, new_setting)
  write_file_content(obs_settings_file_path, new_obs_settings_file_content)
end

set_remmina_theme_mode = function(theme_mode)
  local is_dark_theme = theme_mode == "dark"
  local remmina_settings_file_path = gears.filesystem.get_xdg_config_home() .. "remmina/remmina.pref"
  local remmina_settings_file_content = read_file_content(remmina_settings_file_path)

  if remmina_settings_file_content == nil then
    return
  end

  local pattern = "dark_theme=(.-)%c"
  local new_setting = "dark_theme=" .. tostring(is_dark_theme) .. "\n"
  local new_remmina_settings_file_content = remmina_settings_file_content:gsub(pattern, new_setting)
  write_file_content(remmina_settings_file_path, new_remmina_settings_file_content)
end

-- Brightness

get_system_brightness = function(callback)
  awful.spawn.easy_async("xfpm-power-backlight-helper --get-brightness", function(current_brightness_string)
    awful.spawn.easy_async("xfpm-power-backlight-helper --get-max-brightness", function(max_brightness_string)
      local current_brightness = tonumber(current_brightness_string)
      local max_brightness = tonumber(max_brightness_string)

      callback(math.floor(current_brightness / max_brightness * 100))
    end)
  end)
end

set_system_brightness = function(step_percent, increase, callback)
  awful.spawn.easy_async("xfpm-power-backlight-helper --get-brightness", function(current_brightness_string)
    awful.spawn.easy_async("xfpm-power-backlight-helper --get-max-brightness", function(max_brightness_string)
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

-- Audio

local cached_audio_server = nil

get_audio_server = function(callback)
  if cached_audio_server ~= nil then
    callback(cached_audio_server)
  else
    get_program_installed("pactl", function(is_pactl_installed)
      if is_pactl_installed then
        cached_audio_server = "pactl"
        callback("pactl")
      else
        get_program_installed("pacmd", function(is_pacmd_installed)
          if is_pacmd_installed then
            cached_audio_server = "pacmd"
            callback("pacmd")
          else
            callback(nil)
          end
        end)
      end
    end)
  end
end

get_audio_server_installed = function(callback)
  get_audio_server(function(audio_server)
    callback(audio_server ~= nil)
  end)
end

get_default_sink = function(callback)
  awful.spawn.easy_async("pactl get-default-sink", function(default_sink_stdout)
    local default_sink = default_sink_stdout:gsub("\n", "")
    callback(default_sink)
  end)
end

get_default_source = function(callback)
  awful.spawn.easy_async("pactl get-default-source", function(default_source_stdout)
    local default_source = default_source_stdout:gsub("\n", "")
    callback(default_source)
  end)
end

get_sink_volume = function(callback)
  get_default_sink(function(default_sink)
    awful.spawn.easy_async("pactl get-sink-volume " .. default_sink, function(current_default_sink_volume_output)
      local current_default_sink_volume = tonumber(current_default_sink_volume_output:match("(%d+)%%"))
      callback(current_default_sink_volume)
    end)
  end)
end

get_source_volume = function(callback)
  get_default_source(function(default_source)
    awful.spawn.easy_async("pactl get-source-volume " .. default_source, function(current_default_source_volume_output)
      local current_default_source_volume = tonumber(current_default_source_volume_output:match("(%d+)%%"))
      callback(current_default_source_volume)
    end)
  end)
end

set_sink_volume = function(step, increase, callback)
  get_default_sink(function(default_sink)
    awful.spawn.easy_async("pactl get-sink-volume " .. default_sink, function(current_default_sink_volume_output)
      local current_default_sink_volume = tonumber(current_default_sink_volume_output:match("(%d+)%%"))
      local command = "pactl set-sink-volume " .. default_sink;
      local new_volume_value = 0
      if increase == nil then
        new_volume_value = clamp_percent(step)
      elseif increase then
        new_volume_value = clamp_percent(current_default_sink_volume + step)
      else
        new_volume_value = clamp_percent(current_default_sink_volume - step)
      end
      command = command .. " " .. new_volume_value .. "%"
      awful.spawn.easy_async(command, callback)
    end)
  end)
end

set_source_volume = function(step, increase, callback)
  get_default_source(function(default_source)
    awful.spawn.easy_async("pactl get-source-volume " .. default_source, function(current_default_source_volume_output)
      local current_default_source_volume = tonumber(current_default_source_volume_output:match("(%d+)%%"))
      local command = "pactl set-source-volume " .. default_source;
      local new_volume_value = 0
      if increase == nil then
        new_volume_value = clamp_percent(step)
      elseif increase then
        new_volume_value = clamp_percent(current_default_source_volume + step)
      else
        new_volume_value = clamp_percent(current_default_source_volume - step)
      end
      command = command .. " " .. new_volume_value .. "%"
      awful.spawn.easy_async(command, callback)
    end)
  end)
end

parse_audio_server_devices = function(audio_server_output, default_device)
  local device_index_pattern = "^%a+ #(%d+)"
  local devices = {}

  local device
  local properties
  local profiles
  local ports
  local port
  local port_properties

  local in_device = false
  local in_properties = false
  local in_ports = false
  local in_profiles = false
  local in_port_properties = false

  local matches = audio_server_output:gmatch("[^\r\n]+")

  local lines = {}

  for match in matches do
    table.insert(lines, match)
  end

  for i = #lines - 1, 1, -1 do
    local line = lines[i]
    local next_line = lines[i + 1]
    if not string.match(next_line, ":") and not string.match(next_line, "=") and not string.match(next_line, device_index_pattern) then
      lines[i] = line .. next_line
      table.remove(lines, i + 1)
    end
  end

  for _,line in ipairs(lines) do
    if string.match(line, device_index_pattern) then
      in_device = true
      in_properties = false
      in_ports = false
      in_profiles = false
      in_port_properties = false
      device = {
        id = line:match(device_index_pattern)
      }
      table.insert(devices, device)
      goto continue
    end

    if string.match(line, "%s+Properties:") then
      in_device = false
      in_properties = not in_ports
      in_profiles = false
      in_port_properties = in_ports

      if in_ports then
        port_properties = {}
        ports[port].properties = port_properties
      else
        properties = {}
        device.properties = properties
      end

      in_ports = false

      goto continue
    end

    if string.match(line, "%s+Profiles:") then
      in_device = false
      in_properties = false
      in_ports = false
      in_profiles = true
      in_port_properties = false
      profiles = {}
      device.profiles = profiles
      goto continue
    end

    if string.match(line, "%s+Active Profile:") then
      in_device = false
      in_properties = false
      in_ports = false
      in_profiles = false
      in_port_properties = false
      device.active_profile = line:match(": (.+)"):gsub("<",""):gsub(">","")
      goto continue
    end

    if string.match(line, "%s+Ports:") then

      in_device = false
      in_properties = false
      in_ports = true
      in_profiles = false
      in_port_properties = false
      ports = {}
      device.ports = ports
      goto continue
    end

    if string.match(line, "%s+Active Port: ") then
      in_device = false
      in_properties = false
      in_ports = false
      in_profiles = false
      in_port_properties = false
      device.active_port = line:match(": (.+)"):gsub("<",""):gsub(">","")
      goto continue
    end

    if in_device then
      local key = line:match("%s+(.+):")
      local value = line:match(": (.+)"):gsub("<",""):gsub(">","")
      device[key] = value
    end

    if in_properties then
      local matches = string.gmatch(line, "([^=]+)")

      local parts = {}

      for match in matches do
        table.insert(parts, match)
      end

      local key = parts[1]:gsub("%s", ""):gsub("%.", "_"):gsub("-", "_"):gsub(":", ""):gsub("%s+$", "")
      local value = parts[2]
      if value ~= nil then
        value = value:gsub("\"", ""):gsub("^%s+", ""):gsub(" Analog Stereo", "")
      end

      properties[key] = value
    end

    if in_profiles then
      local key = line:match("%s+(%S+):")
      local value = line:match(": (.+) %(")

      profiles[key] = value
    end

    if in_port_properties and string.match(line, ":") then
      in_port_properties = false
      in_ports = true
    end

    if in_port_properties then
      local matches = string.gmatch(line, "([^=]+)")

      local parts = {}

      for match in matches do
        table.insert(parts, match)
      end


      local key = parts[1]:gsub("    ", ""):gsub("%.", "_"):gsub("-", "_"):gsub(":", ""):gsub("%s+$", "")
      local value = parts[2]
      if value ~= nil then
        value = value:gsub("\"", ""):gsub("^%s+", "")
      end

      port_properties[key] = value
    end

    if in_ports then
      local key = line:match("(%S+):")
      local value = line:match(": (.+) %(")

      port = key

      ports[port] = {
        name = value
      }
    end
    ::continue::
  end

  for _,device in ipairs(devices) do
    device.is_default = device["Name"] == default_device
  end

  return devices
end

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

-- Bluetooth

local get_bluetooth_adapter_index = function(callback)
  awful.spawn.easy_async("rfkill list bluetooth", function(rfkill_list_bluetooth_output)
    callback(string.match(rfkill_list_bluetooth_output, "^(%d+): "))
  end)
end

local bluetooth_status_subscribers = {}

subscribe_bluetooth_status = function(callback)
  table.insert(bluetooth_status_subscribers, callback)

  if #bluetooth_status_subscribers == 1 then
    get_bluetooth_adapter_index(function(index)
      awful.spawn.with_line_callback("rfkill event", {
        stdout = function(line)
          if string.match(line, "idx " .. index .. " ") then
            for _,bluetooth_status_subscriber in ipairs(bluetooth_status_subscribers) do
              bluetooth_status_subscriber(string.match(line, "soft 0 hard 0") ~= nil)
            end
          end
        end
      })
    end)
  end
end

is_bluetooth_device_connected = function(callback)
  awful.spawn.easy_async("bluetoothctl info", function(bluetoothctl_info_output)
    callback(string.match(bluetoothctl_info_output, "Missing device address argument\n") == nil)
  end)
end

get_bluetooth_device = function(callback)
  is_bluetooth_device_connected(function(is_connected)
    if not is_connected then
      callback({
        connected = false
      })
    end

    awful.spawn.easy_async("bluetoothctl info", function(bluetoothctl_info_output)
      local bluetooth_device = {
        mac_address = bluetoothctl_info_output:match("^Device (.-) "),
        name = bluetoothctl_info_output:match("Name: (.-)\n"),
        alias = bluetoothctl_info_output:match("Alias: (.-)\n"),
        paired = bluetoothctl_info_output:match("Paired: yes") ~= nil,
        bonded = bluetoothctl_info_output:match("Bonded: yes") ~= nil,
        trusted = bluetoothctl_info_output:match("Trusted: yes") ~= nil,
        blocked = bluetoothctl_info_output:match("Blocked: yes") ~= nil,
        connected = bluetoothctl_info_output:match("Connected: yes") ~= nil,
        battery_percentage = tonumber(bluetoothctl_info_output:match("Battery Percentage: %w+ %((%d-)%)"))
      }
      callback(bluetooth_device)
    end)
  end)
end

-- Show help

show_help = function()
  hotkeys_popup.show_help(nil, awful.screen.focused())
end

-- Change focused client

change_focused_client = function(direction)
  restore_clients()
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

-- Move client

move_client = function(c)
  c.maximized = false
  client.focus = c
  c:raise()
  awful.mouse.client.move(c)
end

-- Resize client

resize_client = function(c)
  c.maximized = false
  client.focus = c
  c:raise()
  awful.mouse.client.resize(c)
end

get_geolocation = function(callback)
  awful.spawn.easy_async("/usr/lib/geoclue-2.0/demos/where-am-i", function(geoclue_stdout)
    local latitude_string = geoclue_stdout:match("Latitude:%s+(%S+)"):gsub(",", "."):gsub("°", "")
    local longitude_string = geoclue_stdout:match("Longitude:%s+(%S+)"):gsub(",", "."):gsub("°", "")

    local latitude = tonumber(latitude_string)
    local longitude = tonumber(longitude_string)

    callback(latitude, longitude)
  end)
end

local get_days_count = function(year)
  return os.date("%j", os.time({
    year = year,
    month = 12,
    day = 31
  }))
end

local get_fractional_year = function(hour)
  local day_of_year = os.date("%j")
  local current_year_days_count = get_days_count(os.date("%Y"))

  return 2 * math.pi / current_year_days_count * (day_of_year - 1 + (hour - 12) / 24)
end

local get_time_equation_minutes = function(fractional_year)
  return 229.18 * (0.000075 + 0.001868 * math.cos(fractional_year) - 0.032077 * math.sin(fractional_year) - 0.014615 * math.cos(2 * fractional_year) - 0.040849 * math.sin(2 * fractional_year))
end

local get_declination_angle = function(fractional_year)
  return 0.006918 - 0.399912 * math.cos(fractional_year) + 0.070257 * math.sin(fractional_year) - 0.006758 * math.cos(2 * fractional_year) + 0.000907 * math.sin(2 * fractional_year) - 0.002697 * math.cos(3 * fractional_year) + 0.00148 * math.sin(3 * fractional_year)
end

local get_hour_angle = function(hour, latitude, to_sunrise)
  local fractional_year = get_fractional_year(hour)
  local declination_angle = get_declination_angle(fractional_year)
  local hour_angle_sign = to_sunrise and 1 or -1

  return hour_angle_sign * math.acos(math.cos(math.rad(90.833)) / (math.cos(math.rad(latitude)) * math.cos(declination_angle)) - math.tan(math.rad(latitude)) * math.tan(declination_angle))
end

local get_sunrise_sunset_time_minutes = function(latitude, longitude, is_sunrise)
  local hour = os.date("%H")
  local hour_angle = get_hour_angle(hour, latitude, is_sunrise)
  local fractional_year = get_fractional_year(hour)
  local time_equation_minutes = get_time_equation_minutes(fractional_year)

  return 720 - 4 * (longitude + math.deg(hour_angle)) - time_equation_minutes
end

get_sunrise_time_minutes = function(latitude, longitude)
  return get_sunrise_sunset_time_minutes(latitude, longitude, true)
end

get_sunset_time_minutes = function(latitude, longitude)
  return get_sunrise_sunset_time_minutes(latitude, longitude, false)
end

get_redshift_installed = function(callback)
  get_program_installed("redshift", callback)
end

local cached_redshift_dawn_time = nil

get_redshift_dawn_time = function()
  if cached_redshift_dawn_time ~= nil then
    return cached_redshift_dawn_time
  end
  local redshift_settings_file_path = gears.filesystem.get_xdg_config_home() .. "redshift/redshift.conf"
  local redshift_settings_file_content = read_file_content(redshift_settings_file_path)

  if redshift_settings_file_content == nil then
    return nil
  end

  local matches = redshift_settings_file_content:gmatch("dawn[-]time=(.-)%c")

  for match in matches do
    cached_redshift_dawn_time = match
    return match
  end

  return nil
end

set_redshift_dawn_time = function(value)
  local redshift_settings_file_path = gears.filesystem.get_xdg_config_home() .. "redshift/redshift.conf"
  local redshift_settings_file_content = read_file_content(redshift_settings_file_path)

  if redshift_settings_file_content == nil then
    return
  end

  local new_redshift_settings_file_content = redshift_settings_file_content
  local pattern = "dawn[-]time=(.-)%c"

  if redshift_settings_file_content:match(pattern) then
    local new_setting = value == nil and "" or ("dawn-time=" .. os.date("%H:%M", value) .. "\n")
    new_redshift_settings_file_content = redshift_settings_file_content:gsub(pattern, new_setting)
  else
    local pattern = "dusk[-]time=(.-)%c"
    if redshift_settings_file_content:match(pattern) then
      local new_setting = (value == nil and "" or ("dawn-time=" .. os.date("%H:%M", value) .. "\n")) .. "dusk-time=%1" .. "\n"
      new_redshift_settings_file_content = redshift_settings_file_content:gsub(pattern, new_setting)
    else
      if value ~= nil then
        local pattern = "%[redshift%]%c"
        local new_setting = "[redshift]" .. "\n" .. "dawn-time=" .. os.date("%H:%M", value) .. "\n"
        new_redshift_settings_file_content = redshift_settings_file_content:gsub(pattern, new_setting)
      end
    end
  end

  write_file_content(redshift_settings_file_path, new_redshift_settings_file_content)
end

local cached_redshift_dusk_time = nil

get_redshift_dusk_time = function()
  if cached_redshift_dusk_time ~= nil then
    return cached_redshift_dusk_time
  end
  local redshift_settings_file_path = gears.filesystem.get_xdg_config_home() .. "redshift/redshift.conf"
  local redshift_settings_file_content = read_file_content(redshift_settings_file_path)

  if redshift_settings_file_content == nil then
    return nil
  end

  local matches = redshift_settings_file_content:gmatch("dusk[-]time=(.-)%c")

  for match in matches do
    cached_redshift_dusk_time = match
    return match
  end

  return nil
end

set_redshift_dusk_time = function(value)
  local redshift_settings_file_path = gears.filesystem.get_xdg_config_home() .. "redshift/redshift.conf"
  local redshift_settings_file_content = read_file_content(redshift_settings_file_path)

  if redshift_settings_file_content == nil then
    return
  end

  local new_redshift_settings_file_content = redshift_settings_file_content
  local pattern = "dusk[-]time=(.-)%c"

  if redshift_settings_file_content:match(pattern) then
    local new_setting = value == nil and "" or ("dusk-time=" .. os.date("%H:%M", value) .. "\n")
    new_redshift_settings_file_content = redshift_settings_file_content:gsub(pattern, new_setting)
  else
    local pattern = "dawn[-]time=(.-)%c"
    if redshift_settings_file_content:match(pattern) then
      local new_setting = "dawn-time=%1" .. "\n" .. (value == nil and "" or ("dusk-time=" ..  os.date("%H:%M", value) .. "\n"))
      new_redshift_settings_file_content = redshift_settings_file_content:gsub(pattern, new_setting)
    else
      if value ~= nil then
        local pattern = "%[redshift%]%c"
        local new_setting = "[redshift]" .. "\n" .. "dusk-time=" .. os.date("%H:%M", value)
        new_redshift_settings_file_content = redshift_settings_file_content:gsub(pattern, new_setting)
      end
    end
  end

  write_file_content(redshift_settings_file_path, new_redshift_settings_file_content)
end

reset_redshift = function()
  awful.spawn.easy_async("redshift -x", function() end)
end

restart_redshift = function()
  awful.spawn.easy_async("systemctl restart redshift --user", function() end)
end

stop_redshift = function()
  awful.spawn.easy_async("systemctl stop redshift --user", function() end)
end

set_color_temperature = function(color_temperature)
  awful.spawn("redshift -P -O " .. color_temperature)
end

get_wired_interface = function(callback)
  awful.spawn.easy_async("ip addr", function(ip_addr_stdout)
    local wired_interface = ip_addr_stdout:match("%d+:%s(e%S+):")
    callback(wired_interface)
  end)
end

get_wireless_interface = function(callback)
  awful.spawn.easy_async("ip addr", function(ip_addr_stdout)
    local wireless_interface = ip_addr_stdout:match("%d+:%s(w%S+):")
    callback(wireless_interface)
  end)
end
