local awful = require("awful")
local wibox = require("wibox")
local vicious = require("vicious")
local naughty = require("naughty")

NetworkWidget_prototype = function()
  local this = {}

  this.__public_static = {
    -- Public Static Variables
    -- Public Static Funcs
  }

  this.__private_static = {
    -- Private Static Variables
    config_path = awful.util.getdir("config"),
    wired_interface_name = "enp3s0",
    -- Private Static Funcs
    read_command_result = function(command)
      local command_subprocess = io.popen(command)
      local result = command_subprocess:read('*all')
      command_subprocess:close()

      return result
    end,
    compute_linp_level = function(linp)
      if linp == nil then
        return "off"
      end
      if linp > 80 then
        return "perfect"
      end
      if linp > 60 then
        return "excellent"
      end
      if linp > 40 then
        return "good"
      end
      if linp > 20 then
        return "normal"
      end
      return "bad"
    end
  }

  this.__public = {
    -- Public Variables
    wired_path = "/sys/class/net/" .. this.__private_static.wired_interface_name .. "/carrier",

    icon = wibox.widget.imagebox(),
    value = nil,
    -- Public Funcs
  }

  this.__private = {
    -- Private Variables
    ssid = "",
    linp = 0,
    is_wired_connected = false,
    mode = "",
    tooltip = awful.tooltip({
      objects = { this.__public.icon },
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
        return this.__private_static.read_command_result("cat " .. this.__public.wired_path)
    end
  }

  this.__construct = function(icon_path, mode)
    -- Constructor
    this.__public.icon.image = icon_path
    this.__public.icon.resize = false

    this.__private.mode = mode
    
    this.__private.tooltip.preferred_alignments = {"middle", "back", "front"}

    vicious.register(this.__public.icon, vicious.widgets.wifi,
      function (widget, args)
        this.__private.ssid = args["{ssid}"]
        this.__private.linp = args["{linp}"]
        local wired_connection_state = this.__private.compute_wired_connection_state()
        if wired_connection_state == "" then
          -- TODO(relz): enable wired interface and recompute state
        end
        this.__private.is_wired_connected = wired_connection_state == "1\n"
        if this.__private.is_wired_connected then
          this.__public.icon.image = this.__private_static.config_path .. "/themes/relz/icons/panel/widgets/network/wired/ethernet_" .. this.__private.mode .. ".png"
        else
          local icon_file_name_suffix = this.__private_static.compute_linp_level(this.__private.linp)

          this.__public.icon.image = this.__private_static.config_path .. "/themes/relz/icons/panel/widgets/network/wireless/wifi_" .. icon_file_name_suffix .. "_" .. this.__private.mode .. ".png"
        end
      end,
      2^4,
      "wlp2s0b1"
    )
  end

  return this
end

NetworkWidget = createClass(NetworkWidget_prototype)
