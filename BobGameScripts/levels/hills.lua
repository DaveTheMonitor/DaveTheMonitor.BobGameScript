--#build
--#priority 711

---@class hills : level
---@field private time_until_cloud number
Hills = Level.new()
Hills.__index = Hills

function Hills.new()
    local self = setmetatable(Level.new(), Hills)--[[@as hills]]
    return self
end

function Hills:initialize()
    Level.initialize(self)

    self.time_until_cloud = 0
    self.wave = Wave.new(self.game, 1, 4, 5, 4, 1, 1)

    self.bg_sprite = sprite_manager:load("bg_sunny")
    self.mg_sprite = sprite_manager:load("mg_hills")
    self.fg_sprite = sprite_manager:load("fg_hills")
    self.ground_level = 23

    local clouds = math.random(7, 9)
    for i = 1, clouds do
        self:spawn_cloud(false)
    end
end

function Hills:update()
    self.time_until_cloud = self.time_until_cloud - Time.delta_time
    if self.time_until_cloud <= 0 then
        self:spawn_cloud(true)
        self.time_until_cloud = 4 + (math.random() * 2)
    end
end

---@private
---@param off_screen boolean
function Hills:spawn_cloud(off_screen)
    local x = -20
    if not off_screen then
        x = math.random(-20, self.game.screen.width)
    end
    local y = math.random(math.ceil(self.game.screen.height * 0.6), self.game.screen.height - 20)
    self.game.particles:add(Cloud, x, y, 0, 0)
end

function Hills:start_wave()
    local wave = self.wave
    local spawn_time = math.max(wave.spawn_time * 0.75, 0.6)
    local total_enemies = math.floor(wave.total_enemies * 1.5)
    local max_enemies = math.min(math.floor(wave.max_active_enemies * 1.25), 50)
    local health_multiplier = wave.max_health_multiplier + math.min(wave.max_health_multiplier * 0.20, 0.6)
    local speed_multiplier = wave.speed_multiplier + math.min(wave.speed_multiplier * 0.1, 0.25)
    self.wave = Wave.new(self.game, wave.wave_number + 1, spawn_time, total_enemies, max_enemies, health_multiplier, speed_multiplier)
end