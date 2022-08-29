local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

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
              font = beautiful.font_family .. "Bold 13",
              widget = wibox.widget.textbox
            },
            {
              text = description,
              font = beautiful.font_family .. "Regular 12",
              widget = wibox.widget.textbox
            },
            {
              {
                this.__private_static.create_secondary_button(cancel_text, on_cancel),
                this.__private_static.create_primary_button(confirm_text, on_confirm),
                spacing = dpi(16),
                layout = wibox.layout.fixed.horizontal,
              },
              halign = "right",
              layout = wibox.container.place,
            },
            spacing = dpi(8),
            layout = wibox.layout.fixed.vertical,
          },
          margins = dpi(24),
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
      local background_container = wibox.widget {
        {
          {
            text = text,
            font = beautiful.font_family .. "Regular 12",
            widget = wibox.widget.textbox
          },
          top = dpi(4),
          right = dpi(8),
          bottom = dpi(4),
          left = dpi(8),
          widget = wibox.container.margin
        },
        bg = background_color_normal,
        fg = background_color_focus,
        shape = gears.shape.rounded_rect,
        shape_border_color = background_color_focus,

        widget = wibox.container.background
      }

      background_container:connect_signal("mouse::enter", function()
        background_container.bg = background_color_focus
        background_container.fg = background_color_normal
      end)

      background_container:connect_signal("mouse::leave", function()
        background_container.bg = background_color_normal
        background_container.fg = background_color_focus
      end)

      background_container:buttons(awful.util.table.join(
        awful.button({}, 1, function() on_click() end)
      ))

      return wibox.widget {
        background_container,
        top = dpi(5),
        bottom = dpi(5),
        widget = wibox.container.margin
      }
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
