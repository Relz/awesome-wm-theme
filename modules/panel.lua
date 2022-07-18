local wibox = require("wibox")
require("modules/tags")
require("modules/tasks")

Panel_prototype = function()
  local this = {}

  this.__public_static = {
    -- Public Static Variables
    -- Public Static Funcs
  }

  this.__private_static = {
    -- Private Static Variables
    -- Private Static Funcs
  }

  this.__public = {
    -- Public Variables
    position = "top",
    thickness = 24,
    opacity = 0.9,
    tags = Tags(),
    tasks = Tasks(),
    widgets = {},
    launcher = wibox.widget.base
    -- Public Funcs
  }

  this.__private = {
    -- Private Variables
    -- Private Funcs
  }

  this.__construct = function()
    -- Constructor
  end

  return this
end

Panel = createClass(Panel_prototype)
