local gears = require("gears")
local awful = require("awful")
local wibox = require("wibox")

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

local function create_fixed_layout(panel_position)
  return is_horizontal_position(panel_position) and wibox.layout.fixed.horizontal() or wibox.layout.fixed.vertical()
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
  taglist_margin_container.top = 2
  taglist_margin_container.right = 2
  taglist_margin_container.bottom = 2
  taglist_margin_container.left = 2

  return taglist_margin_container
end

local function create_middle_layout(screen_index, panel)
  local middle_layout = create_fixed_layout(panel.position)

  local tasklist = awful.widget.tasklist(
    screen_index,
    awful.widget.tasklist.filter.currenttags,
    panel.tasks.key_bindings,
    {},
    nil,
    middle_layout
  )
  local tasklist_margin_container = wibox.container.margin(tasklist)
  if is_horizontal_position(panel.position) then
    tasklist_margin_container.left = 16
    tasklist_margin_container.top = 4
    tasklist_margin_container.bottom = 4
  else
    tasklist_margin_container.top = 16
    tasklist_margin_container.right = 4
  end

  return tasklist_margin_container
end

local function get_widget_horizontal_margin(panel_position)
  return is_horizontal_position(panel_position) and 4 or 0
end

local function get_widget_vertical_margin(panel_position)
  return is_horizontal_position(panel_position) and 0 or 4
end

local function create_right_layout(screen_index, panel)
  local right_layout = create_fixed_layout(panel.position)

  if panel.show_tray then
    local tray = wibox.widget.systray()
    tray:set_horizontal(is_horizontal_position(panel.position))
    local tray_margin_container = wibox.container.margin(tray)
    tray_margin_container.margins = 2
    right_layout:add(tray_margin_container)
  end

  for _,widget in ipairs(panel.widgets) do
    if widget.icon or widget.value then
      if widget.icon then
        local widget_margin_container = wibox.container.margin(widget.icon)
        widget_margin_container.left = get_widget_horizontal_margin(panel.position)
        widget_margin_container.top = get_widget_vertical_margin(panel.position)
        right_layout:add(widget_margin_container)
      end
      if widget.value then
        local widget_rotate_container = wibox.container.rotate(widget.value, get_direction_by_position(panel.position))
        local widget_margin_container = wibox.container.margin(widget_rotate_container)
        widget_margin_container.top = get_widget_vertical_margin(panel.position)
        right_layout:add(widget_margin_container)
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
