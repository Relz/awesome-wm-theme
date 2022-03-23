local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")

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
    icon = nil,
    value = nil
    -- Public Funcs
  }

  this.__private = {
    -- Private Variables
    keyboard_layout = awful.widget.keyboardlayout()
  }

  this.__construct = function()
    -- Constructor
    this.__private.keyboard_layout.widget.font = "Droid Sans Mono Bold 8"

    local inner_margin_container = wibox.container.margin(this.__private.keyboard_layout)
    inner_margin_container.bottom = 1

    local background_container = wibox.container.background(inner_margin_container)
    background_container.bg = theme.text_color
    background_container.fg = theme.background_color
    background_container.shape = gears.shape.rounded_rect
    background_container.shape_border_color = background_container.fg

    local margin_container = wibox.container.margin(background_container)
    margin_container.top = 5
    margin_container.bottom = 5

    this.__private.keyboard_layout:connect_signal("mouse::enter", function()
      background_container.bg = theme.background_color
      background_container.fg = theme.text_color
      background_container.shape_border_width = 2
      background_container.shape_border_color = background_container.fg
    end)

    this.__private.keyboard_layout:connect_signal("mouse::leave", function()
      background_container.bg = theme.text_color
      background_container.fg = theme.background_color
      background_container.shape_border_width = 0
      background_container.shape_border_color = background_container.fg
    end)

    this.__public.value = margin_container
  end

  return this
end

KeyboardLayoutWidget = createClass(KeyboardLayoutWidget_prototype)
