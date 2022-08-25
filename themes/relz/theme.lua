local gears = require("gears")
local beautiful = require("beautiful")
local dpi = beautiful.xresources.apply_dpi

local theme = {}

theme.root_path = gears.filesystem.get_configuration_dir() .. "themes/relz/"
theme.path = theme.root_path .. "theme.lua"
theme.icons_path = theme.root_path .. "icons/"
theme.mode_file_path = theme.root_path .. "mode"

theme.mode = read_file_content(theme.mode_file_path)

theme.font_family = "Droid Sans "
theme.font_family_mono = theme.font_family .. "Mono "

theme.font = theme.font_family_mono .. "Regular 10"

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
theme.checkbox_border_width = dpi(1)
theme.checkbox_border_color = theme.text_color

theme.checkbox_check_bg = theme.background_color
theme.checkbox_check_border_width = dpi(1)
theme.checkbox_check_border_color = theme.text_color
theme.checkbox_color = theme.text_color

-- | Systray | --

theme.bg_systray = theme.background_color
theme.systray_icon_spacing = dpi(8)

-- | Tooltip | --

theme.tooltip_bg = theme.background_color
theme.tooltip_fg = theme.text_color
theme.tooltip_shape = gears.shape.rounded_rect
theme.tooltip_border_width = dpi(1)
theme.tooltip_border_color = theme.text_color

-- | Borders | --

theme.border_width = 0
theme.border_normal = theme.background_color .. "ee"
theme.border_focus = theme.background_color .. "ee"
theme.border_marked = theme.background_color .. "ee"

-- | Hotkeys popup | --

theme.hotkeys_bg = theme.background_color .. "bb"
theme.hotkeys_font = theme.font_family_mono .. "Bold 11"
theme.hotkeys_description_font = theme.font_family_mono .. "Regular 10"
theme.hotkeys_group_margin = dpi(32)
theme.hotkeys_shape = function(cr, width, height)
  gears.shape.rounded_rect(cr, width, height, dpi(8))
end

-- | Notifications | --

theme.notification_max_width = dpi(640)
theme.notification_max_height = dpi(160)
theme.notification_font = theme.font_family .. "Regular 11"
theme.notification_bg = theme.background_color
theme.notification_fg = theme.text_color
theme.notification_border_width = dpi(1)
theme.notification_border_color = theme.background_color
theme.notification_opacity = 0.8
theme.notification_icon_size = dpi(48)
theme.notification_shape = function(cr, width, height)
  gears.shape.rounded_rect(cr, width, height, 3)
end

-- | Menu | --

theme.menu_height = dpi(24)
theme.menu_width = dpi(180)
theme.menu_bg_normal = theme.background_color .. "66"
theme.menu_bg_focus = theme.text_color .. "bb"

-- | Taglist | --

theme.taglist_spacing = 4

theme.taglist_fg_empty = theme.text_color
theme.taglist_fg_focus = theme.text_color
theme.taglist_fg_occupied = theme.text_color
theme.taglist_fg_urgent = theme.background_color

theme.taglist_bg_empty = theme.text_color .. "11"
theme.taglist_bg_focus = theme.text_color .. "44"
theme.taglist_bg_occupied = theme.text_color .. "11"
theme.taglist_bg_urgent = theme.danger_background .. "66"

theme.taglist_shape = function(cr, width, height)
  gears.shape.rounded_rect(cr, width, height, dpi(4))
end

-- | Tasklist | --

theme.tasklist_align = "center"
theme.tasklist_font = theme.font_family_mono .. "Regular 9"
theme.tasklist_font_focus = theme.font_family_mono .. "Bold 9"
theme.tasklist_disable_task_name = true
theme.tasklist_plain_task_name = true
theme.tasklist_bg_normal = theme.background_color
theme.tasklist_bg_focus = theme.background_color
theme.tasklist_bg_urgent = theme.background_color
theme.tasklist_fg_focus = theme.text_color
theme.tasklist_fg_urgent = theme.text_color
theme.tasklist_fg_normal = theme.text_color

-- | Widget | --

theme.multi_widget_border_color = theme.mode == "dark" and "#34455c" or "#bbd2d8"

-- | Clock / Calendar | --

theme.widget_clock_icon    = gears.color.recolor_image(theme.icons_path .. "/widgets/time.svg", theme.text_color)
theme.widget_calendar_icon = gears.color.recolor_image(theme.icons_path .. "/widgets/calendar.svg", theme.text_color)

-- | Menu | --

theme.widget_menu_icon = gears.color.recolor_image(theme.icons_path .. "/widgets/menu.svg", theme.text_color)

-- | Launch | --

theme.widget_launch_icon = gears.color.recolor_image(theme.icons_path .. "/widgets/launch.svg", theme.text_color)

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
