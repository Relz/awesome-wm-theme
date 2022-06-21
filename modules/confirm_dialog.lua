local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")

ConfirmDialog_prototype = function()
  local this = {}

  this.__public_static = {
    -- Public Static Variables
    -- Public Static Funcs
    show = function(text, description, confirm_text, cancel_text, on_confirm, on_cancel)
      this.__public_static.close()

      this.__private_static.popup = awful.popup {
        widget = {
          {
            {
              text = text,
              font = "Noto Sans Bold 13",
              widget = wibox.widget.textbox
            },
            {
              text = description,
              font = "Noto Sans Regular 12",
              widget = wibox.widget.textbox
            },
            {
              {
                this.__private_static.create_secondary_button(cancel_text, on_cancel),
                this.__private_static.create_primary_button(confirm_text, on_confirm),
                spacing = 16,
                layout = wibox.layout.fixed.horizontal,
              },
              halign = "right",
              layout = wibox.container.place,
            },
            spacing = 8,
            layout = wibox.layout.fixed.vertical,
          },
          margins = 24,
          widget = wibox.container.margin
        },
        shape = gears.shape.rounded_rect,
        placement = awful.placement.centered,
        input_passthrough = true,
        visible = true,
        ontop = true,
        bg = beautiful.bg_normal .. "99",
      }
    end,

    close = function()
      if this.__private_static.popup ~= nil then
        this.__private_static.popup.visible = false
      end
    end
  }

  this.__private_static = {
    -- Private Static Variables
    popup = nil,
    -- Private Static Funcs
    create_primary_button = function(text, on_click)
      return this.__private_static.create_button(text, on_click, beautiful.text_color, beautiful.background_color)
    end,
    create_secondary_button = function(text, on_click)
      return this.__private_static.create_button(text, on_click, beautiful.background_color, beautiful.text_color)
    end,
    create_button = function(text, on_click, background_color_normal, background_color_focus)
      local textbox = wibox.widget.textbox(text)
      textbox.font = "Noto Sans Regular 12"

      local inner_margin_container = wibox.container.margin(textbox, 8, 8, 4, 4)

      local background_container = wibox.container.background(inner_margin_container)
      background_container.bg = background_color_normal
      background_container.fg = background_color_focus
      background_container.shape = gears.shape.rounded_rect
      background_container.shape_border_color = background_container.fg

      local margin_container = wibox.container.margin(background_container)
      margin_container.top = 5
      margin_container.bottom = 5

      background_container:connect_signal("mouse::enter", function()
        background_container.bg = background_color_focus
        background_container.fg = background_color_normal
      end)

      background_container:connect_signal("mouse::leave", function()
        background_container.bg = background_color_normal
        background_container.fg = background_color_focus
      end)

      background_container:buttons(awful.util.table.join(
        awful.button({}, 1, on_click)
      ))

      return margin_container
    end
  }

  this.__public = {
    -- Public Variables
    -- Public Funcs
  }

  this.__private = {
    -- Private Variables
    -- Private Funcs
  }

  this.__construct = function()
    -- Constructor
  end

  return this
end

ConfirmDialog = createClass(ConfirmDialog_prototype)
