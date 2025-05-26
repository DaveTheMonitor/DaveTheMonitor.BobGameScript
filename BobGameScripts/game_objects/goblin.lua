--#build
--#priority 412

---@class goblin : enemy
---@field health_multiplier number
---@field movement_speed_multiplier number
Goblin = Enemy.new()
Goblin.__index = Goblin

do
    local anim_controller = AnimationController.new()
    anim_controller.default_state = "idle"

    local anim = anim_controller:add_state("idle")
    anim.animation = Animation.new({
        [0.0] = AnimationFrame.new(Rectangle.new(0, 0, 16, 16), {
            "enable_movement"
        })
    }, 0, LoopType.Loop)
    anim:add_transition(function (self)
        ---@cast self goblin
        if not self.grounded then
            return "air"
        end

        if math.abs(self.vel_x) > 0.1 then
            return "walk"
        end

        return nil
    end)

    anim = anim_controller:add_state("walk")
    anim.animation = Animation.new({
        [0.0] = AnimationFrame.new(Rectangle.new(16, 0, 16, 16), {
            "enable_movement"
        }),
        [0.15] = AnimationFrame.new(Rectangle.new(32, 0, 16, 16)),
        [0.3] = AnimationFrame.new(Rectangle.new(0, 0, 16, 16))
    }, 0.45, LoopType.Loop)
    anim:add_transition(function (self)
        ---@cast self goblin
        if not self.grounded then
            return "air"
        end

        if math.abs(self.vel_x) < 0.1 then
            return "idle"
        end

        return nil
    end)

    anim = anim_controller:add_state("air")
    anim.animation = Animation.new({
        [0.0] = AnimationFrame.new(Rectangle.new(48, 0, 16, 16), {
            "disable_movement",
        }),
        [0.08] = AnimationFrame.new(Rectangle.new(64, 0, 16, 16)),
    }, 0.16, LoopType.Loop)
    anim:add_transition(function (self)
        ---@cast self goblin
        if self.grounded then
            return "landing_recovery"
        end

        return nil
    end)

    anim = anim_controller:add_state("landing_recovery")
    anim.animation = Animation.new({
        [0.0] = AnimationFrame.new(Rectangle.new(80, 0, 16, 16)),
        [0.08] = AnimationFrame.new(Rectangle.new(96, 0, 16, 16)),
    }, 1.08, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self goblin
        if not self.grounded then
            return "air"
        end

        if self.animation.finished and not self:is_staggered() then
            return "idle"
        end

        return nil
    end)

    anim = anim_controller:add_state("attack")
    anim.animation = Animation.new({
        [0.0] = AnimationFrame.new(Rectangle.new(0, 16, 16, 16), {
            "disable_movement"
        }),
        [0.12] = AnimationFrame.new(Rectangle.new(16, 16, 16, 16)),
        [0.24] = AnimationFrame.new(Rectangle.new(32, 16, 16, 16)),
        [0.48] = AnimationFrame.new(Rectangle.new(48, 16, 16, 16), {
            EventTrigger.new("apply_force", { x = 60, directional = true }),
            EventTrigger.new("attack", { damage = 15, box = Rectangle.new(0, 0, 12, 6), stagger = StaggerInfo.new(60, 0, 1) })
        }),
        [0.52] = AnimationFrame.new(Rectangle.new(64, 16, 16, 16)),
        [0.72] = AnimationFrame.new(Rectangle.new(64, 16, 16, 16)),
    }, 0.72, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self goblin
        if not self.grounded then
            return "air"
        end

        if self.animation.finished then
            local target = self.game:get_nearest_player()
            if target ~= nil and distance(self.x, self.y, target.x, target.y) < 12 then
                if target.x < self.x then
                    self.dir = -1
                else
                    self.dir = 1
                end
                return "attack_2"
            end

            return "idle"
        end

        return nil
    end)

    anim = anim_controller:add_state("attack_2")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(16, 16, 16, 16)),
        [0.12] = AnimationFrame.new(Rectangle.new(32, 16, 16, 16)),
        [0.36] = AnimationFrame.new(Rectangle.new(48, 16, 16, 16), {
            EventTrigger.new("apply_force", { x = 60, directional = true }),
            EventTrigger.new("attack", { damage = 15, box = Rectangle.new(0, 0, 12, 6), stagger = StaggerInfo.new(60, 0, 1) })
        }),
        [0.40] = AnimationFrame.new(Rectangle.new(64, 16, 16, 16)),
        [0.60] = AnimationFrame.new(Rectangle.new(64, 16, 16, 16)),
    }, 0.60, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self goblin
        if not self.grounded then
            return "air"
        end

        if self.animation.finished then
            local target = self.game:get_nearest_player()
            if target ~= nil and distance(self.x, self.y, target.x, target.y) < 12 then
                if target.x < self.x then
                    self.dir = -1
                else
                    self.dir = 1
                end
                return "attack_2"
            end

            return "idle"
        end

        return nil
    end)

    Goblin.animation_controller = anim_controller
end

---@param x number
---@param y number
---@param health_multiplier number
---@param speed_multiplier number
---@return goblin
function Goblin.new(x, y, health_multiplier, speed_multiplier)
    local self = setmetatable(Enemy.new(), Goblin)--[[@as goblin]]
    self.x = x
    self.y = y
    self.health_multiplier = health_multiplier
    self.movement_speed_multiplier = speed_multiplier
    return self
end

function Goblin:initialize()
    Enemy.initialize(self)
    self.can_move = false
    self.sprite = sprite_manager:load("goblin")
    self.animation = AnimationInstance.new(self, self.animation_controller)
    self:add_event_listeners()
    self.tags = { "entity", "enemy", "melee", "goblin" }
    self.max_health = 60 * self.health_multiplier
    self.health = self.max_health
    self.stagger_knockback_threshold_x = 70 * self.health_multiplier
    self.stagger_knockback_threshold_y = 70 * self.health_multiplier
    -- Goblins would typically has a 1.05 stagger force multiplier,
    -- but for the demo it's set to 1
    self.stagger_force_multiplier = 1.00
    self.stagger_recovery = 25 * self.health_multiplier
    self.name = "goblin"
    self.move_speed = 20 * self.movement_speed_multiplier
    self.hitbox_size_x = 8
    self.hitbox_size_y = 6
    self.hitbox_offset_x = -4
end

function Goblin:update()
    Enemy.update(self)

    self.target_vel_x = 0
    if not self.grounded then
        self.acceleration = 20
    else
        self.acceleration = 250 * self.movement_speed_multiplier
    end

    local target = self.game:get_nearest_player()
    if self.ai_enabled and target ~= nil then
        if self.knocked_back or not self.can_move or distance(self.x, 0, target.x, 0) < 10 then
            self.target_vel_x = 0
        elseif target.x < self.x then
            self.dir = -1
            self.target_vel_x = -self.move_speed
        elseif target.x > self.x then
            self.dir = 1
            self.target_vel_x = self.move_speed
        else
            self.target_vel_x = 0
        end
    else
        self.target_vel_x = 0
    end

    if target ~= nil and self.can_move and not self.knocked_back then
        if target.x < self.x then
            self.dir = -1
        elseif target.x > self.x then
            self.dir = 1
        end
    end

    if target == nil then
        return
    end

    if self.ai_enabled and self.can_move and target.grounded then
        if distance(self.x, self.y, target.x, target.y) < 12 then
            self.animation:change_state("attack")
        end
    end
end

function Goblin:get_attack_target_tag()
    return "player"
end

function Goblin:draw()
    local x = math.floor(self.x + 0.5);
    local y = math.floor(self.y + 0.5);
    local rect = self.animation:get_current_frame().src

    local offset_x
    local offset_y
    local flip = false
    if self.dir == -1 then
        offset_x = -10
        offset_y = 0
        flip = true
    else
        offset_x = -5
        offset_y = 0
    end

    local b = nil
    if self.game.options.enemy_damage_flashes then
        if self.time_since_damaged < 0.1 then
            b = block.colorred
        end
    end
    self.game.screen:draw(self.sprite, rect.x, rect.y, rect.w, rect.h, x + offset_x, y + offset_y, Layers.melee_enemies, flip, false, b)

    self:draw_health_bar(Layers.melee_enemies)
end