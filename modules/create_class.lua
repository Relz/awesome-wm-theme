createClass = function()
  local creator = {}

  creator.__private = {
    object_class = {},
  }

  creator.__oncall = function(class_creator)
    -- Get the class definition so we can make needed variables private, static, etc.
    local this = class_creator()
    -- Initialize class from class definition
    __init = function()
      -- Init Public Static
      local class = {}
      if (type(this.__public_static) == "table") then
        class = this.__public_static
      end

      -- Init Object
      local thisClass = this
      local __constructor = function(...)
        local object = {}
        local this = class_creator()

        -- Init Public
        if (type(this.__public) == "table") then
          object = this.__public
        end

        -- Init static values of the class
        this.__public_static = thisClass.__public_static
        this.__private_static = thisClass.__private_static

        -- Call Constructor
        if (type(this.__construct) == "function") then
          this.__construct(...)
        end

        object.type = "class"

        -- Returning constructed object
        return object
      end

      return {class = class, constructor = __constructor}
    end

    -- Creating class (returning constructor)
    local class_data = __init()
    local class = class_data.class
    local constructor = class_data.constructor

    -- Set class metatable (with setting constructor)
    local class_metatable = {
      __newindex = function(t, key, value)
        if type(t[key]) == "nil" or type(t[key]) == "function" then
          error("Attempt to redefine class")
        end
        rawset(t, key, value)
      end,
      __metatable = false,
      __call = function(t, ...)
        if type(t) == nil then
          error("Class object create failed!")
        end
        local obj = constructor(...)
        creator.__private.object_class[obj] = t
        local object_metatable = {
          __newindex = function(t, key, value)
            class = creator.__private.object_class[t]
            if type(class[key])~="nil" and type(class[key])~="function" then
              rawset(class, key, value)
              return
            end
            if type(t[key])~="nil" and type(t[key])~="function" then
              rawset(t, key, value)
              return
            end
            error("Attempt to redefine object")
          end,
          __index = t,
          __metatable = false,
        }
        setmetatable(obj, object_metatable)

        return obj
      end,
    }

    -- Setting class metatable to the class itself
    setmetatable(class, class_metatable)

    -- Returning resulting class
    return class
  end

  return creator.__oncall
end

createClass = createClass()
