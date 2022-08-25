local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")

LaunchWidget_prototype = function()
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
    name = "LaunchWidget",
    icon = wibox.widget.imagebox(),
    value = nil,
    -- Public Funcs
  }

  this.__private = {
    -- Private Variables
    -- Private Funcs
  }

  this.__construct = function(launch_command)
    -- Constructor
    this.__public.icon.image = beautiful.widget_launch_icon

    this.__public.icon:buttons(awful.util.table.join(
      awful.button({}, 1, function() awful.spawn(launch_command) end)
    ))
  end

  return this
end

LaunchWidget = createClass(LaunchWidget_prototype)
