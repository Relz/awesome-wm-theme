local gears   = require("gears")

mode = "light" -- "dark" | "light"

theme = {}
theme.mode = mode
theme.icons = require("awful").util.getdir("config") .. "/themes/relz/icons/"
theme.panel = "png:" .. theme.icons .. "/panel/panel_" .. mode .. ".png" -- size does not make anything
theme.font = "Droid Sans Mono Regular 10"

theme.text_color = mode == "dark" and "#f4feff" or "#1e293d"
theme.background_color = mode == "dark" and "#1e293d" or "#f4feff"

theme.fg_normal = theme.text_color
theme.fg_focus = theme.background_color
theme.fg_urgent = theme.text_color

theme.bg_normal = theme.background_color
theme.bg_focus = theme.text_color
theme.bg_urgent = theme.background_color

theme.bg_systray = theme.background_color

theme.systray_icon_spacing = 8

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

theme.notification_font = "Noto Sans Regular 10"
theme.notification_bg = theme.background_color
theme.notification_border_width = 0
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

-- | Memory | --

theme.widget_memory = theme.icons .. "/panel/widgets/memory/memory_0_" .. mode .. ".png"

-- | Network | --

theme.widget_network_default = theme.icons .. "/panel/widgets/wifi/wifi_off_" .. mode .. ".png"

-- | Battery | --

theme.widget_battery_default = theme.icons .. "/panel/widgets/battery/battery_100_" .. mode .. ".png"

-- | Network | --

theme.widget_volume_default = theme.icons .. "/panel/widgets/volume/volume_muted_" .. mode .. ".png"

-- | Clock / Calendar | --

theme.widget_clock = theme.icons .. "/panel/widgets/time_" .. mode .. ".png"
theme.widget_calendar = theme.icons .. "/panel/widgets/calendar_" .. mode .. ".png"

-- | Power off | --

theme.widget_power_off = theme.icons .. "/panel/widgets/power_off_" .. mode .. ".png"

-- | Client's titlebar | --

theme.titlebar_close_button_focus       = theme.icons .. "/titlebar/close_" .. mode .. ".png"
theme.titlebar_close_button_focus_hover = theme.icons .. "/titlebar/close_hover_" .. mode .. ".png"

theme.titlebar_maximized_button_focus_active       = theme.icons .. "/titlebar/maximize_" .. mode .. ".png"
theme.titlebar_maximized_button_focus_active_hover = theme.icons .. "/titlebar/maximize_hover_" .. mode .. ".png"

theme.titlebar_maximized_button_focus_inactive       = theme.icons .. "/titlebar/maximize_" .. mode .. ".png"
theme.titlebar_maximized_button_focus_inactive_hover = theme.icons .. "/titlebar/maximize_hover_" .. mode .. ".png"

theme.titlebar_minimize_button_focus       = theme.icons .. "/titlebar/minimize_" .. mode .. ".png"
theme.titlebar_minimize_button_focus_hover = theme.icons .. "/titlebar/minimize_hover_" .. mode .. ".png"

theme.titlebar_fg = theme.text_color .. "88"
theme.titlebar_fg_focus = theme.text_color .. "ee"
theme.titlebar_bg = theme.background_color .. "cc"

return theme
