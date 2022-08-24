local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

KeyboardLayoutWidget_prototype = function()
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
    name = "KeyboardLayoutWidget",
    icon = nil,
    value = nil
    -- Public Funcs
  }

  this.__private = {
    -- Private Variables
  }

  this.__construct = function()
    -- Constructor
    local keyboard_layout = awful.widget.keyboardlayout()
    keyboard_layout.widget.font = beautiful.font_family_mono .. "Bold 8"

    local background_container = wibox.widget {
      {
        keyboard_layout,
        bottom = dpi(1),
        widget = wibox.container.margin
      },
      bg = beautiful.text_color,
      fg = beautiful.background_color,
      shape = gears.shape.rounded_rect,
      shape_border_color = beautiful.background_color,
      widget = wibox.container.background
    }

    keyboard_layout:connect_signal("mouse::enter", function()
      background_container.bg = beautiful.background_color
      background_container.fg = beautiful.text_color
      background_container.shape_border_width = dpi(2)
      background_container.shape_border_color = background_container.fg
    end)

    keyboard_layout:connect_signal("mouse::leave", function()
      background_container.bg = beautiful.text_color
      background_container.fg = beautiful.background_color
      background_container.shape_border_width = dpi(0)
      background_container.shape_border_color = background_container.fg
    end)

    this.__public.value = wibox.widget {
      background_container,
      top = dpi(5),
      bottom = dpi(5),
      widget = wibox.container.margin
    }
  end

  return this
end

KeyboardLayoutWidget = createClass(KeyboardLayoutWidget_prototype)
