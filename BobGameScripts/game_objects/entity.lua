--#build
--#priority 409

---@class stagger_info
---@field public x number
---@field public y number
---@field public dir integer
StaggerInfo = {}
StaggerInfo.__index = StaggerInfo

---@param x number
---@param y number
---@param dir integer
function StaggerInfo.new(x, y, dir)
    local self = setmetatable({}, StaggerInfo)
    self.x = x
    self.y = y
    self.dir = dir
    return self
end

---@return stagger_info
function StaggerInfo:copy()
    local copy = {
        x = self.x,
        y = self.y,
        dir = self.dir
    }
    return copy
end

---@class entity : game_object
---@field public health number
---@field public max_health number
---@field public vel_x number
---@field public vel_y number
---@field public dir integer
---@field public grounded boolean
---@field protected animation_controller animation_controller
---@field public animation animation_instance
---@field protected target_vel_x number
---@field protected acceleration number
---@field protected friction number
---@field protected sprite sprite
---@field public game bob_game
---@field protected can_move boolean
---@field private gravity_enabled boolean
---@field private stagger_x number
---@field private stagger_y number
---@field protected stagger_knockback_threshold_x number
---@field protected stagger_knockback_threshold_y number
---@field protected stagger_force_multiplier number
---@field protected stagger_recovery number
---@field private knockback_recovery_accumulator number
---@field protected knocked_back boolean
---@field public hitbox rectangle
---@field protected hitbox_offset_x integer
---@field protected hitbox_offset_y integer
---@field protected hitbox_size_x integer
---@field protected hitbox_size_y integer
---@field protected damage_on_impact number
---@field protected damage_on_impact_tags string[]?
---@field protected damage_on_impact_sources { [entity]: boolean }?
---@field protected time_since_damaged number
Entity = setmetatable({}, GameObject)
Entity.__index = Entity

---@return entity
function Entity.new()
    local self = setmetatable(GameObject.new(), Entity)--[[@as entity]]
    self.health = 0
    self.max_health = 0
    self.vel_x = 0
    self.vel_y = 0
    self.stagger_x = 0
    self.stagger_y = 0
    self.stagger_knockback_threshold_x = 100
    self.stagger_knockback_threshold_y = 100
    self.stagger_force_multiplier = 1
    self.stagger_recovery = 50
    self.target_vel_x = 0
    self.friction = 1
    self.dir = 1
    self.grounded = true
    self.acceleration = 0
    self.can_move = true
    self.gravity_enabled = true
    self.hitbox = Rectangle.new(0, 0, 0, 0)
    self.hitbox_offset_x = 0
    self.hitbox_offset_y = 0
    self.hitbox_size_x = 0
    self.hitbox_size_y = 0
    self.time_since_damaged = 100
    self.damage_on_impact = 0
    return self
end

-- DON'T FORGET TO CALL THIS IN EVERY ENTITY'S INITIALIZE AFTER SETTING ANIMATION
---@protected
function Entity:add_event_listeners()
    self.animation:add_event_listener("disable_movement", self.disable_movement_event)
    self.animation:add_event_listener("enable_movement", self.enable_movement_event)
    self.animation:add_event_listener("disable_gravity", self.disable_gravity_event)
    self.animation:add_event_listener("enable_gravity", self.enable_gravity_event)
    self.animation:add_event_listener("apply_force", self.apply_force_event)
    self.animation:add_event_listener("set_dir", self.set_dir_event)
    self.animation:add_event_listener("set_friction", self.set_friction_event)
    self.animation:add_event_listener("attack", self.attack_event)
end

function Entity:update()
    self.animation:update()

    self:update_stagger()
    self:update_movement()

    self.grounded = self.y == self.game.level.ground_level
    if self.damage_on_impact ~= 0 and self.y < self.game.level.ground_level + 8 and (self.grounded or math.abs(self.vel_x + self.vel_y) < 4) then
        self.damage_on_impact = 0
        self.damage_on_impact_tags = nil
        self.damage_on_impact_sources = nil
    end

    self.hitbox.x = self.x + self.hitbox_offset_x
    self.hitbox.y = self.y + self.hitbox_offset_y
    self.hitbox.w = self.hitbox_size_x
    self.hitbox.h = self.hitbox_size_y

    if self.damage_on_impact ~= 0 then
        local entities = self.game:get_all_entities(self.hitbox, self.damage_on_impact_tags)
        if entities ~= nil then
            for i, target in ipairs(entities) do
                if target == self or target.damage_on_impact ~= 0 or (self.damage_on_impact_sources ~= nil and self.damage_on_impact_sources[target] == true) or not target:should_take_damage(self) then
                    goto continue
                end

                local transferred_force = self.vel_x * 0.9
                self.vel_x = self.vel_x - transferred_force
                if self.damage_on_impact_sources == nil then
                    self.damage_on_impact_sources = { self = true }
                else
                    self.damage_on_impact_sources[self] = true
                end

                target.vel_x = transferred_force
                target.vel_y = math.max(self.vel_y, 50)
                target.damage_on_impact = self.damage_on_impact * 0.5
                target.damage_on_impact_tags = self.damage_on_impact_tags
                target.damage_on_impact_sources = self.damage_on_impact_sources
                target:damage(self.damage_on_impact)
                self:damage(self.damage_on_impact * 0.25)
                self.damage_on_impact = 0
                self.damage_on_impact_tags = nil
                self.damage_on_impact_sources = nil

                ::continue::
            end
        end
    end

    self.time_since_damaged = self.time_since_damaged + Time.delta_time
end

function Entity:update_stagger()
    local dt = Time.delta_time
    local stagger_recovery = self.stagger_recovery
    if self.knocked_back then
        self.knockback_recovery_accumulator = self.knockback_recovery_accumulator + (self.stagger_recovery * dt * 2)
        stagger_recovery = stagger_recovery + self.knockback_recovery_accumulator
    end

    self.stagger_x = self.stagger_x - (stagger_recovery * dt)
    self.stagger_y = self.stagger_y - (stagger_recovery * dt)
    if self.stagger_x < 0 then
        self.stagger_x = 0
    end
    if self.stagger_y < 0 then
        self.stagger_y = 0
    end

    if self.knocked_back and self.grounded and self.stagger_x == 0 and self.stagger_y == 0 then
        self.knocked_back = false
        self.stagger_x = 0
        self.stagger_y = 0
    end
end

function Entity:update_movement()
    local dt = Time.delta_time
    local acc = self.acceleration * self.friction

    if self.vel_x < self.target_vel_x then
        self.vel_x = math.min(self.vel_x + (acc * dt), self.target_vel_x)
    elseif self.vel_x > self.target_vel_x then
        self.vel_x = math.max(self.vel_x - (acc * dt), self.target_vel_x)
    end

    self.x = self.x + (self.vel_x * dt)

    if not self.grounded and self.gravity_enabled then
        self.vel_y = self.vel_y - (self.game.level.gravity * dt)
    end
    self.y = self.y + (self.vel_y * dt)

    if self.y < self.game.level.ground_level then
        self.y = self.game.level.ground_level
        if self.vel_y < 0 then
            self.vel_y = 0
        end
    end
end

---@param x number
---@param y number
function Entity:apply_force(x, y)
    if x ~= 0 then
        self.vel_x = self.vel_x + x
    end
    if y ~= 0 then
        self.vel_y = self.vel_y + y
    end
end

---@param params table?
function Entity:disable_movement_event(params)
    self.can_move = false
end

---@private
---@param params table?
function Entity:enable_movement_event(params)
    self.can_move = true
end

---@private
---@param params table
function Entity:apply_force_event(params)
    if params.x ~= nil then
        local x = params.x
        if params.directional and self.dir == -1 then
            x = -x
        end

        if params.absolute then
            self.vel_x = x
        else
            self.vel_x = self.vel_x + x
        end
    end
    if params.y ~= nil then
        if params.absolute then
            self.vel_y = params.y
        else
            self.vel_y = self.vel_y + params.y
        end
    end
end

---@param params table
function Entity:set_dir_event(params)
    self.dir = params.dir
end

---@param params table
function Entity:set_friction_event(params)
    self.friction = params.friction
end

---@param params table
function Entity:disable_gravity_event(params)
    if self.gravity_enabled then
        self.gravity_enabled = false
        self.vel_y = 0
    end
end

---@param params table
function Entity:enable_gravity_event(params)
    if not self.gravity_enabled then
        self.gravity_enabled = true
        self.vel_y = self.vel_y + 30
    end
end

---@protected
function Entity:get_attack_target_tag()
    return "enemy"
end

---@class attack_event_params
---@field public box rectangle
---@field public stagger stagger_info
---@field public damage number
---@field public on_hit fun(self: entity, targets: entity[])
---@field public on_miss fun(self: entity)

---@param params attack_event_params
function Entity:attack_event(params)
    local box = params.box:copy()
    local stagger = params.stagger
    local damage = params.damage

    if self.dir == -1 then
        box.x = -box.x - box.w
    end

    box.x = box.x + self.x
    box.y = box.y + self.y

    if self.dir == -1 and stagger ~= nil then
        stagger = stagger:copy()
        if stagger.dir == 1 then
            stagger.dir = -1
        elseif stagger.dir == -1 then
            stagger.dir = 1
        end
    end

    self.game:add_debug_box(box.x, box.y, box.w, box.h)
    local entities = self.game:get_all_entities(box)
    ---@type entity[]
    local hits = {}
    if entities ~= nil then
        for i, entity in ipairs(entities) do
            if entity:has_tag(self:get_attack_target_tag()) then
                if entity:should_take_damage(self) then
                    entity:damage(damage, stagger, true)
                    table.insert(hits, entity)
                end
            end
        end
    end

    if params.on_hit ~= nil and hits[1] ~= nil then
        params.on_hit(self, hits)
    elseif params.on_miss then
        params.on_miss(self)
    end
end

---@return boolean
function Entity:should_take_damage(attacker)
    return true
end

---@param amount number
---@param stagger stagger_info
---@param blood boolean
---@overload fun(amount: number)
function Entity:damage(amount, stagger, blood)
    if stagger ~= nil then
        self.stagger_x = self.stagger_x + stagger.x
        self.stagger_y = self.stagger_y + stagger.y
        self:apply_knockback(stagger, self.stagger_force_multiplier, true)

        if self:should_knockback() then
            self.stagger_x = self.stagger_x + stagger.x
            self.stagger_y = self.stagger_y + stagger.y
            self:knockback(stagger)
        end
    end

    self.time_since_damaged = 0
    self.health = self.health - amount
    if self.health <= 0 then
        self:destroy();
    end

    if blood == nil or blood then
        local blood_count = math.random(math.ceil(amount * 0.125), math.ceil(amount * 0.375))
        if self.health <= 0 then
            blood_count = blood_count + math.random(math.ceil(self.max_health * 0.2), math.ceil(self.max_health * 0.3))
        end

        for i = 1, blood_count do
            local vel_x
            if stagger ~= nil and stagger.dir == -1 then
                vel_x = 20
            elseif stagger ~= nil and stagger.dir == 1 then
                vel_x = -20
            else
                vel_x = 0
            end

            local x = self.x + ((math.random() - 0.5) * (self.hitbox_size_x * 0.8))
            local y = self.y + (math.random() * (self.hitbox_size_y * 0.8)) + (self.hitbox_size_y * 0.2)
            self.game.particles:add(Blood, x, y, vel_x + ((math.random() - 0.5) * 80), 60 + ((math.random() - 0.5) * 30))
        end
    end
end

---@private
function Entity:should_knockback()
    if self.knocked_back then
        return true
    end
    return self.stagger_x >= self.stagger_knockback_threshold_x or self.stagger_y >= self.stagger_knockback_threshold_y
end

---@private
---@param stagger stagger_info
function Entity:knockback(stagger)
    self:apply_knockback(stagger, self.stagger_force_multiplier, true)
    if not self.knocked_back then
        self.knocked_back = true
        self.knockback_recovery_accumulator = 0
    end
end

---@private
---@param stagger stagger_info
---@param multiplier number
---@param absolute true
function Entity:apply_knockback(stagger, multiplier, absolute)
    local force_x = stagger.x * multiplier
    local force_y = stagger.y * multiplier
    force_x = math.max(25, force_x)
    force_y = math.max(50, force_y)
    if stagger.dir == -1 then
        force_x = -force_x
    end
    if absolute then
        self.vel_x = 0
        self.vel_y = 0
    end
    self:apply_force(force_x, force_y)
end

function Entity:is_staggered()
    return self.knocked_back
end

---@param damage number
---@param tag string?
---@param source entity?
function Entity:apply_damage_on_impact(damage, tag, source)
    self.damage_on_impact = damage
    if tag ~= nil then
       self.damage_on_impact_tags = { tag } 
    else
        self.damage_on_impact_tags = nil
    end

    if source ~= nil then
       self.damage_on_impact_sources = { source = true }
    else
        self.damage_on_impact_sources = nil
    end
end

---@param layer integer
function Entity:draw_health_bar(layer)
    local x = math.floor(self.x + 0.5) + self.hitbox_offset_x
    local y = math.floor(self.y + 0.5) + self.hitbox_size_y + 2

    local amount = self.health / self.max_health
    local total_width = self.hitbox_size_x
    local width = math.ceil(total_width * amount)
    for i = 1, total_width do
        local b
        if i <= width then
            b = block.colorred
        else
            b = block.colorblack
        end

        self.game.screen:draw_pixel(b, x, y, layer)

        x = x + 1
    end
end