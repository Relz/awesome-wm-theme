local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup")
local beautiful = require("beautiful")
require("modules/confirm_dialog")
require("utils")

MenuWidget_prototype = function()
  local this = {}

  this.__public_static = {
    -- Public Static Variables
    -- Public Static Funcs
  }

  this.__private_static = {
    -- Private Static Variables
    -- Private Static Funcs
  }

  this.__public = {
    -- Public Variables
    name = "MenuWidget",
    icon = wibox.widget.imagebox(),
    value = nil,
    -- Public Funcs
    hide_dropdown = function()
      this.__private.mainmenu:hide()
    end,
    on_container_created = function(container, panel_position)
      local is_top_panel_position = panel_position == "top"
      local is_right_panel_position = panel_position == "right"
      local is_bottom_panel_position = panel_position == "bottom"
      local is_left_panel_position = panel_position == "left"

      this.__private.mainmenu.wibox.shape = function (cr, width, height)
        gears.shape.partially_rounded_rect(
          cr,
          width,
          height,
          is_bottom_panel_position or is_right_panel_position,
          is_bottom_panel_position or is_left_panel_position,
          is_top_panel_position or is_left_panel_position,
          is_top_panel_position or is_right_panel_position,
          8
        )
      end
    end,
  }

  this.__private = {
    -- Private Variables
    mainmenu = nil,
    -- Private Funcs
    switch_theme_mode = function()
      local new_mode = beautiful.mode == "light" and "dark" or "light"
      local mode_file = io.open(beautiful.mode_file_path, "w")
      if mode_file ~= nil then
        mode_file:write(new_mode)
        mode_file:close()
      end

      awful.spawn("gsettings set org.gnome.desktop.interface color-scheme prefer-" .. new_mode)

      local gtk3_settings_file_path = gears.filesystem.get_xdg_config_home() .. "gtk-3.0/settings.ini"
      local gtk3_settings_file = io.open(gtk3_settings_file_path, "r")
      if gtk3_settings_file ~= nil then
        local gtk3_settings_file_content = gtk3_settings_file:read("*all")
        gtk3_settings_file:close()

        local new_gtk3_settings_file_content = gtk3_settings_file_content

        local pattern = "gtk[-]application[-]prefer[-]dark[-]theme=.+$"
        local new_setting = "gtk-application-prefer-dark-theme=" .. tostring(new_mode == "dark")
        if new_gtk3_settings_file_content:match(pattern) ~= nil then
          new_gtk3_settings_file_content = new_gtk3_settings_file_content:gsub(pattern, new_setting)
        else
          new_gtk3_settings_file_content = new_gtk3_settings_file_content .. "\n" .. new_setting
        end

        local gtk3_settings_file = io.open(gtk3_settings_file_path, "w")
        if gtk3_settings_file ~= nil then
          gtk3_settings_file:write(new_gtk3_settings_file_content)
          gtk3_settings_file:close()
        end
      end

      awesome.restart()
    end,
    log_out = function()
      local clients_names = get_clients_names()

      if next(clients_names) == nil then
        awesome.quit()
        return
      end

      local appliications_names = table_map(
        clients_names,
        function(client_name)
          return string.match(client_name, "([^-]+)$"):gsub("^%s", "")
        end)

      ConfirmDialog.show(
        "You have opened windows. Are you sure you want to log out anyway?",
        table.concat(appliications_names, "\n"),
        "Log out anyway",
        "Cancel",
        awesome.quit,
        ConfirmDialog.close
      )
    end,
    run_reboot_command = function()
      awful.spawn("systemctl -q --no-block reboot")
    end,
    reboot = function()
      local clients_names = get_clients_names()

      if next(clients_names) == nil then
        this.__private.run_reboot_command()
        return
      end

      local appliications_names = table_map(
        clients_names,
        function(client_name)
          return string.match(client_name, "([^-]+)$"):gsub("^%s", "")
        end)

      ConfirmDialog.show(
        "You have opened windows. Are you sure you want to restart anyway?",
        table.concat(appliications_names, "\n"),
        "Restart anyway",
        "Cancel",
        this.__private.run_reboot_command,
        ConfirmDialog.close
      )
    end,
    run_power_off_command = function()
      awful.spawn("systemctl -q --no-block poweroff")
    end,
    power_off = function()
      local clients_names = get_clients_names()

      if next(clients_names) == nil then
        this.__private.run_power_off_command()
        return
      end

      local appliications_names = table_map(
        clients_names,
        function(client_name)
          return string.match(client_name, "([^-]+)$"):gsub("^%s", "")
        end)

      ConfirmDialog.show(
        "You have opened windows. Are you sure you want to shut down anyway?",
        table.concat(appliications_names, "\n"),
        "Shut down anyway",
        "Cancel",
        this.__private.run_power_off_command,
        ConfirmDialog.close
      )
    end
  }

  this.__construct = function(icon_path, session_lock_command)
    -- Constructor
    this.__public.icon.image = icon_path

    this.__private.mainmenu = awful.menu({ items = {
      { "Show hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
      { "Switch theme mode", this.__private.switch_theme_mode },
      { "Awesome restart", awesome.restart },
      { "Log out",  this.__private.log_out },
      { "Lock", session_lock_command },
      { "Suspend", "systemctl -q --no-block suspend" },
      { "Reboot", this.__private.reboot },
      { "Power Off", this.__private.power_off }
    }})

    this.__public.icon:buttons(awful.util.table.join(
      awful.button({}, 1, function() this.__private.mainmenu:toggle() end)
    ))

    root.buttons(gears.table.join(root.buttons(),
        awful.button({}, 1, this.__public.hide_dropdown),
        awful.button({}, 2, this.__public.hide_dropdown),
        awful.button({}, 3, this.__public.hide_dropdown)
    ))

    this.__private.mainmenu.wibox:connect_signal("property::visible", function()
      local _key_grabber
      if this.__private.mainmenu.wibox.visible then
        _key_grabber = awful.keygrabber.run(function(mod, key, event)
          if event == "release" then
            return false
          end
          if key == "Up" or key == "Right" or key == "Down" or key == "Left" or key == "Return" then
            return false
          end
          this.__public.hide_dropdown()
          awful.keygrabber.stop(_key_grabber)
        end)
      else
        awful.keygrabber.stop(_key_grabber)
      end
    end)
  end

  return this
end

MenuWidget = createClass(MenuWidget_prototype)
