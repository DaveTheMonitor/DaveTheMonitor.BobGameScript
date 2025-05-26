--#build
--#priority 790

---@class options
---@field public player_damage_flashes boolean
---@field public enemy_damage_flashes boolean
---@field public input_display boolean
---@field public target_framerate integer
---@field public bindings input_bindings
Options = {}
Options.__index = Options

---@return options
function Options.new()
    local self = setmetatable({}, Options)--[[@as options]]
    self.enemy_damage_flashes = self:history_or_default("bobgame\\enemy_damage_flashes", false)
    self.player_damage_flashes = self:history_or_default("bobgame\\player_damage_flashes", true)
    self.input_display = self:history_or_default("bobgame\\input_display", false)

    self.bindings = InputBindings.new()
    for name, value in pairs(InputType) do
        self.bindings:set_key(value, self:history_or_default("bobgame\\" .. name .. "_key", self.bindings:get_key(value)))
        self.bindings:set_button(value, self:history_or_default("bobgame\\" .. name .. "_button", self.bindings:get_button(value)))
    end

    return self;
end

---@private
---@param key string
---@param default integer
---@return integer
---@overload fun(self: options, key: string, default: boolean): boolean
function Options:history_or_default(key, default)
    local value = get_history(key)
    if value ~= 0 then
        if type(default) == "boolean" then
            return value == 2
        else
            return value
        end
    end

    return default
end

---@param name string
---@param value integer|boolean
function Options:set(name, value)
    self[name] = value
    if type(value) == "number" then
        set_history("bobgame\\" .. name, math.floor(value))
    elseif value == true then
        -- We use 2 and 1 for booleans so 0 can be
        -- default
        set_history("bobgame\\" .. name, 2)
    elseif value == false then
        set_history("bobgame\\" .. name, 1)
    end
end

---@param input input_type
---@param key keys
function Options:set_input_key(input, key)
    self.bindings:set_key(input, key)

    for name, value in pairs(InputType) do
        if value == input then
            set_history("bobgame\\" .. name .. "_key", key)
            break
        end
    end
end

---@param input input_type
---@param button buttons
function Options:set_input_button(input, button)
    self.bindings:set_button(input, button)

    for name, value in pairs(InputType) do
        if value == input then
            set_history("bobgame\\" .. name .. "_button", button)
            break
        end
    end
end