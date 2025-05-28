--#build
--#priority 451

---@class hammer_wave : projectile
---@field private sprite sprite
---@field private stage integer
---@field private pierce integer
HammerWave = setmetatable({}, Projectile)
HammerWave.__index = HammerWave

---@param x number
---@param y number
---@param vel_x number
---@param pierce integer
---@param damage number
---@param duration number
---@return hammer_wave
function HammerWave.new(x, y, vel_x, pierce, damage, duration)
    local self = setmetatable(Projectile.new(), HammerWave)--[[@as hammer_wave]]
    self.vel_x = vel_x
    self.x = x
    self.y = y
    self.duration = duration
    self.gravity_enabled = false
    self.grounded_friction = 0
    self.pierce = pierce
    self.damage = damage
    self.stagger = StaggerInfo.new(80, 20, 1)
    self.stage = 1
    self.target_tags = { "enemy" }
    return self
end

function HammerWave:initialize()
    self.sprite = self.game.sprite_manager:load("hammer_wave")
end

function HammerWave:update()
    Projectile.update(self)
    
    self.hitbox.y = self.y
    if self.age < 0.1 or self.age > self.duration - 0.1 then
        self.hitbox.x = self.x - 3
        self.hitbox.w = 6
        self.hitbox.h = 5
        self.stage = 1
    else
        self.hitbox.x = self.x - 5
        self.hitbox.w = 10
        self.hitbox.h = 7
        self.stage = 2
    end
end

function HammerWave:draw()
    local x = math.floor(self.x + 0.5)
    local y = math.floor(self.y + 0.5)

    local flip = self.vel_x < 0

    local src_x = 0
    local src_y = 0
    local offset_x = 0
    if self.stage == 1 then
        src_x = 0
        src_y = 0
        if flip then
            offset_x = -7
        else
            offset_x = -8
        end
    elseif self.stage == 2 then
        src_x = 16
        src_y = 0
        offset_x = -8
    elseif self.stage then
        src_x = 0
        src_y = 16
        offset_x = -8
    end

    self.game.screen:draw(self.sprite, src_x, src_y, 16, 16, x + offset_x, y, Layers.player_projectiles, flip, false)
end

function HammerWave:should_damage()
    return true
end

---@param target entity
function HammerWave:on_hit(target)
    if self.pierce == 0 then
        self:destroy()
    end

    self.pierce = self.pierce - 1
    target:apply_damage_on_impact(20, "enemy", nil)
end