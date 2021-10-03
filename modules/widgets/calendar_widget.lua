local awful = require("awful")
local lain = require("lain")
local wibox = require("wibox")

CalendarWidget_prototype = function()
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
    value = wibox.container.background()
    -- Public Funcs
  }

  this.__private = {
    -- Private Variables
    -- Private Funcs
  }

  this.__construct = function(calendar_icon_path, text_color)
    -- Constructor
    this.__public.icon.resize = false

    date = wibox.widget.textclock(lain.util.markup(text_color, "%d %b"))

    this.__public.value.widget = date
    this.__public.icon.image = calendar_icon_path
  end

  return this
end

CalendarWidget = createClass(CalendarWidget_prototype)
