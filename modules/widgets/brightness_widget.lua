local awful = require("awful")
local wibox = require("wibox")
local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

BrightnessWidget_prototype = function()
  local this = {}

  local slider_max_value = 24000
  local default_slider_value = slider_max_value - 5500

  this.__public_static = {
    -- Public Static Variables
    -- Public Static Funcs
  }

  this.__private_static = {
    -- Private Static Variables
    config_path = gears.filesystem.get_configuration_dir(),
    -- Private Static Funcs
    clamp_time = function(value)
      local seconds_in_minute = 1 * 60
      local seconds_in_day = 24 * 60 * 60
      value = value >= 0 and value or 0
      value = value <= seconds_in_day - seconds_in_minute
        and value
        or seconds_in_day - seconds_in_minute

      return value
    end,
    is_enabled_schedule = function()
      local redshift_dawn_time = get_redshift_dawn_time()
      local redshift_dusk_time = get_redshift_dusk_time()

      return redshift_dawn_time ~= nil and redshift_dusk_time ~= nil
    end,
    get_schedule_start_time = function()
      local redshift_dusk_time = get_redshift_dusk_time()
      if redshift_dusk_time ~= nil then
        local time_parts_matches = redshift_dusk_time:gmatch("(%d+)")

        local hours = nil
        local minutes = nil

        for time_parts_match in time_parts_matches do
          if hours == nil then
            hours = tonumber(time_parts_match)
          else
            if minutes == nil then
              minutes = tonumber(time_parts_match)
            end
          end
        end

        if hours ~= nil and minutes ~= nil then
          return (hours * 60 + minutes) * 60
        end
      end

      return 20 * 60 * 60
    end,
    get_schedule_end_time = function()
      local redshift_dawn_time = get_redshift_dawn_time()
      if redshift_dawn_time ~= nil then
        local time_parts_matches = redshift_dawn_time:gmatch("(%d+)")

        local hours = nil
        local minutes = nil

        for time_parts_match in time_parts_matches do
          if hours == nil then
            hours = tonumber(time_parts_match)
          else
            if minutes == nil then
              minutes = tonumber(time_parts_match)
            end
          end
        end

        if hours ~= nil and minutes ~= nil then
          return (hours * 60 + minutes) * 60
        end
      end

      return 06 * 60 * 60
    end,
    create_timer_part_widget = function(value)
      return wibox.widget {
        {
          {
            text = lpad_string(tostring(value), 2, '0'),
            widget = wibox.widget.textbox
          },
          top = dpi(2),
          right = dpi(4),
          bottom = dpi(2),
          left = dpi(4),
          widget = wibox.container.margin
        },
        bg = beautiful.background_color .. "66",
        shape = function(cr, width, height)
          gears.shape.rounded_rect(cr, width, height, dpi(3))
        end,
        widget = wibox.container.background
      }
    end,
    create_time_picker = function(time_seconds, set_time)
      local hours = math.floor(time_seconds / (60 * 60) % 24)
      local minutes = math.floor(time_seconds / 60 % 60)

      local hours_widget = this.__private_static.create_timer_part_widget(hours)
      local minutes_widget = this.__private_static.create_timer_part_widget(minutes)

      local increment_hours = function()
        set_time(time_seconds + 60 * 60)
      end

      local decrement_hours = function()
        set_time(time_seconds - 60 * 60)
      end

      local increment_minutes = function()
        set_time(time_seconds + 1 * 60)
      end

      local decrement_minutes = function()
        set_time(time_seconds - 1 * 60)
      end

      hours_widget:buttons(
        awful.util.table.join(
          awful.button({}, 1, increment_hours),
          awful.button({}, 3, decrement_hours),
          awful.button({}, 4, increment_hours),
          awful.button({}, 5, decrement_hours)
        )
      )

      minutes_widget:buttons(
        awful.util.table.join(
          awful.button({}, 1, increment_minutes),
          awful.button({}, 3, decrement_minutes),
          awful.button({}, 4, increment_minutes),
          awful.button({}, 5, decrement_minutes)
        )
      )

      return wibox.widget {
        hours_widget,
        {
          {
            text = ":",
            widget = wibox.widget.textbox
          },
          left = dpi(2),
          right = dpi(2),
          layout = wibox.container.margin
        },
        minutes_widget,
        layout = wibox.layout.fixed.horizontal
      }
    end
  }

  this.__public = {
    -- Public Variables
    name = "BrightnessWidget",
    icon = wibox.widget.imagebox(),
    value = nil,
    -- Public Funcs
    on_container_created = function(container, panel_position)
      get_redshift_installed(function(is_redshift_installed)
        if is_redshift_installed then
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
          awful.button({}, 4, function() this.__private.set_brightness(5, true) end),
          awful.button({}, 5, function() this.__private.set_brightness(5, false) end)
        )
      )
    end,
    update = function(brightness_percentage)
      this.__private.rebuild_popup()
      this.__public.icon.image = gears.color.recolor_image(this.__private_static.config_path .. "/themes/relz/icons/widgets/brightness/brightness_" .. this.__private.compute_brightness_level(brightness_percentage) .. ".svg", beautiful.text_color)
      if this.__private.show_text then
        this.__public.value.text = string.rep(" ", 3 - this.__private.get_number_digits_count(brightness_percentage)) ..  brightness_percentage .. "% "
      end
    end,
    hide_dropdown = function()
      this.__private.settings_popup.visible = false
    end,
    set_geolocation = function(geolocation)
      if geolocation.latitude == nil or geolocation.longitude == nil then
        return
      end
      local sunrise_time_total_minutes = get_sunrise_time_minutes(geolocation.latitude, geolocation.longitude)
      local sunrise_time_hours = math.floor(sunrise_time_total_minutes / 60)
      local sunrise_time_minutes = round_number(sunrise_time_total_minutes % 60)
      this.__private.sunrise_datetime = create_local_datetime(nil, nil, nil, sunrise_time_hours, sunrise_time_minutes, 0)

      local sunset_time_total_minutes = get_sunset_time_minutes(geolocation.latitude, geolocation.longitude)
      local sunset_time_hours = math.floor(sunset_time_total_minutes / 60)
      local sunset_time_minutes = round_number(sunset_time_total_minutes % 60)
      this.__private.sunset_datetime = create_local_datetime(nil, nil, nil, sunset_time_hours, sunset_time_minutes, 0)

      this.__private.is_enabled_schedule_auto_mode = get_redshift_dawn_time() == os.date("%H:%M", this.__private.sunrise_datetime) and get_redshift_dusk_time() == os.date("%H:%M", this.__private.sunset_datetime)
      this.__private.is_enabled_schedule_manual_mode = not this.__private.is_enabled_schedule_auto_mode

      this.__private.schedule_start_time = this.__private_static.get_schedule_start_time()
      this.__private.schedule_end_time = this.__private_static.get_schedule_end_time()
    end,
  }

  this.__private = {
    -- Private Variables
    show_text = false,
    sunrise_datetime = nil,
    sunset_datetime = nil,
    settings_popup = nil,
    slider = nil,
    slider_value = default_slider_value,
    is_enabled_schedule = false,
    is_enabled_schedule_auto_mode = false,
    is_enabled_schedule_manual_mode = false,
    schedule_start_time = 0,
    schedule_end_time = 0,
    -- Private Funcs
    get_number_digits_count = function(number)
      return number < 10 and 1 or (number < 100 and 2 or 3)
    end,
    compute_brightness_level = function(brightness_percentage)
      if brightness_percentage > 66 then
        return "high"
      end
      if brightness_percentage > 33 then
        return "medium"
      end
      return "low"
    end,
    set_brightness = function(step_percent, increase)
      set_system_brightness(
        step_percent,
        increase,
        function(new_value_percent)
          this.__public.update(new_value_percent)
        end
      )
    end,
    toggle_schedule = function()
      this.__private.is_enabled_schedule = not this.__private.is_enabled_schedule

      if this.__private.is_enabled_schedule then
        this.__private.slider_value = default_slider_value
        this.__private.slider.value = this.__private.slider_value
        if this.__private.is_enabled_schedule_auto_mode then
          set_redshift_dawn_time(this.__private.sunrise_datetime)
          set_redshift_dusk_time(this.__private.sunset_datetime)
        else
          if this.__private.is_enabled_schedule_manual_mode then
            local schedule_start_time = create_today() + this.__private.schedule_start_time
            local schedule_end_time = create_today() + this.__private.schedule_end_time
            set_redshift_dawn_time(schedule_end_time)
            set_redshift_dusk_time(schedule_start_time)
            restart_redshift()
          end
        end
        reset_redshift()
        restart_redshift()
      else
        set_redshift_dawn_time(nil)
        set_redshift_dusk_time(nil)
        stop_redshift()
      end

      this.__private.rebuild_popup()
    end,
    toggle_schedule_auto_mode = function()
      this.__private.is_enabled_schedule_auto_mode = not this.__private.is_enabled_schedule_auto_mode
      this.__private.is_enabled_schedule_manual_mode = not this.__private.is_enabled_schedule_auto_mode
      this.__private.rebuild_popup()

      if this.__private.is_enabled_schedule_auto_mode then
        set_redshift_dawn_time(this.__private.sunrise_datetime)
        set_redshift_dusk_time(this.__private.sunset_datetime)
        restart_redshift()
      end
    end,
    toggle_schedule_manual_mode = function()
      this.__private.is_enabled_schedule_manual_mode = not this.__private.is_enabled_schedule_manual_mode
      this.__private.is_enabled_schedule_auto_mode = not this.__private.is_enabled_schedule_manual_mode
      this.__private.rebuild_popup()

      if this.__private.is_enabled_schedule_manual_mode then
        local schedule_start_time = create_today() + this.__private.schedule_start_time
        local schedule_end_time = create_today() + this.__private.schedule_end_time
        set_redshift_dawn_time(schedule_end_time)
        set_redshift_dusk_time(schedule_start_time)
        restart_redshift()
      end
    end,
    set_schedule_start_time = function(value)
      this.__private.schedule_start_time = this.__private_static.clamp_time(value)
      this.__private.rebuild_popup()

      if this.__private.is_enabled_schedule_manual_mode then
        local schedule_start_time = create_today() + this.__private.schedule_start_time
        local schedule_end_time = create_today() + this.__private.schedule_end_time
        set_redshift_dawn_time(schedule_end_time)
        set_redshift_dusk_time(schedule_start_time)
        restart_redshift()
      end
    end,
    set_schedule_end_time = function(value)
      this.__private.schedule_end_time = this.__private_static.clamp_time(value)
      this.__private.rebuild_popup()

      if this.__private.is_enabled_schedule_manual_mode then
        local schedule_start_time = create_today() + this.__private.schedule_start_time
        local schedule_end_time = create_today() + this.__private.schedule_end_time
        set_redshift_dawn_time(schedule_end_time)
        set_redshift_dusk_time(schedule_start_time)
        restart_redshift()
      end
    end,
    build_popup_header_row = function(text)
      return wibox.widget{
        {
          markup = "<b>" .. text .. "</b>",
          align = "center",
          widget = wibox.widget.textbox
        },
        margins = dpi(8),
        widget = wibox.container.margin
      }
    end,
    build_color_temperature_slider_row = function()
      local width = dpi(240)

      local reset_button = wibox.widget {
        {
          {
            text = 'Reset',
            widget = wibox.widget.textbox
          },
          top = dpi(2),
          right = dpi(8),
          left = dpi(8),
          bottom = dpi(2),
          widget = wibox.container.margin
        },
        shape = gears.shape.rounded_rect,
        bg = gears.color.transparent,
        fg = beautiful.text_color,
        shape_border_width = dpi(1),
        shape_border_color = beautiful.text_color,
        opacity = this.__private.is_enabled_schedule and 0.3 or 1,
        widget = wibox.container.background
      }

      reset_button:connect_signal("mouse::enter", function()
        if this.__private.is_enabled_schedule then
          return
        end
        reset_button.fg = beautiful.fg_focus
        reset_button.bg = beautiful.text_color
        reset_button.shape_border_width = dpi(0)
        reset_button.shape_border_color = reset_button.fg
      end)

      reset_button:connect_signal("mouse::leave", function()
        reset_button.bg = gears.color.transparent
        reset_button.fg = beautiful.text_color
        reset_button.shape_border_width = dpi(1)
        reset_button.shape_border_color = reset_button.fg
      end)

      local slider_handle_color_from = "#0000ff"
      local slider_handle_color_to = "#ff0000"

      this.__private.slider = wibox.widget {
        forced_width = width,
        forced_height = dpi(20),
        bar_shape = gears.shape.rounded_rect,
        bar_height = dpi(4),
        bar_color = gears.color.create_linear_pattern({
          from = {0, 0},
          to = {width, 0},
          stops = {
            {0, slider_handle_color_from .. "66"},
            {1, slider_handle_color_to .. "66"},
          },
        }),
        handle_shape = gears.shape.circle,
        handle_color = get_color_between(slider_handle_color_from, slider_handle_color_to, this.__private.slider_value / slider_max_value),
        opacity = this.__private.is_enabled_schedule and 0.3 or 1,
        minimum = 0,
        maximum = slider_max_value,
        value = this.__private.slider_value,
        widget = wibox.widget.slider,
      }

      this.__private.slider.value = this.__private.slider_value

      reset_button:connect_signal("button::press", function()
        if this.__private.is_enabled_schedule then
          return
        end
        reset_redshift()
        this.__private.slider_value = default_slider_value
        this.__private.slider.value = this.__private.slider_value
      end)

      this.__private.slider:connect_signal("property::value", function()
        if this.__private.is_enabled_schedule then
          this.__private.slider_value = default_slider_value
          this.__private.slider.value = this.__private.slider_value
          return
        end
        this.__private.slider_value = this.__private.slider.value
        this.__private.slider.handle_color = get_color_between(slider_handle_color_from, slider_handle_color_to, this.__private.slider_value / slider_max_value)

        local color_temperature = slider_max_value - this.__private.slider_value + 1000
        set_color_temperature(color_temperature)
      end)

      return wibox.widget {
        {
          this.__private.slider,
          {
            forced_width = dpi(8),
            widget = wibox.container.constraint
          },
          reset_button,
          layout = wibox.layout.fixed.horizontal,
        },
        right = dpi(8),
        bottom = dpi(8),
        left = dpi(8),
        widget = wibox.container.margin,
    }
    end,
    build_enable_schedule_row = function(on_click)
      local checkbox_background = this.__private.is_enabled_schedule
        and beautiful.text_color
        or beautiful.background_color

      local checkbox = wibox.widget {
        checked = this.__private.is_enabled_schedule,
        paddings = dpi(2),
        forced_width = dpi(16),
        forced_height = dpi(16),
        bg = checkbox_background,
        check_border_color = beautiful.background_color,
        shape = function(cr, width, height)
          gears.shape.rounded_rect(cr, width, height, dpi(2))
        end,
        check_shape = function(cr, width, height)
            local size = math.min(width, height)
            local half_size = size * 0.5
            cr:move_to(0, half_size)
            cr:line_to(half_size * 0.8, size * 0.9)
            cr:line_to(size, half_size * 0.2)
        end,
        widget = wibox.widget.checkbox
      }

      local row = wibox.widget {
        {
          {
            checkbox,
            valign = "center",
            layout = wibox.container.place,
          },
          {
            {
              text = "Schedule night light",
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
      }

      row:connect_signal("button::press", on_click)

      return row
    end,
    build_schedule_auto_mode_toggle_row = function(on_click)
      local checkbox = wibox.widget {
        checked = this.__private.is_enabled_schedule_auto_mode,
        paddings = dpi(3),
        forced_width = dpi(16),
        forced_height = dpi(16),
        widget = wibox.widget.checkbox
      }

      local row = wibox.widget {
        {
          {
            checkbox,
            valign = "center",
            layout = wibox.container.place,
          },
          {
            {
              text = "Sunset to sunrise (" .. os.date("%H:%M", this.__private.sunset_datetime) .. " — " .. os.date("%H:%M", this.__private.sunrise_datetime) .. ")",
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
      }

      row:connect_signal("button::press", on_click)

      return row
    end,
    build_schedule_manual_mode_toggle_row = function(on_click)
      local checkbox = wibox.widget {
        checked = this.__private.is_enabled_schedule_manual_mode,
        paddings = dpi(3),
        forced_width = dpi(16),
        forced_height = dpi(16),
        widget = wibox.widget.checkbox
      }

      local row = wibox.widget {
        {
          {
            checkbox,
            valign = "center",
            layout = wibox.container.place,
          },
          {
            {
              text = "Set hours",
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
      }

      row:connect_signal("button::press", on_click)

      return row
    end,
    build_schedule_manual_mode_start_row = function(set_time)
      return wibox.widget {
        {
          {
            {
              text = "Turn on: ",
              align = "left",
              widget = wibox.widget.textbox
            },
            left = dpi(24),
            right = dpi(8),
            layout = wibox.container.margin
          },
          this.__private_static.create_time_picker(this.__private.schedule_start_time, set_time),
          layout = wibox.layout.fixed.horizontal
        },
        margins = dpi(8),
        layout = wibox.container.margin
      }
    end,
    build_schedule_manual_mode_end_row = function(set_time)
      return wibox.widget {
        {
          {
            {
              text = "Turn off:",
              align = "left",
              widget = wibox.widget.textbox
            },
            left = dpi(24),
            right = dpi(8),
            layout = wibox.container.margin
          },
          this.__private_static.create_time_picker(this.__private.schedule_end_time, set_time),
          layout = wibox.layout.fixed.horizontal
        },
        margins = dpi(8),
        layout = wibox.container.margin
      }
    end,
    rebuild_popup = function()
      local rows  = { layout = wibox.layout.fixed.vertical }

      table.insert(rows, this.__private.build_popup_header_row("COLOR TEMPERATURE"))
      table.insert(rows, this.__private.build_color_temperature_slider_row())
      table.insert(rows, this.__private.build_enable_schedule_row(this.__private.toggle_schedule))

      if this.__private.is_enabled_schedule then
        if this.__private.sunrise_datetime ~= nil and this.__private.sunset_datetime ~= nil then
          table.insert(rows, this.__private.build_schedule_auto_mode_toggle_row(this.__private.toggle_schedule_auto_mode))
        end
        table.insert(rows, this.__private.build_schedule_manual_mode_toggle_row(this.__private.toggle_schedule_manual_mode))
      end

      if this.__private.is_enabled_schedule and this.__private.is_enabled_schedule_manual_mode then
        table.insert(rows, this.__private.build_schedule_manual_mode_start_row(this.__private.set_schedule_start_time))
        table.insert(rows, this.__private.build_schedule_manual_mode_end_row(this.__private.set_schedule_end_time))
      end

      this.__private.settings_popup:setup(rows)
    end,
  }

  this.__construct = function(show_text, brightness_percentage)
    -- Constructor
    this.__private.show_text = show_text

    if this.__private.show_text then
      this.__public.value = wibox.widget.textbox()
      this.__public.value.font = beautiful.font_family_mono .. "Bold 9"
    end

    this.__private.is_enabled_schedule = this.__private_static.is_enabled_schedule()

    if this.__private.is_enabled_schedule then
      restart_redshift()
    end

    this.__private.settings_popup = awful.popup {
      widget = {},
      type = "dropdown_menu",
      shape = gears.shape.rounded_rect,
      input_passthrough = true,
      visible = false,
      ontop = true,
      bg = beautiful.bg_normal .. "99",
    }

    this.__public.update(brightness_percentage)

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

BrightnessWidget = createClass(BrightnessWidget_prototype)
