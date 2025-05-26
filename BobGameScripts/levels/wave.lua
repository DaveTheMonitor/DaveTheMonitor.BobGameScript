--#build
--#priority 700

---@class wave
---@field private game bob_game
---@field public wave_number integer
---@field public spawn_time number
---@field public total_enemies integer
---@field public max_active_enemies integer
---@field public max_health_multiplier number
---@field public speed_multiplier number
Wave = {}
Wave.__index = Wave

---@param game bob_game
---@param wave_number integer
---@param spawn_time number
---@param total_enemies integer
---@param max_enemies integer
---@param health_multiplier number
---@param speed_multiplier number
---@return wave
function Wave.new(game, wave_number, spawn_time, total_enemies, max_enemies, health_multiplier, speed_multiplier)
    local self = setmetatable({}, Wave)--[[@as wave]]
    self.game = game
    self.wave_number = wave_number
    self.spawn_time = spawn_time
    self.total_enemies = total_enemies
    self.max_active_enemies = max_enemies
    self.max_health_multiplier = health_multiplier
    self.speed_multiplier = speed_multiplier
    return self
end

---@return boolean
function Wave:spawn_enemy()
    local x
    if math.random() < 0.5 then
        x = -30
    else
        x = self.game.screen.width + 30
    end

    self.game:add_object(Goblin.new(x, self.game.level.ground_level, self.max_health_multiplier, self.speed_multiplier))

    return true
end