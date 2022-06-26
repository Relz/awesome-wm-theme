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
    config_path = gears.filesystem.get_configuration_dir()
    -- Private Static Funcs
  }

  this.__public = {
    -- Public Variables
    name = "VolumeWidget",
    icon = wibox.widget.imagebox(),
    value = nil,
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

      container:buttons(
        awful.util.table.join(
          awful.button({}, 4, function() this.__private.set_volume(5, true) end),
          awful.button({}, 5, function() this.__private.set_volume(5, false) end)
        )
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
    set_volume = function(step, increase)
      set_system_volume(step, increase, function() vicious.force({ this.__public.icon }) end)
    end,
    update = function()
      this.__private.rebuild_popup()
      this.__private.set_volume(this.__private.volume_value)
    end,
    get_devices = function(pacmd_output)
      local devices = {}

      local device
      local properties
      local profiles
      local sinks
      local sources
      local ports
      local port
      local port_properties

      local in_device = false
      local in_properties = false
      local in_ports = false
      local in_profiles = false
      local in_sinks = false
      local in_sources = false
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
          in_profiles = false
          in_sinks = false
          in_sources = false
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
          in_profiles = false
          in_sinks = false
          in_sources = false
          in_port_properties = false
          properties = {}
          device.properties = properties
          goto continue
        end

        if string.match(line, "^\tprofiles:") then
          in_device = false
          in_properties = false
          in_ports = false
          in_profiles = true
          in_sinks = false
          in_sources = false
          in_port_properties = false
          profiles = {}
          device.profiles = profiles
          goto continue
        end

        if string.match(line, "active profile:") then
          in_device = false
          in_properties = false
          in_ports = false
          in_profiles = false
          in_sinks = false
          in_sources = false
          in_port_properties = false
          device.active_profile = line:match(": (.+)"):gsub("<",""):gsub(">","")
          goto continue
        end

        if string.match(line, "^\tsinks:") then
          in_device = false
          in_properties = false
          in_ports = false
          in_profiles = false
          in_sinks = true
          in_sources = false
          in_port_properties = false
          sinks = {}
          device.sinks = sinks
          goto continue
        end

        if string.match(line, "^\tsources:") then
          in_device = false
          in_properties = false
          in_ports = false
          in_profiles = false
          in_sinks = false
          in_sources = true
          in_port_properties = false
          sources = {}
          device.sources = sources
          goto continue
        end

        if string.match(line, "ports:") then
          in_device = false
          in_properties = false
          in_ports = true
          in_profiles = false
          in_sinks = false
          in_sources = false
          in_port_properties = false
          ports = {}
          device.ports = ports
          goto continue
        end

        if in_ports and string.match(line, "^\t\t\tproperties:") then
          in_device = false
          in_properties = false
          in_ports = false
          in_profiles = false
          in_sinks = false
          in_sources = false
          in_port_properties = true
          port_properties = {}
          ports[port].properties = port_properties
          goto continue
        end

        if string.match(line, "active port:") then
          in_device = false
          in_properties = false
          in_ports = false
          in_profiles = false
          in_sinks = false
          in_sources = false
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

        if in_profiles then
          local key = line:match("\t+(%S+):")
          local value = line:match(": (.+) %(")

          profiles[key] = value
        end

        if in_sinks then
          local key = line:match("\t+(%S+):")
          local value = line:match(": (.+) %(")

          sinks[key] = value
        end

        if in_sources then
          local key = line:match("\t+(%S+):")
          local value = line:match(": (.+) %(")

          sources[key] = value
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
    build_popup_header_row = function(text)
      return wibox.widget{
        {
          {
            markup = "<b>" .. text .. "</b>",
            align = "center",
            widget = wibox.widget.textbox
          },
          widget = wibox.container.background,
        },
        margins = 8,
        widget = wibox.container.margin
      }
    end,
    build_popup_devices_rows = function(devices, on_checkbox_click, command)
      local device_rows  = { layout = wibox.layout.fixed.vertical }

      for _, device in pairs(devices) do

        local checkbox = wibox.widget {
          checked = device.is_default,
          paddings = 3,
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
                left = 8,
                layout = wibox.container.margin
              },
              layout = wibox.layout.align.horizontal
            },
            margins = 8,
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

        local profile_name = device.profile_name and device.profile_name or ""

        row:connect_signal("button::press", function()
          awful.spawn.easy_async(string.format([[pacmd %s "%s" %s]], command, device.name, profile_name), on_checkbox_click)
        end)

        table.insert(device_rows, row)
      end

      return device_rows
    end,
    get_device_name = function(device)
      local port = nil
      if device.active_port ~= nil and device.ports[device.active_port] ~= nil then
        port = device.ports[device.active_port]
      end

      local device_name = device.properties.device_description

      if device.profile_short_description ~= nil then
        device_name = device_name .. " · " .. device.profile_short_description
      else
        if port ~= nil then
          device_name = device_name .. " · " .. port.name
        end
      end

      return device_name
    end,
    rebuild_popup = function ()
      local rows  = { layout = wibox.layout.fixed.vertical }
      awful.spawn.easy_async("pacmd list-cards", function(get_cards_stdout)

        local cards = this.__private.get_devices(get_cards_stdout)

        awful.spawn.easy_async("pacmd list-sinks", function(get_sinks_stdout)

          local sinks = this.__private.get_devices(get_sinks_stdout)

          local other_profiles_sinks = {}
          local other_profiles_sources = {}

          for _,card in ipairs(cards) do
            local card_sink

            for _,sink in ipairs(sinks) do
              if card.properties.device_description == sink.properties.device_description then
                card_sink = sink
              end
            end

            if card_sink == nil then
              goto continue
            end

            local switch_profile_name
            local profile_short_description
            local switch_profile_short_description

            for profile_name, profile_description in pairs(card.profiles) do
              if card_sink.properties.bluetooth_protocol == profile_name then
                profile_short_description = profile_description:match("^(.+) %(")
              else
                if string.match(profile_description, "High Fidelity Playback %(A2DP Sink%)") then
                  switch_profile_name = profile_name
                  switch_profile_short_description = profile_description:match("^(.+) %(")
                end
              end
            end

            if switch_profile_name ~= nil then
              table.insert(
                other_profiles_sinks,
                {
                  is_default = false,
                  name = card.name,
                  profile_name = switch_profile_name,
                  profile_short_description = switch_profile_short_description,
                  properties = {
                    device_description = card_sink.properties.device_description
                  },
                  ports = card_sink.ports,
                  active_port = card_sink.active_port
                }
              )

              card_sink.profile_short_description = profile_short_description
            end

            switch_profile_name = nil
            profile_short_description = nil
            switch_profile_short_description = nil

            for profile_name, profile_description in pairs(card.profiles) do
              if card_sink.properties.bluetooth_protocol == profile_name then
                profile_short_description = profile_description:match("^(.+) %(")
              else
                if string.match(profile_description, "Handsfree Head Unit %(HFP%)") then
                  switch_profile_name = profile_name
                  switch_profile_short_description = profile_description:match("^(.+) %(")
                end
              end
            end

            if switch_profile_name ~= nil then
              table.insert(
                other_profiles_sources,
                {
                  is_default = false,
                  name = card.name,
                  profile_name = switch_profile_name,
                  profile_short_description = switch_profile_short_description,
                  properties = {
                    device_description = card_sink.properties.device_description
                  },
                  ports = card_sink.ports,
                  active_port = card_sink.active_port
                }
              )

              card_sink.profile_short_description = profile_short_description
            end

            ::continue::
          end

          table.insert(rows, this.__private.build_popup_header_row("OUTPUTS"))
          table.insert(rows, this.__private.build_popup_devices_rows(sinks, this.__private.update, "set-default-sink"))
          table.insert(rows, this.__private.build_popup_devices_rows(other_profiles_sinks, this.__private.update, "set-card-profile"))

          awful.spawn.easy_async("pacmd list-sources", function(get_sources_stdout)

            local sources = this.__private.get_devices(get_sources_stdout)

            table.insert(rows, this.__private.build_popup_header_row("INPUTS"))
            table.insert(rows, this.__private.build_popup_devices_rows(sources, this.__private.update, "set-default-source"))
            table.insert(rows, this.__private.build_popup_devices_rows(other_profiles_sources, this.__private.update, "set-card-profile"))

            this.__private.settings_popup:setup(rows)
          end)
        end)
      end)
    end,
  }

  this.__construct = function(show_text)
    -- Constructor
    this.__private.show_text = show_text

    if this.__private.show_text then
      this.__public.value = wibox.widget.textbox()
      this.__public.value.font = "Droid Sans Mono Bold 9"
    end

    vicious.register(
      this.__public.icon,
      vicious.widgets.volume,
      function (widget, args)
        this.__private.volume_value = args[1]
        this.__private.is_muted = args[2] == "🔈"
        this.__public.icon.image = gears.color.recolor_image(this.__private_static.config_path .. "/themes/relz/icons/widgets/volume/volume_" .. this.__private.compute_volume_level(this.__private.is_muted, this.__private.volume_value) .. ".svg", beautiful.text_color)

        if this.__private.show_text then
          this.__public.value.text = string.rep(" ", 3 - get_percent_number_digits_count(this.__private.volume_value)) .. this.__private.volume_value .. "% "
        end
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
