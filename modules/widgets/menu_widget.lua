local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local hotkeys_popup = require("awful.hotkeys_popup")
local beautiful = require("beautiful")

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
      local theme_path = awful.util.getdir("config") .. "themes/relz/"
      local theme_mode_file_path = theme_path .. "mode"
      local mode_file = io.open(theme_mode_file_path, "w")
      if mode_file ~= nil then
        mode_file:write(new_mode)
        mode_file:close()
      end
      awesome.restart()
    end
  }

  this.__construct = function(icon_path, session_lock_command)
    -- Constructor
    this.__public.icon.image = icon_path

    this.__private.mainmenu = awful.menu({ items = {
      { "Show hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
      { "Switch theme mode", this.__private.switch_theme_mode },
      { "Awesome restart", awesome.restart },
      { "Log out",  function() awesome.quit() end },
      { "Lock", session_lock_command },
      { "Suspend", "systemctl -q --no-block suspend" },
      { "Reboot", "systemctl -q --no-block reboot" },
      { "Power Off", "systemctl -q --no-block poweroff" }
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
