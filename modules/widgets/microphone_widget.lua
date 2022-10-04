local awful = require("awful")
local wibox = require("wibox")
local vicious = require("vicious")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

MicrophoneWidget_prototype = function()
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
    name = "MicrophoneWidget",
    icon = wibox.widget.imagebox(),
    value = nil,
    -- Public Funcs
    on_container_created = function(container, panel_position)
      get_audio_server_installed(function(is_audio_server_installed)
        if is_audio_server_installed then
          local is_top_panel_position = panel_position == "top"
          local is_right_panel_position = panel_position == "right"
          local is_bottom_panel_position = panel_position == "bottom"
          local is_left_panel_position = panel_position == "left"

          local offset_x = dpi(is_left_panel_position and 8 or is_right_panel_position and -8 or 0)
          local offset_y = dpi(is_top_panel_position and 8 or is_bottom_panel_position and -8 or 0)

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
        end
      end)

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
    settings_popup = nil,
    -- Private Funcs
    set_volume = function(step, increase)
      set_source_volume(step, increase, function() vicious.force({ this.__public.icon }) end)
    end,
    update = function()
      this.__private.rebuild_popup()
      this.__private.set_volume(this.__private.volume_value)
    end,
    build_popup_devices_rows = function(devices, on_checkbox_click, command)
      local device_rows  = { layout = wibox.layout.fixed.vertical }

      for _, device in pairs(devices) do

        local checkbox = wibox.widget {
          checked = device.is_default,
          paddings = dpi(3),
          forced_width = dpi(16),
          forced_height = dpi(16),
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
                left = dpi(8),
                layout = wibox.container.margin
              },
              layout = wibox.layout.align.horizontal
            },
            margins = dpi(8),
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
          awful.spawn.easy_async(string.format([[pactl %s "%s" %s]], command, device["Name"], profile_name), on_checkbox_click)
        end)

        table.insert(device_rows, row)
      end

      return device_rows
    end,
    get_device_name = function(device)
      local port = nil
      if device.active_port ~= nil and device.ports[device.active_port] ~= nil then
        port = device.ports[device.active_port]
      elseif device.monitor_sink ~= nil and device.monitor_sink.active_port ~= nil then
        port = device.monitor_sink.ports[device.monitor_sink.active_port]
      end

      local device_name = device.properties.device_description
      if device.monitor_sink ~= nil and not device_name:match("Monitor of ") then
        device_name = "Monitor of " .. device_name
      end

      if device.profile_short_description ~= nil then
        device_name = device_name .. " · " .. device.profile_short_description
      elseif port ~= nil then
        device_name = device_name .. " · " .. port.name
      end

      return device_name
    end,
    rebuild_popup = function()
      local rows  = { layout = wibox.layout.fixed.vertical }
      awful.spawn.easy_async("pactl list cards", function(get_cards_stdout)

        local cards = parse_audio_server_devices(get_cards_stdout)

        awful.spawn.easy_async("pactl list sinks", function(get_sinks_stdout)
          get_default_sink(function(default_sink)
            local sinks = parse_audio_server_devices(get_sinks_stdout, default_sink)

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
              local switch_profile_short_description

              for profile_name, profile_description in pairs(card.profiles) do
                local bluetooth_profile = card_sink.properties.bluetooth_protocol or card_sink.properties.api_bluez5_profile
                if bluetooth_profile ~= profile_name then
                  if string.match(profile_description, "High Fidelity Playback %(A2DP Sink%)") then
                    switch_profile_name = profile_name
                    switch_profile_short_description = card_sink.properties.bluetooth_protocol == nil
                      and "Headset"
                      or profile_description:match("^(.+) %(")
                  end
                end
              end

              if switch_profile_name ~= nil then
                table.insert(
                  other_profiles_sinks,
                  {
                    is_default = false,
                    Name = card["Name"],
                    profile_name = switch_profile_name,
                    profile_short_description = switch_profile_short_description,
                    properties = {
                      device_description = card_sink.properties.device_description
                    },
                    ports = card_sink.ports,
                    active_port = card_sink.active_port
                  }
                )
              end

              switch_profile_name = nil
              switch_profile_short_description = nil

              for profile_name, profile_description in pairs(card.profiles) do
                local bluetooth_profile = card_sink.properties.bluetooth_protocol or card_sink.properties.api_bluez5_profile
                if bluetooth_profile ~= profile_name then
                  if string.match(profile_description, "Handsfree Head Unit %(HFP%)") or string.match(profile_description, "Headset Head Unit %(HSP/HFP%)") then
                    switch_profile_name = profile_name
                    switch_profile_short_description = card_sink.properties.bluetooth_protocol == nil
                      and "Handsfree"
                      or "Headset"
                  end
                end
              end

              if switch_profile_name ~= nil then
                table.insert(
                  other_profiles_sources,
                  {
                    is_default = false,
                    Name = card["Name"],
                    profile_name = switch_profile_name,
                    profile_short_description = switch_profile_short_description,
                    properties = {
                      device_description = card_sink.properties.device_description
                    },
                    ports = card_sink.ports,
                    active_port = card_sink.active_port
                  }
                )
              end

              ::continue::
            end

            awful.spawn.easy_async("pactl list sources", function(get_sources_stdout)
              get_default_source(function(default_source)
                local sources = parse_audio_server_devices(get_sources_stdout, default_source)

                for _,source in ipairs(sources) do
                  for _,sink in ipairs(sinks) do
                    if source["Monitor of Sink"] == sink["Name"] then
                      source.monitor_sink = {
                        ports = sink.ports,
                        active_port = sink.active_port
                      }
                      goto continue
                    end
                  end
                  ::continue::
                end

                table.insert(rows, this.__private.build_popup_devices_rows(sources, this.__private.update, "set-default-source"))
                table.insert(rows, this.__private.build_popup_devices_rows(other_profiles_sources, this.__private.update, "set-card-profile"))

                this.__private.settings_popup:setup(rows)
              end)
            end)
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
      this.__public.value.font = beautiful.font_family_mono .. "Bold 9"
    end

    vicious.register(
      this.__public.icon,
      vicious.widgets.volume,
      function()
        get_source_volume(function(current_volume)
          this.__private.volume_value = current_volume
          this.__private.is_muted = current_volume == 0

          local icon_file_name = "microphone"
          if this.__private.is_muted then
            icon_file_name = icon_file_name .. "_muted"
          end
          this.__public.icon.image = gears.color.recolor_image(this.__private_static.config_path .. "/themes/relz/icons/widgets/microphone/" .. icon_file_name .. ".svg", beautiful.text_color)

          if this.__private.show_text then
            this.__public.value.text = string.rep(" ", 3 - get_percent_number_digits_count(this.__private.volume_value)) .. this.__private.volume_value .. "% "
          end
        end)
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

MicrophoneWidget = createClass(MicrophoneWidget_prototype)
