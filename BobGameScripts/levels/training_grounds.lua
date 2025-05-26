--#build
--#priority 711

---@class training_grounds : level
---@field private time_until_cloud number
TrainingGrounds = Level.new()
TrainingGrounds.__index = TrainingGrounds

function TrainingGrounds.new()
    local self = setmetatable(Level.new(), TrainingGrounds)--[[@as training_grounds]]
    return self
end

function TrainingGrounds:initialize()
    Level.initialize(self)

    self.time_until_cloud = 0
    self.wave = Wave.new(self.game, 1, -1, 0, 0, 1, 1)

    self.bg_sprite = sprite_manager:load("bg_sunny")
    self.mg_sprite = sprite_manager:load("mg_hills")
    self.fg_sprite = sprite_manager:load("fg_hills")
    self.ground_level = 23
    self.gravity = self.gravity * 1

    local clouds = math.random(7, 9)
    for i = 1, clouds do
        self:spawn_cloud(false)
    end
end

function TrainingGrounds:post_initialize()
    local enemy = Goblin.new(self.game.screen.width / 2, self.ground_level, 1, 1)
    self.game:add_object(enemy)
    -- math.huge causes the health bar to appear empty
    enemy.max_health = 100000000
    enemy.health = enemy.max_health
    enemy.ai_enabled = false
end

function TrainingGrounds:update()
    self.time_until_cloud = self.time_until_cloud - Time.delta_time
    if self.time_until_cloud <= 0 then
        self:spawn_cloud(true)
        self.time_until_cloud = 4 + (math.random() * 2)
    end

    if self.game.input:is_input_pressed(InputType.input_2) then
        self.game:return_to_menu()
    end

    local enemy = self.game:get_object_with_tag("enemy")
    if enemy ~= nil then
        ---@cast enemy enemy
        enemy.health = enemy.max_health
    end
end

---@private
---@param off_screen boolean
function TrainingGrounds:spawn_cloud(off_screen)
    local x = -20
    if not off_screen then
        x = math.random(-20, self.game.screen.width)
    end
    local y = math.random(math.ceil(self.game.screen.height * 0.6), self.game.screen.height - 20)
    self.game.particles:add(Cloud, x, y, 0, 0)
end

function TrainingGrounds:draw()
    Level.draw(self)

    local input_name
    if is_mod_input_enabled then
        local key
        local enum
        if self.game.input.gamepad then
            key = self.game.input.bindings:get_button(InputType.input_2)
            enum = Buttons
        else
            key = self.game.input.bindings:get_key(InputType.input_2)
            enum = Keys
        end

        for k, value in pairs(enum) do
            if value == key then
                input_name = k
                input_name = input_name:gsub("_", " ")
                break
            end
        end
    else
        input_name = "Script B"
    end

    self.game.screen:draw_text(self.game.font, "Press '" .. input_name .. "' to exit", 5, self.game.screen.height - 22, Layers.ui, block.colorwhite)
end