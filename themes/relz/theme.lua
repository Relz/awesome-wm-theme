local awful = require("awful")
local gears = require("gears")

local theme = {}

theme.root_path = gears.filesystem.get_configuration_dir() .. "themes/relz/"
theme.path = theme.root_path .. "theme.lua"
theme.icons_path = theme.root_path .. "icons/"
theme.mode_file_path = theme.root_path .. "mode"

theme.mode = 'light'

local mode_file = io.open(theme.mode_file_path, "r")
if mode_file ~= nil then
  theme.mode = mode_file:read("*all")
  mode_file:close()
end

theme.font = "Droid Sans Mono Regular 10"

theme.text_color = theme.mode == "dark" and "#f4feff" or "#1e293d"
theme.background_color = theme.mode == "dark" and "#1e293d" or "#f4feff"

theme.danger_background = "#db5853"
theme.danger_foreground = "#751d1a"

theme.fg_normal = theme.text_color
theme.fg_focus = theme.background_color
theme.fg_urgent = theme.text_color

theme.bg_normal = theme.background_color
theme.bg_focus = theme.text_color
theme.bg_urgent = theme.background_color

-- | Checkbox | --

theme.checkbox_shape = gears.shape.circle

theme.checkbox_bg = theme.background_color
theme.checkbox_border_width = 1
theme.checkbox_border_color = theme.text_color

theme.checkbox_check_bg = theme.background_color
theme.checkbox_check_border_width = 1
theme.checkbox_check_border_color = theme.text_color
theme.checkbox_color = theme.text_color

-- | Systray | --

theme.bg_systray = theme.background_color
theme.systray_icon_spacing = 8

-- | Tooltip | --

theme.tooltip_bg = theme.background_color
theme.tooltip_fg = theme.text_color
theme.tooltip_shape = gears.shape.rounded_rect
theme.tooltip_border_width = 1
theme.tooltip_border_color = theme.text_color

-- | Borders | --

theme.border_width = 0
theme.border_normal = theme.background_color .. "ee"
theme.border_focus = theme.background_color .. "ee"
theme.border_marked = theme.background_color .. "ee"

-- | Hotkeys popup | --

theme.hotkeys_bg = theme.background_color .. "bb"
theme.hotkeys_font = "Droid Sans Mono Bold 11"
theme.hotkeys_description_font = "Droid Sans Mono Regular 10"
theme.hotkeys_group_margin = 32
theme.hotkeys_shape = function(cr, width, height)
  gears.shape.rounded_rect(cr, width, height, 8)
end

-- | Notifications | --

theme.notification_max_width = 640
theme.notification_max_height = 160
theme.notification_font = "Noto Sans Regular 11"
theme.notification_bg = theme.background_color
theme.notification_fg = theme.text_color
theme.notification_border_width = 1
theme.notification_border_color = theme.background_color
theme.notification_opacity = 0.8
theme.notification_icon_size = 48
theme.notification_shape = function(cr, width, height)
  gears.shape.rounded_rect(cr, width, height, 3)
end

-- | Menu | --

theme.menu_height = 24
theme.menu_width = 180
theme.menu_bg_normal = theme.background_color .. "66"
theme.menu_bg_focus = theme.text_color .. "bb"

-- | Taglist | --

theme.taglist_spacing = 4
theme.taglist_font = "Noto Sans Mono Regular 11"

theme.taglist_fg_empty = "#1e293d"
theme.taglist_fg_focus = "#f4feff"
theme.taglist_fg_occupied = "#f4feff"
theme.taglist_fg_urgent = "#f4feff"

theme.taglist_bg_empty = "#eceff1"
theme.taglist_bg_focus = "#0d46a1"
theme.taglist_bg_occupied = "#1e87e5"
theme.taglist_bg_urgent = "#f44336"

theme.taglist_shape_border_width_empty = 1
theme.taglist_shape_border_color_empty = "#1e293d"
theme.taglist_shape = gears.shape.rounded_bar

-- | Tasklist | --

theme.tasklist_font = "Droid Sans Mono Regular 9"
theme.tasklist_font_focus = "Droid Sans Mono Bold 9"
theme.tasklist_disable_task_name = true
theme.tasklist_plain_task_name = true
theme.tasklist_bg_normal = theme.background_color
theme.tasklist_bg_focus = theme.background_color
theme.tasklist_bg_urgent = theme.background_color
theme.tasklist_fg_focus = theme.text_color
theme.tasklist_fg_urgent = theme.text_color
theme.tasklist_fg_normal = theme.text_color
theme.tasklist_floating = ""
theme.tasklist_sticky = ""
theme.tasklist_ontop = ""
theme.tasklist_maximized_horizontal = ""
theme.tasklist_maximized_vertical = ""

-- | Widget | --

theme.multi_widget_border_color = theme.mode == "dark" and "#34455c" or "#bbd2d8"

-- | Clock / Calendar | --

theme.widget_clock    = gears.color.recolor_image(theme.icons_path .. "/widgets/time.svg", theme.text_color)
theme.widget_calendar = gears.color.recolor_image(theme.icons_path .. "/widgets/calendar.svg", theme.text_color)

-- | Menu | --

theme.widget_menu = gears.color.recolor_image(theme.icons_path .. "/widgets/menu.svg", theme.text_color)

-- | Client's titlebar | --

theme.titlebar_close_button_focus       = gears.color.recolor_image(theme.icons_path .. "/titlebar/close.svg", theme.text_color)
theme.titlebar_close_button_focus_hover = gears.color.recolor_image(theme.icons_path .. "/titlebar/close_hover.svg", theme.text_color)

theme.titlebar_maximized_button_focus_active       = gears.color.recolor_image(theme.icons_path .. "/titlebar/maximize.svg", theme.text_color)
theme.titlebar_maximized_button_focus_active_hover = gears.color.recolor_image(theme.icons_path .. "/titlebar/maximize_hover.svg", theme.text_color)

theme.titlebar_maximized_button_focus_inactive       = gears.color.recolor_image(theme.icons_path .. "/titlebar/maximize.svg", theme.text_color)
theme.titlebar_maximized_button_focus_inactive_hover = gears.color.recolor_image(theme.icons_path .. "/titlebar/maximize_hover.svg", theme.text_color)

theme.titlebar_minimize_button_focus       = gears.color.recolor_image(theme.icons_path .. "/titlebar/minimize.svg", theme.text_color)
theme.titlebar_minimize_button_focus_hover = gears.color.recolor_image(theme.icons_path .. "/titlebar/minimize_hover.svg", theme.text_color)

theme.titlebar_fg = theme.text_color .. "88"
theme.titlebar_fg_focus = theme.text_color .. "ee"
theme.titlebar_bg = theme.background_color .. "cc"

return theme
