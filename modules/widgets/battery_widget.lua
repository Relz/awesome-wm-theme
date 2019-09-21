local awful   = require("awful")
local wibox   = require("wibox")
local naughty = require("naughty")
local vicious = require("vicious")

BatteryWidget_prototype = function()
  local this = {}

  this.__public_static = {
    -- Public Static Variables
    -- Public Static Funcs
  }

  this.__private_static = {
    -- Private Static Variables
    config_path = awful.util.getdir("config"),
    -- Private Static Funcs
  }

  this.__public = {
    -- Public Variables
    icon = wibox.widget.imagebox(),
    value = nil,
    -- Public Funcs
  }

  this.__private = {
    -- Private Variables
    capacity = 0,
    previous_capacity = 0,
    is_charging = false,
    remaining_time = 0,
    wear_level = 0,
    tooltip_mode = 0,
    mode = "",
    notification = nil;
    tooltip = awful.tooltip({
      objects = { this.__public.icon },
      timer_function = function()
        return this.__private.compute_tooltip_text()
      end,
      mode = "outside"
    }),
    -- Private Funcs
    compute_tooltip_text = function()
      if this.__private.tooltip_mode == 0 then
        return this.__private.capacity .. "%"
      end
      if this.__private.tooltip_mode == 1 then
        local chargingOrDischarging = "discharging"
        if this.__private.is_charging then
          local chargingOrDischarging = "charging"
        end
        return "Remaining " .. chargingOrDischarging .. " time: " .. this.__private.remaining_time
      end
      if this.__private.tooltip_mode == 2 then
        return "Wear level: " .. this.__private.wear_level .. "%"
      end
    end,
    update = function()
      if this.__private.compute_is_low_capacity(this.__private.capacity) and this.__private.is_charging == false then
        if this.__private.capacity ~= this.__private.previous_capacity then
          this.__private.previous_capacity = this.__private.capacity
          if this.__private.notification == nil then
            this.__private.notification = naughty.notify({
              title = "Your battery is running low (" .. this.__private.capacity .. "%)",
              text = "You might want to plug in your PC",
              border_width = 1,
              border_color = "#dd6864",
              bg = "#e27c79",
              fg = "#9f2723",
              icon = this.__private_static.config_path .. "/themes/relz/icons/notifications/battery/battery_alert_" .. this.__private.mode .. ".png",
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

      this.__public.icon.image = this.__private_static.config_path .. "/themes/relz/icons/panel/widgets/battery/battery_" .. icon_file_name_suffix .. "_" .. this.__private.mode .. ".png"
    end,
    compute_possible_charging = function()
      return this.__private.is_charging and "charging_" or ""
    end,
    compute_rounded_capacity = function(capacity)
      if capacity <= 10 then
        return "0"
      end
      if capacity > 95 then
        return "100"
      end
      if capacity > 85 then
        return "90"
      end
      if capacity > 75 then
        return "80"
      end
      if capacity > 55 then
        return "60"
      end
      if capacity > 45 then
        return "50"
      end
      if capacity > 25 then
        return "30"
      end
      if capacity > 10 then
        return "20"
      end
    end,
    compute_is_low_capacity = function(capacity)
      if capacity <= 10 then
        return true
      end
      return false
    end,
    compute_icon_file_name_suffix = function()
      local result = ""
      local show_alert = this.__private.capacity <= 10
      if show_alert then
        result = "alert"
      else
        local possible_charging = this.__private.compute_possible_charging()
        local rounded_capacity = this.__private.compute_rounded_capacity(this.__private.capacity)
        result = possible_charging .. rounded_capacity
      end

      return result
    end
  }

  this.__construct = function(icon_path, mode)
    -- Constructor
    this.__public.icon.image = icon_path
    this.__public.icon.resize = false

    this.__private.mode = mode

    this.__private.tooltip.preferred_alignments = {"middle", "back", "front"}

    vicious.register(this.__public.icon, vicious.widgets.bat,
      function (widget, args)
        this.__private.is_charging = args[1] == "+"
        this.__private.capacity = args[2]
        this.__private.remaining_time = args[3]
        this.__private.wear_level = args[4]
        this.__private.update()
      end,
      2^5,
      "BAT0"
    )

    this.__public.icon:connect_signal("button::press", function()
      this.__private.tooltip_mode = this.__private.tooltip_mode + 1
      if this.__private.tooltip_mode == 3 then
        this.__private.tooltip_mode = 0
      end
    end)
  end

  return this
end

BatteryWidget = createClass(BatteryWidget_prototype)
