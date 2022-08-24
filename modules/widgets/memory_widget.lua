local awful = require("awful")
local wibox = require("wibox")
local vicious = require("vicious")
local gears = require("gears")
local beautiful = require("beautiful")

MemoryWidget_prototype = function()
  local this = {}

  this.__public_static = {
    -- Public Static Variables
    -- Public Static Funcs
  }

  this.__private_static = {
    -- Private Static Variables
    config_path = gears.filesystem.get_configuration_dir(),
    -- Private Static Funcs
    compute_used_level = function(used_percentage)
      if used_percentage > 95 then
        return "100"
      end
      if used_percentage > 90 then
        return "90"
      end
      if used_percentage > 80 then
        return "80"
      end
      if used_percentage > 70 then
        return "70"
      end
      if used_percentage > 60 then
        return "60"
      end
      if used_percentage > 50 then
        return "50"
      end
      if used_percentage > 40 then
        return "40"
      end
      if used_percentage > 30 then
        return "30"
      end
      if used_percentage > 20 then
        return "20"
      end
      if used_percentage > 10 then
        return "10"
      end
      return "0"
    end
  }

  this.__public = {
    -- Public Variables
    name = "MemoryWidget",
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
    end
  }

  this.__private = {
    -- Private Variables
    on_click_command = nil,
    tooltip = awful.tooltip({
      timer_function = function()
        return this.__private.memory_used
      end,
      mode = "outside"
    }),
    memory_used = "",
    -- Private Funcs
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
      vicious.widgets.mem,
      function(widget, args)
        local mem_used = args[2];
        local used_percentage = args[1];
        this.__private.memory_used = mem_used .. "MB"
        this.__public.icon.image = gears.color.recolor_image(this.__private_static.config_path .. "/themes/relz/icons/widgets/memory/memory_" .. this.__private_static.compute_used_level(used_percentage) .. ".svg", beautiful.text_color)
        if this.__private.show_text then
          this.__public.value.text = string.rep(" ", 3 - get_percent_number_digits_count(used_percentage)) .. used_percentage .. "% "
        end
      end,
      2^2
    )
  end

  return this
end

MemoryWidget = createClass(MemoryWidget_prototype)
