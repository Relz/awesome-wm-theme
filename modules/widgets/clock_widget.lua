local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")

ClockWidget_prototype = function()
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
    name = "ClockWidget",
    icon = wibox.widget.imagebox(),
    value = wibox.container.background()
    -- Public Funcs
  }

  this.__private = {
    -- Private Variables
    -- Private Funcs
  }

  this.__construct = function(calendar_command)
    -- Constructor
    local time = wibox.widget.textclock("%H:%M ")
    time.font = beautiful.font_family_mono .. "Bold 10"

    this.__public.value.widget = time
    this.__public.icon.image = beautiful.widget_clock_icon

    this.__public.icon:buttons(awful.util.table.join(
      awful.button({}, 1, function() awful.spawn(calendar_command) end)
    ))

    this.__public.value:buttons(awful.util.table.join(
      awful.button({}, 1, function() awful.spawn(calendar_command) end)
    ))
  end

  return this
end

ClockWidget = createClass(ClockWidget_prototype)
