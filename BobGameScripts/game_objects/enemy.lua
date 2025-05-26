--#build
--#priority 410

---@class enemy : entity
---@field off_screen boolean
---@field ai_enabled boolean
Enemy = Entity.new()
Enemy.__index = Enemy

---@return enemy
function Enemy.new()
    local self = setmetatable(Entity.new(), Enemy)--[[@as enemy]]
    self.off_screen = true
    self.ai_enabled = true
    return self
end

function Enemy:should_take_damage(attacker)
    return not self.off_screen
end

function Enemy:update()
    Entity.update(self)

    if self.off_screen and self.x > 0 and self.x < self.game.screen.width then
        self.off_screen = false
    end

    if not self.off_screen then
        if self.x < 0 then
            self.x = 0
            self.vel_x = self.vel_x * -0.5
        elseif self.x > self.game.screen.width then
            self.x = self.game.screen.width
            self.vel_x = self.vel_x * -0.5
        end
    end
end