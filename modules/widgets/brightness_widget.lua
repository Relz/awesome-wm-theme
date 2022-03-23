local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")

BrightnessWidget_prototype = function()
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
    update = function(brightness_percentage)
      this.__public.icon.image = gears.color.recolor_image(this.__private_static.config_path .. "/themes/relz/icons/widgets/brightness/brightness_" .. this.__private.compute_brightness_level(brightness_percentage) .. ".svg", beautiful.text_color)
      this.__private.textbox.text = string.rep(" ", 3 - this.__private.get_number_digits_count(brightness_percentage)) ..  brightness_percentage .. "%"
    end
  }

  this.__private = {
    -- Private Variables
    textbox = wibox.widget.textbox(),
    -- Private Funcs
    get_number_digits_count = function(number)
      return number < 10 and 1 or (number < 100 and 2 or 3)
    end,
    compute_brightness_level = function(brightness_percentage)
      if brightness_percentage > 66 then
        return "high"
      end
      if brightness_percentage > 33 then
        return "medium"
      end
      return "low"
    end
  }

  this.__construct = function(brightness_percentage)
    -- Constructor
    this.__private.textbox.font = "Droid Sans Mono Bold 9"
    this.__public.value.widget = this.__private.textbox

    this.__public.update(brightness_percentage)
  end

  return this
end

BrightnessWidget = createClass(BrightnessWidget_prototype)
