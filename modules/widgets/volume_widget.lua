local awful = require("awful")
local wibox = require("wibox")
local vicious = require("vicious")
local gears = require("gears")
local beautiful = require("beautiful")

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
    name = "VolumeWidget",
    icon = wibox.widget.imagebox(),
    value = wibox.container.background(),
    -- Public Funcs
    on_container_created = function(container, panel_position)
      local is_top_panel_position = panel_position == "top"
      local is_right_panel_position = panel_position == "right"
      local is_bottom_panel_position = panel_position == "bottom"
      local is_left_panel_position = panel_position == "left"

      local offset_x = is_left_panel_position and 8 or is_right_panel_position and -8 or 0
      local offset_y = is_top_panel_position and 8 or is_bottom_panel_position and -8 or 0

      this.__private.settings_popup.offset = {
        x = offset_x,
        y = offset_y,
      }

      container:connect_signal(
        "button::press",
        function(_, _, _, button_id, _, geometry)
          if button_id == 1 then
            this.__private.rebuild_popup()
            local is_visible = this.__private.settings_popup.visible
            this.__private.settings_popup:move_next_to(geometry)
            this.__private.settings_popup.visible = not is_visible
          end
        end
      )
    end,
    hide_dropdown = function()
      this.__private.settings_popup.visible = false
    end,
  }

  this.__private = {
    -- Private Variables
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
    end,
    get_devices = function(pacmd_output)
      local devices = {}

      local device
      local properties
      local ports
      local port
      local port_properties

      local in_device = false
      local in_properties = false
      local in_ports = false
      local in_port_properties = false

      local matches = pacmd_output:gmatch("[^\r\n]+")

      local lines = {}

      for match in matches do
        table.insert(lines, match)
      end

      for i = #lines - 1, 1, -1 do
        local line = lines[i]
        local next_line = lines[i + 1]
        if not string.match(next_line, ":") and not string.match(next_line, "=") then
          lines[i] = line .. next_line
          table.remove(lines, i + 1)
        end
      end

      for _,line in ipairs(lines) do
        if string.match(line, "index:") then
          in_device = true
          in_properties = false
          in_ports = false
          in_port_properties = false
          device = {
            id = line:match(": (%d+)"),
            is_default = string.match(line, "*") ~= nil
          }
          table.insert(devices, device)
          goto continue
        end

        if string.match(line, "^\tproperties:") then
          in_device = false
          in_properties = true
          in_ports = false
          in_port_properties = false
          properties = {}
          device.properties = properties
          goto continue
        end

        if string.match(line, "ports:") then
          in_device = false
          in_properties = false
          in_ports = true
          in_port_properties = false
          ports = {}
          device.ports = ports
          goto continue
        end

        if in_ports and string.match(line, "^\t\t\tproperties:") then
          in_device = false
          in_properties = false
          in_ports = false
          in_port_properties = true
          port_properties = {}
          ports[port].properties = port_properties
          goto continue
        end

        if string.match(line, "active port:") then
          in_device = false
          in_properties = false
          in_ports = false
          in_port_properties = false
          device.active_port = line:match(": (.+)"):gsub("<",""):gsub(">","")
          goto continue
        end

        if in_device then
          local key = line:match("\t+(.+):")
          local value = line:match(": (.+)"):gsub("<",""):gsub(">","")
          device[key] = value
        end

        if in_properties then
          local matches = string.gmatch(line, "([^=]+)")

          local parts = {}

          for match in matches do
            table.insert(parts, match)
          end

          local key = parts[1]:gsub("\t+", ""):gsub("%.", "_"):gsub("-", "_"):gsub(":", ""):gsub("%s+$", "")
          local value = parts[2]
          if value ~= nil then
            value = value:gsub("\"", ""):gsub("^%s+", ""):gsub(" Analog Stereo", "")
          end

          properties[key] = value
        end

        if in_port_properties and string.match(line, ":") then
          in_port_properties = false
          in_ports = true
        end

        if in_port_properties then
          local matches = string.gmatch(line, "([^=]+)")

          local parts = {}

          for match in matches do
            table.insert(parts, match)
          end


          local key = parts[1]:gsub("\t+", ""):gsub("%.", "_"):gsub("-", "_"):gsub(":", ""):gsub("%s+$", "")
          local value = parts[2]
          if value ~= nil then
            value = value:gsub("\"", ""):gsub("^%s+", "")
          end

          port_properties[key] = value
        end

        if in_ports then
          local key = line:match("\t+(%S+):")
          local value = line:match(": (.+) %(")

          port = key

          ports[port] = {
            name = value
          }
        end
        ::continue::
      end

      return devices
    end,
    get_device_name = function(device)
      local port = nil
      if device.active_port ~= nil and device.ports[device.active_port] ~= nil then
        port = device.ports[device.active_port]
      end

      local device_name = device.properties.device_description
      if port ~= nil then
        device_name = device_name .. " · " .. port.name
      end

      return device_name
    end,
    build_popup_devices_rows = function(devices, on_checkbox_click, device_type)
      local device_rows  = { layout = wibox.layout.fixed.vertical }

      for _, device in pairs(devices) do

        local checkbox = wibox.widget {
          checked = device.is_default,
          paddings = 2,
          forced_width = 16,
          forced_height = 16,
          widget = wibox.widget.checkbox
        }

        local row = wibox.widget {
          {
            {
              {
                checkbox,
                valign = "center",
                layout = wibox.container.place,
              },
              {
                {
                  text = this.__private.get_device_name(device),
                  align = "left",
                  widget = wibox.widget.textbox
                },
                left = 10,
                layout = wibox.container.margin
              },
              spacing = 8,
              layout = wibox.layout.align.horizontal
            },
            margins = 4,
            layout = wibox.container.margin
          },
          widget = wibox.container.background
        }

        row:connect_signal(
          "mouse::enter",
          function(c)
            c:set_bg(beautiful.menu_bg_focus)
            c:set_fg(beautiful.fg_focus)
          end
        )
        row:connect_signal(
          "mouse::leave",
          function(c)
            c:set_bg(gears.color.transparent)
            c:set_fg(beautiful.fg_normal)
          end
        )

        row:connect_signal("button::press", function()
          awful.spawn.easy_async(string.format([[pacmd set-default-%s "%s"]], device_type, device.name), on_checkbox_click)
        end)

        table.insert(device_rows, row)
      end

      return device_rows
    end,
    build_popup_header_row = function(text)
      return wibox.widget{
        {
          markup = "<b>" .. text .. "</b>",
          align = "center",
          widget = wibox.widget.textbox
        },
        widget = wibox.container.background
      }
    end,
    rebuild_popup = function ()
      local rows  = { layout = wibox.layout.fixed.vertical }

      awful.spawn.easy_async("pacmd list-sinks", function(get_sinks_stdout)

        local sinks = this.__private.get_devices(get_sinks_stdout)

        table.insert(rows, this.__private.build_popup_header_row("OUTPUTS"))
        table.insert(rows, this.__private.build_popup_devices_rows(sinks, this.__private.rebuild_popup, "sink"))

        awful.spawn.easy_async("pacmd list-sources", function(get_sources_stdout)

          local sources = this.__private.get_devices(get_sources_stdout)

          table.insert(rows, this.__private.build_popup_header_row("INPUTS"))
          table.insert(rows, this.__private.build_popup_devices_rows(sources, this.__private.rebuild_popup, "source"))

          this.__private.settings_popup:setup(rows)
        end)
      end)
    end,
  }

  this.__construct = function()
    -- Constructor
    this.__private.textbox.font = "Droid Sans Mono Bold 9"
    this.__public.value.widget = this.__private.textbox

    vicious.register(
      this.__public.icon,
      vicious.widgets.volume,
      function (widget, args)
        this.__private.volume_value = args[1]
        this.__private.is_muted = args[2] == "🔈"
        this.__public.icon.image = gears.color.recolor_image(this.__private_static.config_path .. "/themes/relz/icons/widgets/volume/volume_" .. this.__private.compute_volume_level(this.__private.is_muted, this.__private.volume_value) .. ".svg", beautiful.text_color)
        this.__private.textbox.text = string.rep(" ", 3 - this.__private.get_number_digits_count(this.__private.volume_value)) .. this.__private.get_volume_value_string() .. " "
      end,
      2^22,
      "Master"
    )

    this.__private.settings_popup = awful.popup {
      widget = {},
      type = "dropdown_menu",
      shape = gears.shape.rounded_rect,
      input_passthrough = true,
      visible = false,
      ontop = true,
      bg = beautiful.bg_normal .. "99",
    }
    this.__private.rebuild_popup()

    root.buttons(gears.table.join(root.buttons(),
        awful.button({}, 1, this.__public.hide_dropdown),
        awful.button({}, 2, this.__public.hide_dropdown),
        awful.button({}, 3, this.__public.hide_dropdown)
    ))

    this.__private.settings_popup:connect_signal("property::visible", function()
      local _key_grabber
      if this.__private.settings_popup.visible then
        _key_grabber = awful.keygrabber.run(function(mod, key, event)
          if event == "release" then
            return false
          end
          this.__public.hide_dropdown()
          awful.keygrabber.stop(_key_grabber)
        end)
      else
        awful.keygrabber.stop(_key_grabber)
      end
    end)
  end

  return this
end

VolumeWidget = createClass(VolumeWidget_prototype)
