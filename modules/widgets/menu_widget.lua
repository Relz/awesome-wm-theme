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
    icon = wibox.widget.imagebox(),
    value = nil
    -- Public Funcs
  }

  this.__private = {
    -- Private Variables
    mainmenu = nil,
    -- Private Funcs
    switch_theme_mode = function()
      local new_mode = beautiful.mode == "light" and "dark" or "light"
      local theme_path = awful.util.getdir("config") .. "themes/relz/"
      local theme_mode_file_path = theme_path .. "mode"
      mode_file = io.open(theme_mode_file_path, "w")
      mode_file:write(new_mode)
      mode_file:close()
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
    this.__private.mainmenu.wibox.shape = function (cr, w, h)
      gears.shape.partially_rounded_rect(cr, w, h, false, false, true, true, 8)
    end
    this.__public.icon:buttons(awful.util.table.join(
      awful.button({}, 1, function() this.__private.mainmenu:toggle() end)
    ))
  end

  return this
end

MenuWidget = createClass(MenuWidget_prototype)
