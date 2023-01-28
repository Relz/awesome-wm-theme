local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local _screens = {}

local function get_screen_count()
  return #_screens
end

local function set_screens(screens)
  _screens = {}
  for _,screen in ipairs(screens) do
    table.insert(_screens, screen)
  end
end

local function add_screen(screen)
  table.insert(_screens, screen)
end

local function apply_wallpaper(screen_index, wallpaper)
  gears.wallpaper.maximized(wallpaper, screen_index, true)
end

local function is_horizontal_position(panel_position)
  return panel_position == "top" or panel_position == "bottom"
end

local function get_direction_by_position(panel_position)
  if is_horizontal_position(panel_position) then
    return "north"
  else
    if panel_position == "left" then
      return "east"
    else
      return "west"
    end
  end
end

local function get_aligned_layout(panel_position)
  return is_horizontal_position(panel_position) and wibox.layout.align.horizontal or wibox.layout.align.vertical
end

local function create_aligned_layout(panel_position)
  return get_aligned_layout(panel_position)()
end

local function get_fixed_layout(panel_position)
  return is_horizontal_position(panel_position) and wibox.layout.fixed.horizontal or wibox.layout.fixed.vertical
end

local function create_fixed_layout(panel_position, widgets)
  if widgets == nil then
    widgets = {}
  end
  return get_fixed_layout(panel_position)(table.unpack(widgets))
end

local create_tasklist = function(screen_index, panel_position, tag, tasks)
	return awful.widget.tasklist({
		screen = screen_index,
		filter = function(c) return is_client_in_tag(c, tag) end,
    buttons = tasks.key_bindings,
    layout = {
      spacing = dpi(8),
      layout = get_fixed_layout(panel_position)
    },
		widget_template = {
			{
				id = "client_icon",
				widget = awful.widget.clienticon,
			},
			layout = wibox.layout.stack,
			create_callback = function(self, c, _, _)
        local client_icon = self:get_children_by_id("client_icon")[1]
				client_icon.client = c
        client_icon.opacity = c.minimized and 0.4 or 1
			end,
      update_callback = function(self, c, _, _)
        local client_icon = self:get_children_by_id("client_icon")[1]
        client_icon.opacity = c.minimized and 0.4 or 1
			end,
		}
	})
end

local function create_left_layout(screen_index, panel)
  for tag_index,tag in ipairs(panel.tags.list) do
    awful.tag.add(
      tag.name,
      {
        layout = tag.layout,
        screen = screen_index,
        selected = panel.tags.selected_index == tag_index
      }
    )
  end

  local screen = get_screen(screen_index)

  local tag_list = awful.widget.taglist {
    screen = screen,
    filter = awful.widget.taglist.filter.all,
    buttons = panel.tags.key_bindings,
    layout = get_fixed_layout(panel.position),
    widget_template = {
      {
        {
          {
            {
              forced_width = is_horizontal_position(panel.position) and panel.thickness - dpi(6) or 0,
              forced_height = is_horizontal_position(panel.position) and 0 or panel.thickness - dpi(6),
              widget = wibox.container.constraint

            },
            {
              {
                id = "tasklist",
                layout = get_fixed_layout(panel.position),
              },
              widget = wibox.container.place
            },
            layout = wibox.layout.stack,
          },
          top = dpi(is_horizontal_position(panel.position) and 2 or 8),
          right = dpi(is_horizontal_position(panel.position) and 8 or 2),
          left = dpi(is_horizontal_position(panel.position) and 8 or 2),
          bottom = dpi(is_horizontal_position(panel.position) and 2 or 8),
          widget = wibox.container.margin
        },
        id = "background_role",
        widget = wibox.container.background,
      },
      shape = function(cr, width, height)
        gears.shape.rounded_rect(cr, width, height, dpi(4))
      end,
      shape_border_width = dpi(1),
      shape_border_color = beautiful.multi_widget_border_color,
      widget = wibox.container.background,
      create_callback = function(self, _, index, _)
        local tag = screen.tags[index]
        self:get_children_by_id("tasklist")[1]:add(create_tasklist(screen_index, panel.position, tag, panel.tasks))
      end,
    }
  }

  local taglist_margin_container = wibox.container.margin(tag_list)
  if is_horizontal_position(panel.position) then
    taglist_margin_container.left = dpi(4)
    taglist_margin_container.top = dpi(2)
    taglist_margin_container.bottom = dpi(2)
  else
    taglist_margin_container.top = dpi(4)
    taglist_margin_container.left = dpi(2)
    taglist_margin_container.right = dpi(2)
  end

  local launcher_margin_container = wibox.container.margin(panel.launcher.icon)
  launcher_margin_container.margins = dpi(2)

  local left_layout_widgets = create_fixed_layout(panel.position, {launcher_margin_container, taglist_margin_container})

  return left_layout_widgets
end

local function create_right_layout(screen_index, panel)
  local right_layout = create_fixed_layout(panel.position)
  right_layout.spacing = dpi(8)

  if screen_index == 1 then
    local tray = wibox.widget.systray()
    tray:set_horizontal(is_horizontal_position(panel.position))
    local tray_margin_container = wibox.container.margin(tray)
    tray_margin_container.margins = dpi(2)
    right_layout:add(tray_margin_container)
  end

  for _,widget_or_widget_group in ipairs(panel.widgets) do
    local is_widget_group = #widget_or_widget_group ~= 0
    local widgets = is_widget_group and widget_or_widget_group or { widget_or_widget_group }
    local containers = {}

    for i,widget in ipairs(widgets) do
      if widget.icon or widget.value then
        if widget.icon then
          local widget_icon_margin_container = wibox.container.margin(widget.icon)
          widget_icon_margin_container.margins = dpi(1)
          table.insert(containers, widget_icon_margin_container)
        end
        if widget.value then
          local widget_value_rotate_container = wibox.container.rotate(widget.value, get_direction_by_position(panel.position))
          table.insert(containers, widget_value_rotate_container)
        end
      end
    end

    local top_level_container

    if #containers == 1 then
      top_level_container = containers[1]
    else
      local widget_fixed_container = create_fixed_layout(panel.position, containers)

      local widgets_margin_container = wibox.container.margin(widget_fixed_container)
      widgets_margin_container.margins = dpi(2)

      local widget_background_container = wibox.container.background(
        widgets_margin_container,
        nil,
        function(cr, width, height)
          gears.shape.rounded_rect(cr, width, height, dpi(4))
        end
      )
      widget_background_container.shape_border_width = dpi(1)
      widget_background_container.shape_border_color = beautiful.multi_widget_border_color

      top_level_container = wibox.container.margin(widget_background_container)
      top_level_container.margins = dpi(2)
    end

    right_layout:add(top_level_container)

    for _,widget in ipairs(widgets) do
      if widget.on_container_created ~= nil then
        widget.on_container_created(top_level_container, panel.position)
      end
    end
  end

  return right_layout
end

local function create_main_layout(screen_index, panel)
  local main_layout = create_aligned_layout(panel.position)
  main_layout.first = create_left_layout(screen_index, panel)
  main_layout.third = create_right_layout(screen_index, panel)

  return main_layout
end

local function apply_panels(screen_index, panels)
  for _,panel in ipairs(panels) do
    local wibar = awful.wibar({
      screen = screen_index,
      position = panel.position,
      height = dpi(panel.thickness, screen_index),
      widget = create_main_layout(screen_index, panel),
      opacity = panel.opacity
    })
    wibar:struts {
      top = panel.position == "top" and wibar.height or 0,
      right = panel.position == "right" and wibar.width or 0,
      bottom = panel.position == "bottom" and wibar.height or 0,
      left = panel.position == "left" and wibar.width or 0
    }
  end
end

local function apply_screens()
  for screen_index,s in ipairs(_screens) do
    if screen_index <= screen.count() then
      apply_wallpaper(screen_index, s.wallpaper)
      apply_panels(screen_index, s.panels)
    end
  end
end

local function apply_screen(screen_index)
  if screen_index <= #_screens and screen_index <= screen.count() then
    s = _screens[screen_index]
    apply_wallpaper(screen_index, s.wallpaper)
    apply_panels(screen_index, s.panels)
  end
end

local screens_manager = {}

screens_manager.get_screen_count = get_screen_count
screens_manager.set_screens = set_screens
screens_manager.add_screen = add_screen
screens_manager.apply_screens = apply_screens
screens_manager.apply_screen = apply_screen

return screens_manager
