local awful = require("awful")
local lain = require("lain")
local wibox = require("wibox")

ClockCalendarWidget_prototype = function()
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

  this.__construct = function(clock_icon_path, calendar_icon_path, text_color)
    -- Constructor
    this.__public.icon.image = clock_icon_path
    this.__public.icon.resize = false

    time = wibox.widget.textclock(lain.util.markup(text_color, "%H:%M "))
    date = wibox.widget.textclock(lain.util.markup(text_color, "%d %b"))

    this.__public.value.widget = time

    local index = 1
    local loop_widgets = { time, date }
    local loop_widgets_icons = { clock_icon_path, calendar_icon_path }

    this.__public.value:buttons(awful.util.table.join(awful.button({}, 1,
        function ()
            index = index % #loop_widgets + 1
            this.__public.value.widget = loop_widgets[index]
            this.__public.icon.image = loop_widgets_icons[index]
        end)))
  end

  return this
end

ClockCalendarWidget = createClass(ClockCalendarWidget_prototype)
