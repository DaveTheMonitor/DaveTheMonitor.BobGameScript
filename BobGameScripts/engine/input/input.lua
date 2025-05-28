--#build
--#priority 120

---@enum input_type
InputType = {
    move_left = 1,
    move_right = 2,
    move_forward = 3,
    move_backward = 4,
    jump = 5,
    crouch = 6,
    input_1 = 7,
    input_2 = 8,
    input_3 = 9
}

---@class input_bindings
---@field private keys { [input_type]: keys }
---@field private buttons { [input_type]: buttons }
InputBindings = {}
InputBindings.__index = InputBindings

---@return input_bindings
function InputBindings.new()
    local self = setmetatable({}, InputBindings)--[[@as input_bindings]]
    self.keys = {
        [InputType.move_left] = Keys.a,
        [InputType.move_right] = Keys.d,
        [InputType.move_forward] = Keys.w,
        [InputType.move_backward] = Keys.s,
        [InputType.jump] = Keys.space,
        [InputType.crouch] = Keys.left_control,
        [InputType.input_1] = Keys.j,
        [InputType.input_2] = Keys.k,
        [InputType.input_3] = Keys.l,
    }
    self.buttons = {
        [InputType.move_left] = Buttons.dpad_left,
        [InputType.move_right] = Buttons.dpad_right,
        [InputType.move_forward] = Buttons.dpad_up,
        [InputType.move_backward] = Buttons.dpad_down,
        [InputType.jump] = Buttons.a,
        [InputType.crouch] = Buttons.left_stick,
        [InputType.input_1] = Buttons.x,
        [InputType.input_2] = Buttons.b,
        [InputType.input_3] = Buttons.y,
    }
    return self
end

---@param input input_type
---@return keys
function InputBindings:get_key(input)
    return self.keys[input]
end

---@param input input_type
---@return buttons
function InputBindings:get_button(input)
    return self.buttons[input]
end

---@param input input_type
---@param key keys
function InputBindings:set_key(input, key)
    self.keys[input] = key
end

---@param input input_type
---@param button buttons
function InputBindings:set_button(input, button)
    self.buttons[input] = button
end

---@class (exact) input_manager
---@field private pressed_inputs { [input_type]: number }
---@field private pending_up_inputs { [input_type]: number }
---@field private hooked_events boolean
---@field public gamepad boolean
---@field private prev_gamepad_x number
---@field private prev_gamepad_y number
---@field public on_key_down fun(key: keys)
---@field public on_button_down fun(button: buttons)
---@field public bindings input_bindings
---@field public __index table
---@field public new function
InputManager = {}
InputManager.__index = InputManager

---@return input_manager
function InputManager.new()
    local self = setmetatable({}, InputManager)--[[@as input_manager]]
    self.pressed_inputs = {}
    self.pending_up_inputs = {}
    self.hooked_events = false
    self.gamepad = false
    self.prev_gamepad_x = 0
    self.prev_gamepad_y = 0
    for _, value in pairs(InputType) do
        self.pressed_inputs[value] = -1
    end
    self.bindings = InputBindings.new()

    return self
end

function InputManager:hook_events()
    local mgr = self
    hook_event(ModEvent.key_up, function(key)
        ---@diagnostic disable-next-line: invisible
        mgr:key_up(key)
    end)
    hook_event(ModEvent.key_down, function(key)
        ---@diagnostic disable-next-line: invisible
        mgr:key_down(key)
    end)
    hook_event(ModEvent.button_up, function(button)
        ---@diagnostic disable-next-line: invisible
        mgr:button_up(button)
    end)
    hook_event(ModEvent.button_down, function(button)
        ---@diagnostic disable-next-line: invisible
        mgr:button_down(button)
    end)
    self.hooked_events = true
end

function InputManager:unhook_events()
    unhook_all()
    self.hooked_events = false
end

---@private
---@param key keys
function InputManager:key_up(key)
    local input = self:get_input_from_key(key)
    if input ~= nil then
        -- stupid fix for eating inputs when lagging, ensure each
        -- input lasts at least 1 frame
        if self.pressed_inputs[input] == 0 then
            table.insert(self.pending_up_inputs, input)
        else
            self.pressed_inputs[input] = -1
        end
    end
end

---@private
---@param key keys
function InputManager:key_down(key)
    if self.on_key_down ~= nil then
        self.on_key_down(key)
    end

    local input = self:get_input_from_key(key)
    self.gamepad = false
    if input ~= nil then
        if self.pressed_inputs[input] < 0 then
            self.pressed_inputs[input] = 0
        end
    end
end

---@private
---@param button buttons
function InputManager:button_up(button)
    local input = self:get_input_from_button(button)
    if input ~= nil then
        -- stupid fix for eating inputs when lagging, ensure each
        -- input lasts at least 1 frame
        if self.pressed_inputs[input] == 0 then
            table.insert(self.pending_up_inputs, input)
        else
            self.pressed_inputs[input] = -1
        end
    end
end

---@private
---@param button buttons
function InputManager:button_down(button)
    if self.on_button_down ~= nil then
        self.on_button_down(button)
    end

    local input = self:get_input_from_button(button)
    self.gamepad = true
    if input ~= nil then
        if self.pressed_inputs[input] == -1 then
            self.pressed_inputs[input] = 0
        end
    end
end

---@private
---@param key keys
---@return input_type?
function InputManager:get_input_from_key(key)
    local bindings = self.bindings
    for _, value in pairs(InputType) do
        if key == bindings:get_key(value) then
            return value
        end
    end
end

---@private
---@param button buttons
---@return input_type?
function InputManager:get_input_from_button(button)
    local bindings = self.bindings
    for _, value in pairs(InputType) do
        if button == bindings:get_button(value) then
            return value
        end
    end
end

---@param input input_type
---@return boolean
function InputManager:is_input_held(input)
    local r = self.pressed_inputs[input]
    return r >= 0
end

---@param input input_type
---@return boolean
function InputManager:is_input_pressed(input)
    local r = self.pressed_inputs[input]
    return r == 0
end

---@param x number
---@param y number
---@param z number
function InputManager:pump(x, y, z)
    x = math.floor(x) + 0.5
    y = math.floor(y) + 0.05
    z = math.floor(z) + 0.5

    if is_mod_input_enabled then
        self:pump_mod()
    else
        self:pump_vanilla(x, y, z)
    end

    teleport(x, y, z)
    set_view_dir(0, 0, -1)
end

---@param x number
---@param y number
---@param z number
function InputManager:pump_vanilla(x, y, z)
    local deadzone = 0.5
    -- We base input on the player's view direction
    local px, py, pz = get_pos()
    local vx, vy, vz = get_view_dir()
    vx, vz = normalize(vx, vz)
    local input_x, input_y
    if length(px - x, pz - z) ~= 0 and (math.abs(px - x) > 0.0005 or math.abs(pz - z) > 0.0005) then
        px, pz = normalize(px - x, pz - z)
        input_x, input_y = normalize(dot(px, pz, -vz, vx), dot(px, pz, vx, vz))
    else
        px, pz = 0, 0
        input_x, input_y = 0, 0
    end
    if math.abs(input_y) > math.abs(input_x) then
        self:update_input(InputType.move_backward, input_y < -deadzone)
        self:update_input(InputType.move_forward, input_y > deadzone)
        self:update_input(InputType.move_left, false)
        self:update_input(InputType.move_right, false)
    else
        self:update_input(InputType.move_left, input_x < -deadzone)
        self:update_input(InputType.move_right, input_x > deadzone)
        self:update_input(InputType.move_backward, false)
        self:update_input(InputType.move_forward, false)
    end

    -- Up/down doesn't use the same deadzone as directional movement
    -- because of vertical fly acceleration
    self:update_input(InputType.crouch, py < y - 0.0001)
    self:update_input(InputType.jump, py > y - 0.00001)

    if get_history("bobgame\\input_1") > 0 then
        self.pressed_inputs[InputType.input_1] = 0
        set_history("bobgame\\input_1", 0)
    else
        self.pressed_inputs[InputType.input_1] = -1;
    end

    if get_history("bobgame\\input_2") > 0 then
        self.pressed_inputs[InputType.input_2] = 0
        set_history("bobgame\\input_2", 0)
    else
        self.pressed_inputs[InputType.input_2] = -1;
    end

    if get_history("bobgame\\input_3") > 0 then
        self.pressed_inputs[InputType.input_3] = 0
        set_history("bobgame\\input_3", 0)
    else
        self.pressed_inputs[InputType.input_3] = -1;
    end
end

function InputManager:pump_mod()
    if not self.hooked_events then
        self:hook_events()
    end

    local x, y = get_gamepad()
    if x ~= self.prev_gamepad_x or y ~= self.prev_gamepad_y then
        self.gamepad = true
        local deadzone = get_history("bobgame\\gamepad_deadzone")
        if deadzone ~= nil then
            deadzone = deadzone / 1000
        else
            deadzone = 0.5
        end
        if math.abs(y) > math.abs(x) then
            self:update_input(InputType.move_backward, y < -deadzone)
            self:update_input(InputType.move_forward, y > deadzone)
            self:update_input(InputType.move_left, false)
            self:update_input(InputType.move_right, false)
        else
            self:update_input(InputType.move_left, x < -deadzone)
            self:update_input(InputType.move_right, x > deadzone)
            self:update_input(InputType.move_backward, false)
            self:update_input(InputType.move_forward, false)
        end
        self.prev_gamepad_x = x
        self.prev_gamepad_y = y
    end

    local i = 1
    while i <= #self.pending_up_inputs do
        self.pressed_inputs[self.pending_up_inputs[1]] = -1
        table.remove(self.pending_up_inputs, i)
    end

    pump_mod_events()
end

function InputManager:advance()
    for index, value in ipairs(self.pressed_inputs) do
        if value >= 0 then
            self.pressed_inputs[index] = value + Time.delta_time
        end
    end
end

---@private
---@param input input_type
---@param held boolean
function InputManager:update_input(input, held)
    if held then
        if self.pressed_inputs[input] == -1 then
            self.pressed_inputs[input] = 0
        else
            self.pressed_inputs[input] = self.pressed_inputs[input]
        end
    else
        self.pressed_inputs[input] = -1
    end
end