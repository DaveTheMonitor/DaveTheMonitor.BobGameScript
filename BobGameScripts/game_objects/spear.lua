--#build
--#priority 403

---@class spear : weapon
Spear = setmetatable({}, Weapon)
Spear.__index = Spear
Spear.idle_anim_state = "spear_idle"
Spear.run_anim_state = "spear_run"
Spear.air_anim_state = "spear_air"

---@param player player
---@return spear
function Spear.new(player)
    local self = setmetatable(Weapon.new(), Spear)--[[@as spear]]
    self.player = player
    return self
end

function Spear:initialize()
    self.sprite = sprite_manager:load("player_spear")
    local anim_controller = self.player.animation_controller

    local anim = anim_controller:add_state("spear_idle")
    anim.animation = Animation.new({
        [0.0] = AnimationFrame.new(Rectangle.new(128, 0, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil }),
        }),
    }, 0, LoopType.Loop)
    anim:add_transition(function (self)
        ---@cast self player
        if not self.grounded then
            return Spear.air_anim_state
        elseif self.vel_x > 0.01 or self.vel_x < -0.01 then
            return Spear.run_anim_state
        end
        return nil
    end)

    anim = anim_controller:add_state("spear_run")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(144, 0, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil }),
        }),
        [0.14] = AnimationFrame.new(Rectangle.new(160, 0, 16, 16)),
        [0.28] = AnimationFrame.new(Rectangle.new(176, 0, 16, 16)),
        [0.42] = AnimationFrame.new(Rectangle.new(192, 0, 16, 16)),
    }, 0.56, LoopType.Loop)
    anim:add_transition(function (self)
        ---@cast self player
        if not self.grounded then
            return Spear.air_anim_state
        elseif self.vel_x < 0.01 and self.vel_x > -0.01 then
            return Spear.idle_anim_state
        end
        return nil
    end)

    anim = anim_controller:add_state("spear_air")
    anim.animation = Animation.new({
        [0.0] = AnimationFrame.new(Rectangle.new(160, 0, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil }),
        }),
    }, 0.0, LoopType.Loop)
    anim:add_transition(function (self)
        ---@cast self player
        if self.grounded and (self.vel_x > 0.01 or self.vel_x < -0.01) then
            return Spear.run_anim_state
        elseif self.grounded and self.vel_x < 0.01 and self.vel_x > -0.01 then
            return Spear.idle_anim_state
        end
        return nil
    end)

    anim = anim_controller:add_state("spear_ground_1")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(128, 16, 16, 16), {
            "disable_movement",
            EventTrigger.new("set_combo_type", { type = "spear" })
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(144, 16, 16, 16), {
            EventTrigger.new("apply_force", { x = 60, directional = true })
        }),
        [0.08] = AnimationFrame.new(Rectangle.new(160, 16, 16, 16), {
            EventTrigger.new("attack", { damage = 15, box = Rectangle.new(0, 0, 14, 10), stagger = StaggerInfo.new(40, 0, 1) })
        }),
        [0.12] = AnimationFrame.new(Rectangle.new(176, 16, 16, 16)),
        [0.16] = AnimationFrame.new(Rectangle.new(192, 16, 16, 16)),
        [0.20] = AnimationFrame.new(Rectangle.new(208, 16, 16, 16)),
        [0.24] = AnimationFrame.new(Rectangle.new(208, 16, 16, 16)),
        [0.28] = AnimationFrame.new(Rectangle.new(208, 16, 16, 16), {
            "enable_movement"
        }),
    }, 0.28, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            if self:consume_queued_attack(AttackInput.attack) or self:consume_queued_attack(AttackInput.down) then
                return "spear_ground_2"
            end
        end

        if self.animation.total_time > self.animation.length + 0.4 then
            return "spear_ground_end_1"
        end
        
        if self.animation.finished then
            return default_spear_transition(self, true)
        end

        return nil
    end)

    anim = anim_controller:add_state("spear_ground_2")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(128, 48, 16, 16), {
            "disable_movement"
        }),
        [0.06] = AnimationFrame.new(Rectangle.new(144, 48, 16, 16), {
            EventTrigger.new("apply_force", { x = 70, directional = true })
        }),
        [0.12] = AnimationFrame.new(Rectangle.new(160, 48, 16, 16), {
            EventTrigger.new("attack", { damage = 5, box = Rectangle.new(0, 0, 14, 16), stagger = StaggerInfo.new(20, 0, 1) })
        }),
        [0.18] = AnimationFrame.new(Rectangle.new(176, 48, 16, 16)),
        [0.24] = AnimationFrame.new(Rectangle.new(192, 48, 16, 16), {
            EventTrigger.new("attack", { damage = 5, box = Rectangle.new(0, 0, 14, 16), stagger = StaggerInfo.new(20, 0, 1) })
        }),
        [0.30] = AnimationFrame.new(Rectangle.new(176, 48, 16, 16)),
        [0.36] = AnimationFrame.new(Rectangle.new(192, 48, 16, 16), {
            EventTrigger.new("attack", { damage = 5, box = Rectangle.new(0, 0, 14, 16), stagger = StaggerInfo.new(20, 0, 1) })
        }),
        [0.42] = AnimationFrame.new(Rectangle.new(176, 16, 16, 16)),
        [0.48] = AnimationFrame.new(Rectangle.new(192, 16, 16, 16), {
            EventTrigger.new("apply_force", { x = -50, directional = true })
        }),
        [0.54] = AnimationFrame.new(Rectangle.new(208, 16, 16, 16)),
        [0.60] = AnimationFrame.new(Rectangle.new(208, 16, 16, 16)),
        [0.66] = AnimationFrame.new(Rectangle.new(208, 16, 16, 16), {
            "enable_movement"
        }),
    }, 0.66, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            if self:consume_queued_attack(AttackInput.attack) or self:consume_queued_attack(AttackInput.down) then
                return "spear_ground_3"
            end
        end

        if self.animation.total_time > self.animation.length + 0.4 then
            return "spear_ground_end_1"
        end
        
        if self.animation.finished then
            return default_spear_transition(self, true)
        end

        return nil
    end)

    anim = anim_controller:add_state("spear_ground_3")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(128, 64, 16, 16), {
            "disable_movement",
            EventTrigger.new("apply_force", { x = 130, directional = true }),
            EventTrigger.new("attack", { damage = 20, box = Rectangle.new(0, 0, 24, 10), stagger = StaggerInfo.new(60, 0, 1) })
        }),
        [0.12] = AnimationFrame.new(Rectangle.new(144, 64, 16, 16)),
        [0.24] = AnimationFrame.new(Rectangle.new(160, 64, 16, 16), {
            EventTrigger.new("attack", { damage = 10, box = Rectangle.new(0, 0, 10, 10), stagger = StaggerInfo.new(40, 0, 1) })
        }),
        [0.48] = AnimationFrame.new(Rectangle.new(160, 64, 16, 16)),
        [0.58] = AnimationFrame.new(Rectangle.new(176, 64, 16, 16)),
        [0.68] = AnimationFrame.new(Rectangle.new(176, 64, 16, 16), {
            "enable_movement"
        }),
    }, 0.68, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            return "spear_ground_end_1"
        end

        return nil
    end)

    anim = anim_controller:add_state("spear_ground_stab")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(128, 80, 16, 16), {
            "disable_movement",
            EventTrigger.new("set_combo_type", { type = "spear" })
        }),
        [0.08] = AnimationFrame.new(Rectangle.new(144, 80, 16, 16), {
            EventTrigger.new("attack", { damage = 5, box = Rectangle.new(0, 0, 16, 12), stagger = StaggerInfo.new(40, 20, 1) }),
            EventTrigger.new("apply_force", { x = 100, directional = true, absolute = true }),
            EventTrigger.new("set_friction", { friction = 0.2 }),
        }),
        [0.16] = AnimationFrame.new(Rectangle.new(160, 80, 16, 16), {
            EventTrigger.new("attack", { damage = 2, box = Rectangle.new(0, 0, 18, 12), stagger = StaggerInfo.new(100, 20, 1) }),
            EventTrigger.new("apply_force", { x = 120, directional = true, absolute = true })
        }),
        [0.26] = AnimationFrame.new(Rectangle.new(176, 80, 16, 16), {
            EventTrigger.new("attack", { damage = 2, box = Rectangle.new(0, 0, 18, 12), stagger = StaggerInfo.new(70, 20, 1) })
        }),
        [0.36] = AnimationFrame.new(Rectangle.new(192, 80, 32, 16), {
            EventTrigger.new("apply_force", { x = 80, directional = true, absolute = true }),
            EventTrigger.new("set_friction", { friction = 1 }),
        }),
        [0.44] = AnimationFrame.new(Rectangle.new(224, 80, 16, 16), {
            EventTrigger.new("attack", { damage = 15, box = Rectangle.new(0, 0, 16, 16), stagger = StaggerInfo.new(45, 20, 1) }),
        }),
        [0.52] = AnimationFrame.new(Rectangle.new(240, 80, 16, 16)),
        [0.60] = AnimationFrame.new(Rectangle.new(240, 80, 16, 16), {
            "enable_movement"
        }),
    }, 0.60, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            if self:consume_queued_attack(AttackInput.attack) or self:consume_queued_attack(AttackInput.down) then
                return "spear_ground_1_from_stab"
            end
        end
        
        if self.animation.total_time > self.animation.length + 0.4 then
            return "spear_ground_end_1"
        end

        if self.animation.finished then
            local state = default_spear_transition(self, true)
            if state ~= nil then
                return state
            end
        end

        return nil
    end)

    anim = anim_controller:add_state("spear_ground_1_from_stab")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(160, 16, 16, 16), {
            "disable_movement",
            EventTrigger.new("apply_force", { x = 60, directional = true }),
            EventTrigger.new("attack", { damage = 15, box = Rectangle.new(0, 0, 14, 10), stagger = StaggerInfo.new(40, 0, 1) })
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(176, 16, 16, 16)),
        [0.08] = AnimationFrame.new(Rectangle.new(192, 16, 16, 16)),
        [0.12] = AnimationFrame.new(Rectangle.new(208, 16, 16, 16)),
        [0.16] = AnimationFrame.new(Rectangle.new(208, 16, 16, 16), {
            "enable_movement"
        }),
    }, 0.20, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            if self:consume_queued_attack(AttackInput.attack) then
                return "spear_ground_2"
            end
        end

        if self.animation.total_time > self.animation.length + 0.4 then
            return "spear_ground_end_1"
        end
        
        if self.animation.finished then
            return default_spear_transition(self, true)
        end

        return nil
    end)

    anim = anim_controller:add_state("spear_uppercut")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(128, 16, 16, 16), {
            "disable_movement",
            EventTrigger.new("set_combo_type", { type = "spear" })
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(208, 48, 16, 16), {
            EventTrigger.new("apply_force", { x = 30, directional = true }),
        }),
        [0.08] = AnimationFrame.new(Rectangle.new(224, 48, 16, 16), {
            EventTrigger.new("attack", { damage = 20, box = Rectangle.new(0, 0, 12, 10), stagger = StaggerInfo.new(10, 140, 1) })
        }),
        [0.12] = AnimationFrame.new(Rectangle.new(240, 48, 16, 16), {
            EventTrigger.new("apply_force", { x = 30, y = 130, absolute = true, directional = true }),
        }),
        [0.16] = AnimationFrame.new(Rectangle.new(240, 64, 16, 16)),
        [0.20] = AnimationFrame.new(Rectangle.new(224, 64, 16, 16), {
            "enable_movement"
        }),
    }, 0.24, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            return default_spear_transition(self, false)
        end

        return nil
    end)

    anim = anim_controller:add_state("spear_air_down_stab")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(128, 96, 16, 32), {
            "disable_movement",
            EventTrigger.new("set_combo_type", { type = "spear" })
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(144, 96, 16, 32), {
            EventTrigger.new("apply_force", { y = -80, absolute = true }),
        })
    }, 0.04, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            return "spear_air_down_stab_attack"
        end

        if self.grounded then
            return "spear_air_down_stab_miss"
        end

        return nil
    end)

    anim = anim_controller:add_state("spear_air_down_stab_attack")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(144, 96, 16, 32), {
            EventTrigger.new("attack", { damage = 5, box = Rectangle.new(-6, -6, 12, 12), stagger = StaggerInfo.new(0, 10, 1), on_hit = function(self, targets)
                ---@cast self player
                self.animation:change_state("spear_air_down_stab_hit")
            end })
        })
    }, 0.04, LoopType.Loop)
    anim:add_transition(function (self)
        ---@cast self player
        if self.grounded then
            return "spear_air_down_stab_miss"
        end

        return nil
    end)

    anim = anim_controller:add_state("spear_air_down_stab_hit")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(144, 96, 16, 32), {
            EventTrigger.new("apply_force", { y = 120, absolute = true })
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(208, 64, 16, 16)),
        [0.16] = AnimationFrame.new(Rectangle.new(224, 64, 16, 16), {
            "enable_movement"
        }),
    }, 0.20, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            return default_spear_transition(self, false)
        end
    end)

    anim = anim_controller:add_state("spear_air_down_stab_miss")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(160, 96, 16, 16)),
        [0.60] = AnimationFrame.new(Rectangle.new(176, 96, 16, 16)),
        [0.72] = AnimationFrame.new(Rectangle.new(192, 96, 16, 16), {
            "enable_movement"
        }),
        [0.84] = AnimationFrame.new(Rectangle.new(208, 96, 16, 16)),
        [0.96] = AnimationFrame.new(Rectangle.new(208, 32, 16, 16)),
    }, 1.08, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        
        if self.animation.finished then
            return "spear_idle"
        end

        if self.animation.time >= 0.72 then
            return default_spear_transition(self, true) or self:transition_to_any_movement_state(true, false, false)
        end

        return nil
    end)

    anim = anim_controller:add_state("spear_air_stab_right")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(160, 112, 16, 16), {
            "disable_movement", "disable_gravity",
            EventTrigger.new("set_dir", { dir = 1 }),
            EventTrigger.new("set_combo_type", { type = "spear" }),
            EventTrigger.new("apply_force", { x = 140, directional = true, absolute = true }),
            EventTrigger.new("attack", { damage = 20, box = Rectangle.new(0, 0, 28, 10), stagger = StaggerInfo.new(100, 20, 1) })
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(176, 112, 16, 16)),
        [0.08] = AnimationFrame.new(Rectangle.new(192, 112, 16, 16)),
        [0.12] = AnimationFrame.new(Rectangle.new(224, 64, 16, 16)),
        [0.16] = AnimationFrame.new(Rectangle.new(224, 64, 16, 16), {
            "enable_gravity"
        }),
    }, 0.16, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            if self.grounded then
                return self:transition_to_any_movement_state(false, true, false)
            end

            local state = default_spear_transition(self, false)
            -- we don't allow chaining stabs in the same direction
            if state ~= "spear_air_stab_right" and state ~= nil then
                return state
            end
        end

        return nil
    end)

    anim = anim_controller:add_state("spear_air_stab_left")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(160, 112, 16, 16), {
            "disable_movement", "disable_gravity",
            EventTrigger.new("set_dir", { dir = -1 }),
            EventTrigger.new("set_combo_type", { type = "spear" }),
            EventTrigger.new("apply_force", { x = 140, directional = true, absolute = true }),
            EventTrigger.new("attack", { damage = 20, box = Rectangle.new(0, 0, 28, 10), stagger = StaggerInfo.new(100, 20, 1) })
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(176, 112, 16, 16)),
        [0.08] = AnimationFrame.new(Rectangle.new(192, 112, 16, 16)),
        [0.12] = AnimationFrame.new(Rectangle.new(224, 64, 16, 16)),
        [0.16] = AnimationFrame.new(Rectangle.new(224, 64, 16, 16), {
            "enable_gravity"
        }),
    }, 0.16, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            if self.grounded then
                return self:transition_to_any_movement_state(false, true, false)
            end

            local state = default_spear_transition(self, false)
            -- we don't allow chaining stabs in the same direction
            if state ~= "spear_air_stab_left" and state ~= nil then
                return state
            end
        end

        return nil
    end)

    anim = anim_controller:add_state("spear_ground_end_1")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(128, 32, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil })
        }),
        [0.12] = AnimationFrame.new(Rectangle.new(144, 32, 16, 16)),
        [0.24] = AnimationFrame.new(Rectangle.new(224, 32, 16, 16)),
        [0.36] = AnimationFrame.new(Rectangle.new(208, 32, 16, 16)),
    }, 0.48, LoopType.Once)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            return Spear.idle_anim_state
        end

        return self:transition_to_any_movement_state(true, false, false)
    end)
end

---@package
---@param player player
---@param ground_anim boolean
---@return string? state
function default_spear_transition(player, ground_anim, blacklist)
    if player:is_weapon_switch_queued() then
        return player:transition_to_any_movement_state(ground_anim, true, true)
    end

    if player.grounded then
        if player:consume_queued_attack(AttackInput.attack) or player:consume_queued_attack(AttackInput.down) then
            return "spear_ground_1"
        elseif player:consume_queued_attack(AttackInput.left) then
            player.dir = -1
            return "spear_ground_stab"
        elseif player:consume_queued_attack(AttackInput.right) then
            player.dir = 1
            return "spear_ground_stab"
        elseif player:consume_queued_attack(AttackInput.up) then
            return "spear_uppercut"
        end
    else
        if player:consume_queued_attack(AttackInput.down) then
            return "spear_air_down_stab"
        elseif player:consume_queued_attack(AttackInput.right) then
            return "spear_air_stab_right"
        elseif player:consume_queued_attack(AttackInput.left) then
            return "spear_air_stab_left"
        end
    end

    return player:transition_to_any_movement_state(ground_anim, false, true)
end

function Spear:attack_input()
    local state = default_spear_transition(self.player, false)
    if state ~= nil then
        self.player.animation:change_state(state)
    end
end

function Spear:special_input() end