--#build
--#priority 710

---@class level
---@field public game bob_game
---@field public ground_level integer
---@field public bg_sprite sprite
---@field public mg_sprite sprite
---@field public fg_sprite sprite
---@field public gravity number
---@field public wave wave
Level = {}
Level.__index = Level

function Level.new()
    local self = setmetatable({}, Level)
    self.gravity = 450
    return self
end

function Level:initialize()
    self.wave = Wave.new(self.game, 1, 0, 0, 0, 0, 0)
end

function Level:post_initialize() end

function Level:draw()
    local screen = self.game.screen
    if self.bg_sprite ~= nil then
        screen:draw(self.bg_sprite, 0, 0, self.bg_sprite.width, self.bg_sprite.height, 0, 0, Layers.bg)
    end
    if self.mg_sprite ~= nil then
        screen:draw(self.mg_sprite, 0, 0, self.mg_sprite.width, self.mg_sprite.height, 0, 0, Layers.mg)
    end
    if self.fg_sprite ~= nil then
        screen:draw(self.fg_sprite, 0, 0, self.fg_sprite.width, self.fg_sprite.height, 0, 0, Layers.fg)
    end
end

function Level:update() end
function Level:wave_complete() end
function Level:start_wave() end