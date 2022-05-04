local awful = require("awful")
local wibox = require("wibox")
local vicious = require("vicious")
local gears = require("gears")
local beautiful = require("beautiful")

CpuWidget_prototype = function()
  local this = {}

  this.__public_static = {
    -- Public Static Variables
    -- Public Static Funcs
  }

  this.__private_static = {
    -- Private Static Variables
    config_path = awful.util.getdir("config")
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
    tooltip = awful.tooltip({
      objects = { this.__public.icon },
      timer_function = function()
        return this.__private.cpu_usage .. "%"
      end,
      mode = "outside"
    }),
    cpu_usage = 0,
    -- Private Funcs
    compute_usage_level = function(usage_value)
      if usage_value > 90 then
        return "100"
      end
      if usage_value > 80 then
        return "90"
      end
      if usage_value > 70 then
        return "80"
      end
      if usage_value > 60 then
        return "70"
      end
      if usage_value > 50 then
        return "60"
      end
      if usage_value > 40 then
        return "50"
      end
      if usage_value > 30 then
        return "40"
      end
      if usage_value > 20 then
        return "30"
      end
      if usage_value > 10 then
        return "20"
      end
      return "10"
    end
  }

  this.__construct = function()
    -- Constructor
    this.__private.tooltip.preferred_alignments = {"middle", "back", "front"}

    vicious.register(
      this.__public.icon,
      vicious.widgets.cpu,
      function (widget, args)
        this.__private.cpu_usage = args[1]
        widget.image = gears.color.recolor_image(this.__private_static.config_path .. "/themes/relz/icons/widgets/cpu/cpu_" .. this.__private.compute_usage_level(this.__private.cpu_usage) .. ".svg", beautiful.text_color)
      end,
      2^2
    )
  end

  return this
end

CpuWidget = createClass(CpuWidget_prototype)
