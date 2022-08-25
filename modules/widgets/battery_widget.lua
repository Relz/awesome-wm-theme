local awful = require("awful")
local wibox = require("wibox")
local naughty = require("naughty")
local vicious = require("vicious")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

BatteryWidget_prototype = function()
  local this = {}

  this.__public_static = {
    -- Public Static Variables
    -- Public Static Funcs
  }

  this.__private_static = {
    -- Private Static Variables
    config_path = gears.filesystem.get_configuration_dir(),
    -- Private Static Funcs
  }

  this.__public = {
    -- Public Variables
    name = "BatteryWidget",
    icon = wibox.widget.imagebox(),
    value = nil,
    -- Public Funcs
    on_container_created = function(container, panel_position)
      this.__private.tooltip:add_to_object(container)

      local buttons = awful.util.table.join(
        awful.button(
          {},
          4,
          function()
            this.__private.tooltip_mode = this.__private.tooltip_mode + 1
            if this.__private.tooltip_mode == 3 then
              this.__private.tooltip_mode = 0
            end
          end
        ),
        awful.button(
          {},
          5,
          function()
            this.__private.tooltip_mode = this.__private.tooltip_mode - 1
            if this.__private.tooltip_mode == -1 then
              this.__private.tooltip_mode = 2
            end
          end
        )
      )

      if this.__private.on_click_command ~= nil then
        buttons = awful.util.table.join(
          buttons,
          awful.button({}, 1, function() awful.spawn(this.__private.on_click_command) end)
        )
      end

      container:buttons(buttons)
    end
  }

  this.__private = {
    -- Private Variables
    show_text = false,
    on_click_command = nil,
    capacity = 0,
    previous_capacity = 0,
    is_charging = false,
    remaining_time = 0,
    wear_level = 0,
    tooltip_mode = 0,
    notification = nil;
    tooltip = awful.tooltip({
      timer_function = function() return this.__private.compute_tooltip_text() end,
      mode = "outside"
    }),
    -- Private Funcs
    compute_tooltip_text = function()
      if this.__private.tooltip_mode == 0 then
        return this.__private.capacity .. "%"
      end
      if this.__private.tooltip_mode == 1 then
        local charging_or_discharging = this.__private.is_charging and "charging" or "discharging"
        return "Remaining " .. charging_or_discharging .. " time: " .. this.__private.remaining_time
      end
      if this.__private.tooltip_mode == 2 then
        return "Wear level: " .. this.__private.wear_level .. "%"
      end
    end,
    update = function()
      local is_low_capacity = this.__private.compute_is_low_capacity(this.__private.capacity)

      if is_low_capacity and this.__private.is_charging == false then
        if this.__private.capacity ~= this.__private.previous_capacity then
          this.__private.previous_capacity = this.__private.capacity
          if this.__private.notification == nil then
            this.__private.notification = naughty.notify({
              title = "Your battery is running low (" .. this.__private.capacity .. "%)",
              text = "You might want to plug in your PC",
              bg = beautiful.danger_background,
              fg = beautiful.danger_foreground,
              border_width = dpi(1),
              border_color = beautiful.danger_background,
              icon = gears.color.recolor_image(this.__private_static.config_path .. "/themes/relz/icons/notifications/battery_alert.png", beautiful.danger_foreground),
              timeout = 0,
              destroy = function()
                this.__private.notification = nil
              end
            })
          else
            naughty.replace_text(this.__private.notification, "Your battery is running low (" .. this.__private.capacity .. "%)", "You might want to plug in your PC")
          end
        end
      else
        if this.__private.notification ~= nil then
          naughty.destroy(this.__private.notification)
        end
      end

      local icon_file_name_suffix = this.__private.compute_icon_file_name_suffix()
      local icon_color = is_low_capacity and beautiful.danger_background or beautiful.text_color
      local possible_mode = this.__private.is_charging and "_" .. beautiful.mode or ""
      local icon_path = this.__private_static.config_path .. "/themes/relz/icons/widgets/battery/battery_" .. icon_file_name_suffix .. possible_mode .. ".svg"

      this.__public.icon.image = this.__private.is_charging and icon_path or gears.color.recolor_image(icon_path, icon_color)
      if this.__private.show_text then
        this.__public.value.text = string.rep(" ", 3 - get_percent_number_digits_count(this.__private.capacity)) .. this.__private.capacity .. "% "
      end
    end,
    compute_possible_charging = function()
      return this.__private.is_charging and "charging_" or ""
    end,
    compute_rounded_capacity = function(capacity)
      if capacity > 95 then
        return "100"
      end
      if capacity > 90 then
        return "90"
      end
      if capacity > 80 then
        return "80"
      end
      if capacity > 70 then
        return "70"
      end
      if capacity > 60 then
        return "60"
      end
      if capacity > 50 then
        return "50"
      end
      if capacity > 40 then
        return "40"
      end
      if capacity > 30 then
        return "30"
      end
      if capacity > 20 then
        return "20"
      end
      if capacity > 10 then
        return "10"
      end
      return "0"
    end,
    compute_is_low_capacity = function(capacity)
      return capacity <= 10
    end,
    compute_icon_file_name_suffix = function()
      local possible_charging = this.__private.compute_possible_charging()
      local rounded_capacity = this.__private.compute_rounded_capacity(this.__private.capacity)
      return possible_charging .. rounded_capacity
    end
  }

  this.__construct = function(show_text, on_click_command)
    -- Constructor
    this.__private.show_text = show_text
    this.__private.on_click_command = on_click_command

    if this.__private.show_text then
      this.__public.value = wibox.widget.textbox()
      this.__public.value.font = beautiful.font_family_mono .. "Bold 9"
    end

    this.__private.tooltip.preferred_alignments = {"middle", "back", "front"}

    vicious.register(
      this.__public.icon,
      vicious.widgets.bat,
      function(widget, args)
        this.__private.is_charging = args[1] == "+"
        this.__private.capacity = args[2]
        this.__private.remaining_time = args[3]
        this.__private.wear_level = args[4]
        this.__private.update()
      end,
      2^8,
      "BAT0"
    )
  end

  return this
end

BatteryWidget = createClass(BatteryWidget_prototype)
