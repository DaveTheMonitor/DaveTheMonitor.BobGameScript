--#build
--#priority 801

---@class menu_option
---@field public text string
---@field public select_action fun(menu: menu)?
---@field public left_action fun(menu: menu)?
---@field public right_action fun(menu: menu)?
---@field public get_value (fun(menu: menu): any)?
---@field public disabled boolean?

---@class menu
---@field private game bob_game
---@field private option integer
---@field private sprite sprite
---@field private input_hold_timer number
---@field private border_sprite sprite
---@field private options menu_option[]
---@field private setting_input_key input_type?
---@field private setting_input_button input_type?
---@field private input_ignore_timer integer
Menu = {}
Menu.__index = Menu

---@return menu
function Menu.new()
    local self = setmetatable({}, Menu)
    return self
end

---@param game bob_game
function Menu:initialize(game)
    self.game = game
    self.sprite = self.game.sprite_manager:load("menu")
    self.border_sprite = self.game.sprite_manager:load("screen_border")
    self.input_ignore_timer = 0
    self:main_menu()
end

function Menu:update()
    if self.setting_input_key ~= nil or self.setting_input_button ~= nil then
        return
    elseif self.input_ignore_timer > 0 then
        self.input_ignore_timer = self.input_ignore_timer - 1
        return
    end

    local input = self.game.input

    if input:is_input_pressed(InputType.move_backward) then
        local max = 0
        for _, option in ipairs(self.options) do
            if not option.disabled then
                max = max + 1
            end
        end
        self.option = math.min(self.option + 1, max)
    end
    if input:is_input_pressed(InputType.move_forward) then
        self.option = math.max(self.option - 1, 1)
    end

    if input:is_input_pressed(InputType.input_1) or input:is_input_pressed(InputType.jump) then
        local option = self:get_option()
        if option.select_action ~= nil then
            option.select_action(self)
        end
    end

    if input:is_input_pressed(InputType.move_left) then
        local option = self:get_option()
        if option.left_action ~= nil then
            option.left_action(self)
        end
    elseif input:is_input_pressed(InputType.move_right) then
        local option = self:get_option()
        if option.right_action ~= nil then
            option.right_action(self)
        end
    end
end

function Menu:get_option()
    local i = 1
    for _, option in ipairs(self.options) do
        if option.disabled then
            goto continue
        end

        if self.option == i then
            return option
        end
        i = i + 1

        ::continue::
    end
end

---@private
function Menu:select_play()
    -- Advance here prevents the player from attacking on
    -- the first frame
    self.game.input:advance()
    self.game:initialize_level(Hills.new())
end

---@private
function Menu:select_training()
    -- Advance here prevents the player from attacking on
    -- the first frame
    self.game.input:advance()
    self.game:initialize_level(TrainingGrounds.new())
end

---@private
function Menu:select_options()
    self.option = 1
    self.options = {
        {
            text = "Damage Flashes",
            get_value = Menu.get_damage_flashes,
            left_action = Menu.damage_flashes_left,
            right_action = Menu.damage_flashes_right
        },
        {
            text = "Framerate",
            get_value = Menu.get_framerate,
            left_action = Menu.framerate_left,
            right_action = Menu.framerate_right
        },
        {
            text = "Screen Distance",
            get_value = Menu.get_screen_distance,
            left_action = Menu.screen_distance_left,
            right_action = Menu.screen_distance_right
        },
        {
            text = "Rendering",
            get_value = Menu.get_rendering,
            left_action = Menu.rendering_left,
            right_action = Menu.rendering_right,
            disabled = not is_mod_enabled
        },
        {
            text = "Input",
            get_value = Menu.get_input,
            left_action = Menu.input_left,
            right_action = Menu.input_right,
            disabled = not is_mod_enabled
        },
        {
            text = "Input Display",
            get_value = Menu.get_input_display,
            left_action = Menu.input_display_left,
            right_action = Menu.input_display_right
        },
        {
            text = "Back",
            select_action = Menu.main_menu
        }
    }
end

function Menu:select_controls()
    self.option = 1
    local get_input = self.get_key
    local start_setting_input = self.start_setting_input

    if is_mod_input_enabled then
        self.options = {
            {
                text = "Back",
                select_action = Menu.main_menu
            },
            {
                text = "Left",
                get_value = function(self) return get_input(self, InputType.move_left) end,
                select_action = function(self) start_setting_input(self, InputType.move_left) end
            },
            {
                text = "Right",
                get_value = function(self) return get_input(self, InputType.move_right) end,
                select_action = function(self) start_setting_input(self, InputType.move_right) end
            },
            {
                text = "Up",
                get_value = function(self) return get_input(self, InputType.move_forward) end,
                select_action = function(self) start_setting_input(self, InputType.move_forward) end
            },
            {
                text = "Down",
                get_value = function(self) return get_input(self, InputType.move_backward) end,
                select_action = function(self) start_setting_input(self, InputType.move_backward) end
            },
            {
                text = "Attack",
                get_value = function(self) return get_input(self, InputType.input_1) end,
                select_action = function(self) start_setting_input(self, InputType.input_1) end
            },
            {
                text = "Switch Weapon",
                get_value = function(self) return get_input(self, InputType.input_3) end,
                select_action = function(self) start_setting_input(self, InputType.input_3) end
            },
            {
                text = "Jump",
                get_value = function(self) return get_input(self, InputType.jump) end,
                select_action = function(self) start_setting_input(self, InputType.jump) end
            },
        }
    else
        self.options = {
            {
                text = "Back",
                select_action = Menu.main_menu
            },
            {
                text = "Left: Move Left",
                disabled = true
            },
            {
                text = "Right: Move Right",
                disabled = true
            },
            {
                text = "Up: Move Up",
                disabled = true
            },
            {
                text = "Down: Move Down",
                disabled = true
            },
            {
                text = "Attack: Script X",
                disabled = true
            },
            {
                text = "Switch Weapon: Script Y",
                disabled = true
            },
            {
                text = "Jump: Jump",
                disabled = true
            },
        }
    end
end

---@private
function Menu:select_exit()
    self.game.is_active = false
end

---@private
function Menu:get_damage_flashes()
    local options = self.game.options
    if options.enemy_damage_flashes and options.player_damage_flashes then
        return "All"
    elseif options.player_damage_flashes then
        return "Player"
    elseif options.enemy_damage_flashes then
        return "Enemies"
    else
        return "Off"
    end
end

---@private
function Menu:damage_flashes_left()
    local options = self.game.options
    if not options.enemy_damage_flashes and not options.player_damage_flashes then
        return
    elseif options.enemy_damage_flashes and options.player_damage_flashes then
        options:set("enemy_damage_flashes", false)
        options:set("player_damage_flashes", false)
    elseif options.player_damage_flashes then
        options:set("enemy_damage_flashes", true)
        options:set("player_damage_flashes", true)
    else
        options:set("enemy_damage_flashes", false)
        options:set("player_damage_flashes", true)
    end
end

---@private
function Menu:damage_flashes_right()
    local options = self.game.options
    if not options.enemy_damage_flashes and not options.player_damage_flashes then
        options:set("enemy_damage_flashes", true)
        options:set("player_damage_flashes", true)
    elseif options.enemy_damage_flashes and options.player_damage_flashes then
        options:set("enemy_damage_flashes", false)
        options:set("player_damage_flashes", true)
    elseif options.player_damage_flashes then
        options:set("enemy_damage_flashes", true)
        options:set("player_damage_flashes", false)
    end
end

---@private
function Menu:get_framerate()
    return math.floor((1000 / self.game.target_time) + 0.5)
end

---@private
function Menu:framerate_left()
    self:adjust_framerate(-1)
end

---@private
function Menu:framerate_right()
    self:adjust_framerate(1)
end

---@private
---@param amount integer
function Menu:adjust_framerate(amount)
    local framerate = self:get_framerate()
    framerate = framerate + amount
    if framerate > 60 then
        framerate = 60
    elseif framerate < 10 then
        framerate = 10
    end

    self.game.target_time = 1000 / framerate
    set_history("bobgame\\target_fps", framerate)
end

---@private
function Menu:get_rendering()
    if is_mod_swap_chain_enabled then
        return "Enhanced"
    else
        return "Vanilla"
    end
end

---@private
function Menu:rendering_left()
    if is_mod_swap_chain_enabled then
        self.game.target_time = 1000 / 30
        set_history("bobgame\\target_fps", 30)
        
        local screen = self.game.screen
        screen:reset()
        swap_chain_dispose()
        -- Set after disposing the swap chain
        is_mod_swap_chain_enabled = false

        set_history("bobgame\\disable_swap_chain", 1)
    end
end

---@private
function Menu:rendering_right()
    if not is_mod_swap_chain_enabled then
        is_mod_swap_chain_enabled = true
        self.game.target_time = 1000 / 60
        set_history("bobgame\\target_fps", 60)
        
        local screen = self.game.screen
        screen:reset()
        set_region(screen.x, screen.y, screen.z, screen.x + screen.width, screen.y + screen.height, screen.z, block.none, 100, 0)
        initialize_swap_chain(screen.x, screen.y, screen.z + 1, screen.width, screen.height)
        clear_history("bobgame\\disable_swap_chain")
    end
end

---@private
function Menu:get_input()
    if is_mod_input_enabled then
        return "Enhanced"
    else
        return "Vanilla"
    end
end

---@private
function Menu:input_left()
    if is_mod_input_enabled then
        self.game.input:unhook_events()
        is_mod_input_enabled = false
        set_history("bobgame\\disable_input", 1)
    end
end

---@private
function Menu:input_right()
    if not is_mod_input_enabled then
        is_mod_input_enabled = true
        -- Pump twice to reset events
        self.game.input:pump_mod()
        self.game.input:pump_mod()
        clear_history("bobgame\\disable_input")
    end
end

---@private
function Menu:get_input_display()
    if self.game.options.input_display then
        return "On"
    else
        return "Off"
    end
end

---@private
function Menu:input_display_left()
    if self.game.options.input_display then
        self.game.options:set("input_display", false)
    end
end

---@private
function Menu:input_display_right()
    if not self.game.options.input_display then
        self.game.options:set("input_display", true)
    end
end

---@private
function Menu:get_screen_distance()
    return self.game.screen_distance
end

---@private
function Menu:screen_distance_left()
    self.game.screen_distance = math.max(self.game.screen_distance - 1, 32)
    set_history("bobgame\\screen_distance", self.game.screen_distance)
    -- prevents forward/back input from registering with vanilla input
    -- after changing screen distance
    teleport(self.game.screen.x + (self.game.screen.width / 2), self.game.screen.y + (self.game.screen.height / 2) - 2, self.game.screen.z + self.game.screen_distance)
end

---@private
function Menu:screen_distance_right()
    self.game.screen_distance = math.min(self.game.screen_distance + 1, 256)
    set_history("bobgame\\screen_distance", self.game.screen_distance)
    -- prevents forward/back input from registering with vanilla input
    -- after changing screen distance
    teleport(self.game.screen.x + (self.game.screen.width / 2), self.game.screen.y + (self.game.screen.height / 2) - 2, self.game.screen.z + self.game.screen_distance)
end

---@param input input_type
function Menu:start_setting_input(input)
    self.finished_setting_input = false

    if self.game.input.gamepad then
        self.setting_input_button = input
        self.game.input.on_button_down = function(value)
            self:set_input(input, nil, value)
        end

        return
    end

    self.setting_input_key = input
    self.game.input.on_key_down = function(value)
        self:set_input(input, value, nil)
    end
end

---@private
---@param input input_type
---@param key keys?
---@param button buttons?
function Menu:set_input(input, key, button)
    local bindings = self.game.options.bindings
    ---@type keys|buttons
    local old_value

    self.finished_setting_input = true
    self.setting_input_key = nil
    self.setting_input_button = nil
    if button ~= nil then
        old_value = bindings:get_button(input)
        self.game.options:set_input_button(input, button)
    elseif key ~= nil then
        old_value = bindings:get_key(input)
        self.game.options:set_input_key(input, key)
    end
    self.game.input.on_key_down = nil
    self.game.input.on_button_down = nil
    -- We ignore input for one frame after setting the key
    -- so the "action" input is not immediately reset
    self.input_ignore_timer = 1

    for _, value in pairs(InputType) do
        if value == input then
            goto continue
        end

        if button ~= nil then
            if bindings:get_button(value) == button then
                bindings:set_button(value, old_value)
            end
        else
            if bindings:get_key(value) == key then
                bindings:set_key(value, old_value)
            end
        end
        ::continue::
    end
end

---@private
---@param input input_type
function Menu:get_key(input)
    if self.setting_input_key == input or self.setting_input_button == input then
        return "..."
    end

    local key
    local enum
    if self.game.input.gamepad then
        key = self.game.options.bindings:get_button(input)
        enum = Buttons
    else
        key = self.game.options.bindings:get_key(input)
        enum = Keys
    end
    
    for k, value in pairs(enum) do
        if value == key then
            return k:gsub("_", " ")
        end
    end

    return "?"
end

---@private
function Menu:main_menu()
    self.option = 1
    self.options = {
        {
            text = "Play",
            select_action = Menu.select_play
        },
        {
            text = "Training",
            select_action = Menu.select_training
        },
        {
            text = "Options",
            select_action = Menu.select_options
        },
        {
            text = "Controls",
            select_action = Menu.select_controls
        },
        {
            text = "Exit",
            select_action = Menu.select_exit
        },
    }
end

function Menu:draw()
    local screen = self.game.screen
    local font = self.game.font
    local cx = math.floor(self.game.screen.width * 0.5)
    screen:draw(self.sprite, 0, 0, self.sprite.width, self.sprite.height, 0, 0, Layers.ui)

    local y = screen.height - 20
    local mx, my = font:measure("Bob Game Demo")
    screen:draw_text(font, "Bob Game Demo", cx - math.floor(mx * 0.5), y, Layers.ui, block.colorwhite)

    y = y - 20
    local index = 1
    for _, option in ipairs(self.options) do
        local text = option.text

        local value = nil
        if option.get_value ~= nil then
            value = option.get_value(self)
            text = text .. ": "
        end

        if not option.disabled and self.option == index and option.left_action ~= nil then
            text = text .. "< "
        end

        if value ~= nil then
            text = text .. value
        end

        if not option.disabled and self.option == index and option.right_action ~= nil then
            text = text .. " >"
        end

        if option.disabled then
            self:draw_option(-1, font, text, cx, y, block.colorgray)
        else
            self:draw_option(index, font, text, cx, y)
        end

        if not option.disabled then
            index = index + 1
        end

        y = y - 12
    end
end

---@param index integer
---@param font font
---@param text string
---@param center_x integer
---@param y integer
---@param color integer?
function Menu:draw_option(index, font, text, center_x, y, color)
    local mx, my = font:measure(text)
    if self.option == index then
        -- why tf do the sides not line up when equal distance
        self.game.screen:draw_box(center_x - 75, y - 2, center_x + 73, y + 8, block.colordarkgray, Layers.ui)
    end

    if color == nil then
        color = block.colorwhite
    end
    self.game.screen:draw_text(font, text, center_x - math.ceil(mx * 0.5), y, Layers.ui, color)
end