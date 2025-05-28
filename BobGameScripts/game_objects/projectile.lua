--#build
--#priority 450

---@class projectile : game_object
---@field protected vel_x number
---@field protected vel_y number
---@field protected age number
---@field protected duration number
---@field protected can_be_deflected boolean
---@field protected target_tags string[]?
---@field protected hitbox rectangle
---@field protected game bob_game
---@field protected gravity_enabled boolean
---@field protected grounded boolean
---@field protected grounded_friction number
---@field protected pierce integer
---@field protected damage number
---@field protected stagger stagger_info
---@field private hits { [entity]: boolean }
Projectile = setmetatable({}, GameObject)
Projectile.__index = Projectile

---@return projectile
function Projectile.new()
    local self = setmetatable(GameObject.new(), Projectile)--[[@as projectile]]
    self.vel_x = 0
    self.vel_y = 0
    self.age = 0
    self.duration = -1
    self.can_be_deflected = false
    self.hitbox = Rectangle.new(0, 0, 0, 0)
    self.gravity_enabled = true
    self.grounded = false
    self.grounded_friction = 200
    self.damage = 0
    self.stagger = StaggerInfo.new(0, 0, 1)
    self.hits = {}
    return self
end

function Projectile:update()
    local dt = Time.delta_time

    self.age = self.age + dt
    if self.duration ~= -1 and self.age >= self.duration then
        self:destroy()
        return
    end

    if self.grounded then
        if self.vel_x < 0 then
            self.vel_x = math.min(self.vel_x + (self.grounded_friction * dt), 0)
        elseif self.vel_x > 0 then
            self.vel_x = math.max(self.vel_x - (self.grounded_friction * dt), 0)
        end
    end

    self.x = self.x + (self.vel_x * dt)

    if not self.grounded and self.gravity_enabled then
        self.vel_y = self.vel_y - (self.game.level * dt)
    end
    self.y = self.y + (self.vel_y * dt)

    if self.y < self.game.level.ground_level then
        self.y = self.game.level.ground_level
        if self.vel_y < 0 then
            self.vel_y = 0
        end
    end

    self.grounded = self.y == self.game.level.ground_level

    if self:should_damage() then
        local targets = self.game:get_all_entities(self.hitbox, self.target_tags)
        if targets ~= nil then
            table.sort(targets, function(l, r)
                return distance(l.x, l.y, self.x, self.y) < distance(r.x, r.y, self.x, self.y)
            end)

            for i, target in ipairs(targets) do
                if target ~= self and not self:has_hit(target) then
                    local stagger = self.stagger:copy()
                    if self.vel_x < 0 then
                        stagger.dir = -1
                    else
                        stagger.dir = 1
                    end

                    target:damage(self.damage, stagger)
                    self.hits[target] = true
                    self:on_hit(target)
                end
            end
        end
    end
end

---@param entity entity
---@return boolean
function Projectile:has_hit(entity)
    return self.hits[entity] == true
end

---@protected
---@return boolean
function Projectile:should_damage()
    return not self.grounded
end

---@protected
---@param entity entity
function Projectile:on_hit(entity)
    self:destroy()
end