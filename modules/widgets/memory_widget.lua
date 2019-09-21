local awful = require("awful")
local wibox = require("wibox")
local vicious = require("vicious")

MemoryWidget_prototype = function()
  local this = {}

  this.__public_static = {
    -- Public Static Variables
    -- Public Static Funcs
  }

  this.__private_static = {
    -- Private Static Variables
    config_path = awful.util.getdir("config"),
    -- Private Static Funcs
    compute_used_level = function(used_percentage)
      if used_percentage > 80 then
        return "100"
      end
      if used_percentage > 70 then
        return "80"
      end
      if used_percentage > 45 then
        return "60"
      end
      if used_percentage > 25 then
        return "40"
      end
      if used_percentage > 10 then
        return "20"
      end
      return "0"
    end
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
        return this.__private.memory_used
      end,
      mode = "outside"
    }),
    memory_used = ""
    -- Private Funcs
  }

  this.__construct = function(icon_path, mode)
    -- Constructor
    this.__public.icon.image = icon_path
    this.__public.icon.resize = false

    this.__private.mode = mode
    
    this.__private.tooltip.preferred_alignments = {"middle", "back", "front"}

    vicious.register(this.__public.icon, vicious.widgets.mem,
      function(widget, args)
        local mem_used = args[2];
        local used_percentage = args[1];
        this.__private.memory_used = mem_used .. "MB"
        widget.image = this.__private_static.config_path .. "/themes/relz/icons/panel/widgets/memory/memory_" .. this.__private_static.compute_used_level(used_percentage) .. "_" .. this.__private.mode .. ".png"
      end,
      2^2
    )
  end

  return this
end

MemoryWidget = createClass(MemoryWidget_prototype)
