local awful = require("awful")
local wibox = require("wibox")
local vicious = require("vicious")

VolumeWidget_prototype = function()
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
    value = wibox.container.background(),
    -- Public Funcs
  }

  this.__private = {
    -- Private Variables
    mode = "",
    tooltip = awful.tooltip({
      objects = { this.__public.icon },
      timer_function = function()
        return this.__private.get_volume_value_string()
      end,
      mode = "outside"
    }),
    volume_value = 0,
    is_muted = true,
    textbox = wibox.widget.textbox(),
    -- Private Funcs
    compute_volume_level = function(is_muted, volume_value)
      if (is_muted or volume_value == 0) then
        return "muted"
      elseif volume_value < 30 then
        return "low"
      elseif volume_value < 65 then
        return "medium"
      elseif volume_value <= 100 then
        return "high"
      end
      return "muted"
    end,
    get_number_digits_count = function(number)
      return number < 10 and 1 or (number < 100 and 2 or 3)
    end,
    get_volume_value_string = function()
      return this.__private.volume_value .. "%"
    end
  }

  this.__construct = function(icon_path, mode)
    -- Constructor
    this.__public.icon.image = icon_path
    this.__public.icon.resize = false

    this.__private.mode = mode

    this.__private.tooltip.preferred_alignments = {"middle", "back", "front"}

    this.__private.textbox.font = "Droid Sans Mono Bold 9"
    this.__public.value.widget = this.__private.textbox

    vicious.register(this.__public.icon, vicious.widgets.volume,
      function (widget, args)
        this.__private.volume_value = args[1]
        this.__private.is_muted = args[2] == "♩"
        this.__public.icon.image = this.__private_static.config_path .. "/themes/relz/icons/panel/widgets/volume/volume_" .. this.__private.compute_volume_level(this.__private.is_muted, this.__private.volume_value) .. "_" .. this.__private.mode .. ".png"
        this.__private.textbox.text = string.rep(" ", 3 - this.__private.get_number_digits_count(this.__private.volume_value)) .. this.__private.get_volume_value_string() .. " "
      end,
      2^22,
      "Master"
    )
  end

  return this
end

VolumeWidget = createClass(VolumeWidget_prototype)
