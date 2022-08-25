local awful = require("awful")
local wibox = require("wibox")
local vicious = require("vicious")
local gears = require("gears")
local beautiful = require("beautiful")

NetworkWidget_prototype = function()
  local this = {}

  this.__public_static = {
    -- Public Static Variables
    -- Public Static Funcs
  }

  this.__private_static = {
    -- Private Static Variables
    config_path = gears.filesystem.get_configuration_dir(),
    wired_interface_name = "enp3s0",
    -- Private Static Funcs
    compute_linp_level = function(linp)
      if linp == nil then
        return "off"
      end
      if linp > 90 then
        return "perfect"
      end
      if linp > 70 then
        return "excellent"
      end
      if linp > 50 then
        return "good"
      end
      if linp > 30 then
        return "normal"
      end
      if linp > 10 then
        return "bad"
      end
      return "terrible"
    end
  }

  this.__public = {
    -- Public Variables
    name = "NetworkWidget",
    icon = wibox.widget.imagebox(),
    value = nil,
    -- Public Funcs
    on_container_created = function(container, panel_position)
      this.__private.tooltip:add_to_object(container)

      if this.__private.on_click_command ~= nil then
        container:buttons(
          awful.util.table.join(
            awful.button({}, 1, function() awful.spawn(this.__private.on_click_command) end)
          )
        )
      end
    end,
    set_wireless_interface = function(wireless_interface_name)
      vicious.register(
        this.__public.icon,
        vicious.widgets.wifi,
        function(widget, args)
          this.__private.ssid = args["{ssid}"]
          this.__private.linp = args["{linp}"]
          local wired_connection_state = this.__private.compute_wired_connection_state()
          if wired_connection_state == "" then
            -- TODO(relz): enable wired interface and recompute state
          end
          this.__private.is_wired_connected = wired_connection_state == "1\n"
          if this.__private.is_wired_connected then
            this.__public.icon.image = this.__private_static.config_path .. "/themes/relz/icons/widgets/network/wired.svg"
          else
            local icon_file_name_suffix = this.__private_static.compute_linp_level(this.__private.linp)

            this.__public.icon.image = gears.color.recolor_image(this.__private_static.config_path .. "/themes/relz/icons/widgets/network/wireless/wifi_" .. icon_file_name_suffix .. ".svg", beautiful.text_color)
          end

          if this.__private.show_text then
            local linp = this.__private.linp and this.__private.linp or 0
            this.__public.value.text = string.rep(" ", 3 - get_percent_number_digits_count(linp)) .. linp .. "% "
          end
        end,
        2^4,
        wireless_interface_name
      )
    end,
    set_wired_interface = function(value)
      this.__private.wired_interface_name = value
    end
  }

  this.__private = {
    -- Private Variables
    textbox = nil,
    ssid = "",
    linp = 0,
    is_wired_connected = false,
    tooltip = awful.tooltip({
      timer_function = function()
        return this.__private.compute_tooltip_text()
      end,
      mode = "outside"
    }),
    -- Private Funcs
    compute_tooltip_text = function()
      return this.__private.is_wired_connected
        and "Wired connected"
        or this.__private.linp == nil and "Disconnected" or this.__private.ssid .. ": " .. this.__private.linp .. "%"
    end,
    compute_wired_connection_state = function()
        return run_command_sync("cat /sys/class/net/" .. this.__private.wired_interface_name .. "/carrier")
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
  end

  return this
end

NetworkWidget = createClass(NetworkWidget_prototype)
