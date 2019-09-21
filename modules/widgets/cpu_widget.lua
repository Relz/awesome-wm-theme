local awful = require("awful")
local wibox = require("wibox")
local vicious = require("vicious")

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
    mode = "",
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
      if usage_value == 100 then
        return "full"
      end
      if usage_value > 80 then
        return "high"
      end
      if usage_value > 60 then
        return "pretty_high"
      end
      if usage_value > 40 then
        return "normal"
      end
      if usage_value > 20 then
        return "pretty_low"
      end
      if usage_value > 5 then
        return "low"
      end
      return "zero"
    end
  }

  this.__construct = function(icon_path, mode)
    -- Constructor
    this.__public.icon.image = icon_path
    this.__public.icon.resize = false

    this.__private.mode = mode
    
    this.__private.tooltip.preferred_alignments = {"middle", "back", "front"}

    vicious.register(this.__public.icon, vicious.widgets.cpu,
      function (widget, args)
        this.__private.cpu_usage = args[1]
        widget.image = this.__private_static.config_path .. "/themes/relz/icons/panel/widgets/cpu/cpu_" .. this.__private.compute_usage_level(this.__private.cpu_usage) .. "_" .. this.__private.mode .. ".png"
      end,
      2^2
    )
  end

  return this
end

CpuWidget = createClass(CpuWidget_prototype)
