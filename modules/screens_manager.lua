local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")
local beautiful = require("beautiful")

local _screens = {}

local function set_screens(screens)
  _screens = {}
  for _,screen in ipairs(screens) do
    table.insert(_screens, screen)
  end
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

local function create_aligned_layout(panel_position)
  return is_horizontal_position(panel_position) and wibox.layout.align.horizontal() or wibox.layout.align.vertical()
end

local function create_fixed_layout(panel_position, widgets)
  if widgets == nil then
    widgets = {}
  end
  return is_horizontal_position(panel_position) and wibox.layout.fixed.horizontal(table.unpack(widgets)) or wibox.layout.fixed.vertical(table.unpack(widgets))
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

  local tag_list = awful.widget.taglist(
    screen_index,
    awful.widget.taglist.filter.all,
    panel.tags.key_bindings,
    {},
    nil,
    create_fixed_layout(panel.position)
  )

  local taglist_margin_container = wibox.container.margin(tag_list)
  taglist_margin_container.top = 3
  taglist_margin_container.right = 3
  taglist_margin_container.bottom = 3
  taglist_margin_container.left = 3

  return taglist_margin_container
end

local function create_middle_layout(screen_index, panel)
  local middle_layout = create_fixed_layout(panel.position)

  local tasklist = awful.widget.tasklist {
    screen = screen_index,
    filter = awful.widget.tasklist.filter.currenttags,
    buttons = tasklist_buttons,
    layout = {
      spacing = 8,
      layout  = wibox.layout.fixed.horizontal
    },
    base_widget = middle_layout
  }
  local tasklist_margin_container = wibox.container.margin(tasklist)
  if is_horizontal_position(panel.position) then
    tasklist_margin_container.left = 32
    tasklist_margin_container.top = 4
    tasklist_margin_container.bottom = 4
  else
    tasklist_margin_container.top = 32
    tasklist_margin_container.right = 4
  end

  return tasklist_margin_container
end

local function create_right_layout(screen_index, panel)
  local right_layout = create_fixed_layout(panel.position)
  right_layout.spacing = 8

  if panel.show_tray then
    local tray = wibox.widget.systray()
    tray:set_horizontal(is_horizontal_position(panel.position))
    local tray_margin_container = wibox.container.margin(tray)
    tray_margin_container.margins = 2
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
          widget_icon_margin_container.margins = 1
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
      widgets_margin_container.margins = 2

      local widget_background_container = wibox.container.background(
        widgets_margin_container,
        nil,
        function (cr, width, height)
          gears.shape.rounded_rect(cr, width, height, 4)
        end
      )
      widget_background_container.shape_border_width = 1
      widget_background_container.shape_border_color = beautiful.multi_widget_border_color

      top_level_container = wibox.container.margin(widget_background_container)
      top_level_container.margins = 2
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
  main_layout.second = create_middle_layout(screen_index, panel)
  main_layout.third = create_right_layout(screen_index, panel)

  return main_layout
end

local function apply_panels(screen_index, panels)
  for _,panel in ipairs(panels) do
    local wibar = awful.wibar({screen = screen_index})
    wibar.position = panel.position
    wibar.height = panel.thickness
    wibar.widget = create_main_layout(screen_index, panel)
    wibar.opacity = panel.opacity
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

local screens_manager = {}

screens_manager.set_screens = set_screens
screens_manager.apply_screens = apply_screens

return screens_manager
