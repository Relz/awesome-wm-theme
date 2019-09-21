local awful = require("awful")

Tag_prototype = function()
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
    name = "",
    layout = awful.layout.suit.floating
    -- Public Funcs
  }

  this.__private = {
    -- Private Variables
    -- Private Funcs
  }

  this.__construct = function(name, layout)
    -- Constructor
    this.__public.name = name
    this.__public.layout = layout
  end

  return this
end

Tag = createClass(Tag_prototype)
