local awful = require("awful")
local wibox = require("wibox")
local hotkeys_popup = require("awful.hotkeys_popup")

PowerOffWidget_prototype = function()
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
    mainmenu = nil
  }

  this.__construct = function(icon_path, session_lock_command)
    -- Constructor
    this.__public.icon.image = icon_path
    this.__private.mainmenu = awful.menu({ items = {
      { "Show hotkeys", function() hotkeys_popup.show_help(nil, awful.screen.focused()) end },
      { "Awesome restart", awesome.restart },
      { "Awesome quit",  function() awesome.quit() end },
      { "Session lock", session_lock_command },
      { "Notebook suspend", "systemctl -q --no-block suspend" },
      { "Notebook reboot", "systemctl -q --no-block reboot" },
      { "Notebook poweroff", "systemctl -q --no-block poweroff" }
    }})
    this.__public.icon.resize = false
    this.__public.icon:buttons(awful.util.table.join(
      awful.button({}, 1, function() this.__private.mainmenu:toggle() end),
      awful.button({}, 3, function() this.__private.show_launchpad() end)
    ))
  end

  return this
end

PowerOffWidget = createClass(PowerOffWidget_prototype)
