--#build
--#priority 402

---@class sword : weapon
Sword = setmetatable({}, Weapon)
Sword.__index = Sword
Sword.idle_anim_state = "sword_idle"
Sword.run_anim_state = "sword_run"
Sword.air_anim_state = "sword_air"

---@param player player
---@return sword
function Sword.new(player)
    local self = setmetatable(Weapon.new(), Sword)--[[@as sword]]
    self.player = player
    return self
end

function Sword:initialize()
    self.sprite = sprite_manager:load("player_sword")
    local anim_controller = self.player.animation_controller

    local anim = anim_controller:add_state("sword_idle")
    anim.animation = Animation.new({
        [0.0] = AnimationFrame.new(Rectangle.new(0, 0, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil }),
        }),
    }, 0, LoopType.Loop)
    anim:add_transition(function (self)
        ---@cast self player
        if not self.grounded then
            return Sword.air_anim_state
        elseif self.vel_x > 0.01 or self.vel_x < -0.01 then
            return Sword.run_anim_state
        end
        return nil
    end)

    anim = anim_controller:add_state("sword_run")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(16, 0, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil }),
        }),
        [0.14] = AnimationFrame.new(Rectangle.new(32, 0, 16, 16)),
        [0.28] = AnimationFrame.new(Rectangle.new(48, 0, 16, 16)),
        [0.42] = AnimationFrame.new(Rectangle.new(64, 0, 16, 16)),
    }, 0.56, LoopType.Loop)
    anim:add_transition(function (self)
        ---@cast self player
        if not self.grounded then
            return Sword.air_anim_state
        elseif self.vel_x < 0.01 and self.vel_x > -0.01 then
            return Sword.idle_anim_state
        end
        return nil
    end)

    anim = anim_controller:add_state("sword_air")
    anim.animation = Animation.new({
        [0.0] = AnimationFrame.new(Rectangle.new(32, 0, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil }),
        }),
    }, 0.0, LoopType.Loop)
    anim:add_transition(function (self)
        ---@cast self player
        if self.grounded and (self.vel_x > 0.01 or self.vel_x < -0.01) then
            return Sword.run_anim_state
        elseif self.grounded and self.vel_x < 0.01 and self.vel_x > -0.01 then
            return Sword.idle_anim_state
        end
        return nil
    end)

    anim = anim_controller:add_state("sword_ground_1")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(0, 16, 16, 16), {
            "disable_movement",
            EventTrigger.new("set_combo_type", { type = "sword" })
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(16, 16, 16, 16)),
        [0.08] = AnimationFrame.new(Rectangle.new(32, 16, 16, 16)),
        [0.12] = AnimationFrame.new(Rectangle.new(48, 16, 16, 16)),
        [0.16] = AnimationFrame.new(Rectangle.new(64, 16, 16, 16), {
            EventTrigger.new("attack", { damage = 20, box = Rectangle.new(0, 0, 11, 16), stagger = StaggerInfo.new(35, 0, 1) }),
            EventTrigger.new("apply_force", { x = 50, directional = true })
        }),
        [0.20] = AnimationFrame.new(Rectangle.new(80, 16, 16, 16)),
        [0.24] = AnimationFrame.new(Rectangle.new(96, 16, 16, 16)),
        [0.28] = AnimationFrame.new(Rectangle.new(112, 16, 16, 16)),
        [0.36] = AnimationFrame.new(Rectangle.new(112, 16, 16, 16), {
            "enable_movement"
        }),
    }, 0.36, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            if self:consume_queued_attack(AttackInput.attack) or self:consume_queued_attack(AttackInput.down) then
                return "sword_ground_2"
            end
        end

        if self.animation.total_time > self.animation.length + 0.4 then
            return "sword_ground_end_1"
        end
        
        if self.animation.finished then
            return default_sword_transition(self, true)
        end

        return nil
    end)

    anim = anim_controller:add_state("sword_ground_2")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(0, 48, 16, 16), {
            "disable_movement",
            EventTrigger.new("attack", { damage = 20, box = Rectangle.new(0, 0, 11, 16), stagger = StaggerInfo.new(30, 20, 1) }),
            EventTrigger.new("apply_force", { x = 50, directional = true })
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(16, 48, 16, 16)),
        [0.08] = AnimationFrame.new(Rectangle.new(32, 48, 16, 16)),
        [0.12] = AnimationFrame.new(Rectangle.new(48, 48, 16, 16)),
        [0.20] = AnimationFrame.new(Rectangle.new(48, 48, 16, 16), {
            "enable_movement"
        }),
    }, 0.20, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            if self:consume_queued_attack(AttackInput.attack) or self:consume_queued_attack(AttackInput.down) then
                return "sword_ground_3"
            end
        end

        if self.animation.total_time > self.animation.length + 0.4 then
            return "sword_ground_end_2"
        end

        if self.animation.finished then
            return default_sword_transition(self, true)
        end

        return nil
    end)

    anim = anim_controller:add_state("sword_ground_3")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(0, 64, 32, 16), {
            "disable_movement"
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(32, 64, 32, 16), {
            EventTrigger.new("attack", { damage = 30, box = Rectangle.new(-11, 0, 11, 16), stagger = StaggerInfo.new(50, 0, -1) })
        }),
        [0.08] = AnimationFrame.new(Rectangle.new(64, 64, 16, 16), {
            EventTrigger.new("apply_force", { x = 60, directional = true })
        }),
        [0.12] = AnimationFrame.new(Rectangle.new(80, 64, 16, 16), {
            EventTrigger.new("attack", { damage = 30, box = Rectangle.new(0, 0, 11, 16), stagger = StaggerInfo.new(50, 0, 1) })
        }),
        [0.16] = AnimationFrame.new(Rectangle.new(96, 64, 16, 16)),
    }, 0.24, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.total_time > self.animation.length + 0.4 then
            return "sword_ground_end_3"
        end

        return nil
    end)

    local anim_controller = self.player.animation_controller
    local anim = anim_controller:add_state("sword_ground_1_from_stab")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(16, 16, 16, 16), {
            "disable_movement"
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(32, 16, 16, 16)),
        [0.08] = AnimationFrame.new(Rectangle.new(48, 16, 16, 16)),
        [0.12] = AnimationFrame.new(Rectangle.new(64, 16, 16, 16), {
            EventTrigger.new("attack", { damage = 20, box = Rectangle.new(0, 0, 11, 16), stagger = StaggerInfo.new(35, 0, 1) }),
            EventTrigger.new("apply_force", { x = 50, directional = true })
        }),
        [0.16] = AnimationFrame.new(Rectangle.new(80, 16, 16, 16)),
        [0.20] = AnimationFrame.new(Rectangle.new(96, 16, 16, 16)),
        [0.24] = AnimationFrame.new(Rectangle.new(112, 16, 16, 16)),
        [0.32] = AnimationFrame.new(Rectangle.new(112, 16, 16, 16), {
            "enable_movement"
        }),
    }, 0.32, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            if self:consume_queued_attack(AttackInput.attack) or self:consume_queued_attack(AttackInput.down) then
                return "sword_ground_2"
            end
        end

        if self.animation.total_time > self.animation.length + 0.4 then
            return "sword_ground_end_1"
        end
        
        if self.animation.finished then
            return default_sword_transition(self, true)
        end

        return nil
    end)

    anim = anim_controller:add_state("sword_ground_uppercut")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(0, 80, 16, 16), {
            "disable_movement",
            EventTrigger.new("set_combo_type", { type = "sword" })
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(16, 80, 16, 16)),
        [0.08] = AnimationFrame.new(Rectangle.new(32, 80, 16, 16), {
            EventTrigger.new("attack", { damage = 20, box = Rectangle.new(0, 0, 11, 16), stagger = StaggerInfo.new(45, 120, 1) }),
            EventTrigger.new("apply_force", { x = 50, directional = true })
        }),
        [0.12] = AnimationFrame.new(Rectangle.new(48, 80, 16, 16)),
        [0.16] = AnimationFrame.new(Rectangle.new(64, 80, 16, 16)),
        [0.20] = AnimationFrame.new(Rectangle.new(48, 48, 16, 16), {
            "enable_movement"
        }),
    }, 0.28, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.total_time > self.animation.length + 0.4 then
            return "sword_ground_end_2"
        end

        if self.animation.finished then
            return default_sword_transition(self, true)
        end

        return nil
    end)

    anim = anim_controller:add_state("sword_ground_stab_right")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(0, 96, 16, 16), {
            "disable_movement",
            EventTrigger.new("set_dir", { dir = 1 }),
            EventTrigger.new("set_combo_type", { type = "sword" })
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(16, 96, 16, 16), {
            EventTrigger.new("attack", { damage = 25, box = Rectangle.new(0, 0, 22, 10), stagger = StaggerInfo.new(80, 20, 1) }),
            EventTrigger.new("apply_force", { x = 160, directional = true, absolute = true })
        }),
        [0.08] = AnimationFrame.new(Rectangle.new(32, 96, 16, 16)),
        [0.12] = AnimationFrame.new(Rectangle.new(48, 96, 16, 16)),
        [0.20] = AnimationFrame.new(Rectangle.new(48, 96, 16, 16)),
    }, 0.20, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            if self:consume_queued_attack(AttackInput.attack) or self:consume_queued_attack(AttackInput.down) then
                return "sword_ground_1_from_stab"
            end
        end

        if self.animation.total_time > self.animation.length + 0.4 then
            return "sword_ground_end_4"
        end

        if self.animation.finished then
            local state = default_sword_transition(self, true)
            -- we don't allow chaining stabs in the same direction
            if state ~= nil and state ~= "sword_ground_stab_right" then
                return state
            end
        end

        return nil
    end)

    anim = anim_controller:add_state("sword_ground_stab_left")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(0, 96, 16, 16), {
            "disable_movement",
            EventTrigger.new("set_dir", { dir = -1 }),
            EventTrigger.new("set_combo_type", { type = "sword" })
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(16, 96, 16, 16), {
            EventTrigger.new("attack", { damage = 25, box = Rectangle.new(0, 0, 22, 10), stagger = StaggerInfo.new(80, 20, 1) }),
            EventTrigger.new("apply_force", { x = 160, directional = true, absolute = true })
        }),
        [0.08] = AnimationFrame.new(Rectangle.new(32, 96, 16, 16)),
        [0.12] = AnimationFrame.new(Rectangle.new(48, 96, 16, 16)),
        [0.20] = AnimationFrame.new(Rectangle.new(48, 96, 16, 16)),
    }, 0.20, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            if self:consume_queued_attack(AttackInput.attack) or self:consume_queued_attack(AttackInput.down) then
                return "sword_ground_1_from_stab"
            end
        end

        if self.animation.total_time > self.animation.length + 0.4 then
            return "sword_ground_end_4"
        end

        if self.animation.finished then
            local state = default_sword_transition(self, true)
            -- we don't allow chaining stabs in the same direction
            if state ~= nil and state ~= "sword_ground_stab_left" then
                return state
            end
        end

        return nil
    end)

    anim = anim_controller:add_state("sword_air_stab_right")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(64, 96, 16, 16), {
            "disable_movement", "disable_gravity",
            EventTrigger.new("set_dir", { dir = 1 }),
            EventTrigger.new("set_combo_type", { type = "sword" })
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(80, 96, 16, 16), {
            EventTrigger.new("attack", { damage = 25, box = Rectangle.new(0, 0, 22, 10), stagger = StaggerInfo.new(80, 20, 1) }),
            EventTrigger.new("apply_force", { x = 160, directional = true, absolute = true })
        }),
        [0.08] = AnimationFrame.new(Rectangle.new(96, 96, 16, 16)),
        [0.12] = AnimationFrame.new(Rectangle.new(112, 96, 16, 16)),
        [0.20] = AnimationFrame.new(Rectangle.new(112, 96, 16, 16), {
            "enable_gravity"
        }),
    }, 0.20, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            if self.grounded then
                return self:transition_to_any_movement_state(false, true, false)
            end

            local state = default_sword_transition(self, false)
            -- we don't allow chaining stabs in the same direction
            if state ~= "sword_air_stab_right" and state ~= nil then
                return state
            end
        end

        return nil
    end)

    anim = anim_controller:add_state("sword_air_stab_left")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(64, 96, 16, 16), {
            "disable_movement", "disable_gravity",
            EventTrigger.new("set_dir", { dir = -1 }),
            EventTrigger.new("set_combo_type", { type = "sword" })
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(80, 96, 16, 16), {
            EventTrigger.new("attack", { damage = 25, box = Rectangle.new(0, 0, 22, 10), stagger = StaggerInfo.new(80, 20, 1) }),
            EventTrigger.new("apply_force", { x = 160, directional = true, absolute = true })
        }),
        [0.08] = AnimationFrame.new(Rectangle.new(96, 96, 16, 16)),
        [0.12] = AnimationFrame.new(Rectangle.new(112, 96, 16, 16)),
        [0.20] = AnimationFrame.new(Rectangle.new(112, 96, 16, 16), {
            "enable_gravity"
        }),
    }, 0.20, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            if self.grounded then
                return self:transition_to_any_movement_state(false, true, false)
            end

            local state = default_sword_transition(self, false)
            -- we don't allow chaining stabs in the same direction
            if state ~= "sword_air_stab_left" and state ~= nil then
                return state
            end
        end

        return nil
    end)

    anim = anim_controller:add_state("sword_air_slam")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(0, 112, 16, 16), {
            "disable_movement",
            EventTrigger.new("set_combo_type", { type = "sword" })
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(16, 112, 16, 16), {
            EventTrigger.new("apply_force", { y = 100, absolute = true })
        }),
        [0.08] = AnimationFrame.new(Rectangle.new(32, 112, 16, 16)),
        [0.12] = AnimationFrame.new(Rectangle.new(48, 112, 16, 16)),
        [0.20] = AnimationFrame.new(Rectangle.new(64, 112, 16, 16), {
            EventTrigger.new("attack", { damage = 20, box = Rectangle.new(0, 0, 10, 10), stagger = StaggerInfo.new(35, 20, 1) }),
        }),
        [0.24] = AnimationFrame.new(Rectangle.new(80, 112, 16, 16)),
    }, 0.24, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.time < 0.12 and self.grounded then
            return self:transition_to_any_movement_state(true, true, false)
        end

        if self.animation.time > 0.12 and self.grounded then
            return "sword_air_slam_landing"
        end
        
        return nil
    end)

    anim = anim_controller:add_state("sword_air_slam_landing")
    anim.animation = Animation.new({
        [0.0] = AnimationFrame.new(Rectangle.new(96, 16, 16, 16), {
            EventTrigger.new("attack", { damage = 5, box = Rectangle.new(-15, 0, 15, 10), stagger = StaggerInfo.new(70, 40, -1) }),
            EventTrigger.new("attack", { damage = 15, box = Rectangle.new(0, 0, 10, 10), stagger = nil }),
            EventTrigger.new("attack", { damage = 5, box = Rectangle.new(0, 0, 15, 10), stagger = StaggerInfo.new(70, 40, 1) })
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(112, 16, 16, 16)),
    }, 0.04, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.total_time > self.animation.length + 0.4 then
            return "sword_ground_end_2"
        end

        return nil
    end)

    anim = anim_controller:add_state("sword_ground_end_1")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(0, 32, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil })
        }),
        [0.10] = AnimationFrame.new(Rectangle.new(16, 32, 16, 16)),
        [0.40] = AnimationFrame.new(Rectangle.new(32, 32, 16, 16)),
    }, 0.80, LoopType.Once)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            return Sword.idle_anim_state
        end

        return self:transition_to_any_movement_state(true, false, false)
    end)

    anim = anim_controller:add_state("sword_ground_end_2")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(48, 32, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil })
        }),
        [0.10] = AnimationFrame.new(Rectangle.new(16, 32, 16, 16)),
        [0.40] = AnimationFrame.new(Rectangle.new(32, 32, 16, 16)),
    }, 0.80, LoopType.Once)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            return Sword.idle_anim_state
        end

        return self:transition_to_any_movement_state(true, false, false)
    end)

    anim = anim_controller:add_state("sword_ground_end_3")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(64, 32, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil })
        }),
        [0.10] = AnimationFrame.new(Rectangle.new(16, 32, 16, 16)),
        [0.40] = AnimationFrame.new(Rectangle.new(32, 32, 16, 16)),
    }, 0.80, LoopType.Once)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            return Sword.idle_anim_state
        end

        return self:transition_to_any_movement_state(true, false, false)
    end)

    anim = anim_controller:add_state("sword_ground_end_4")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(16, 32, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil })
        }),
        [0.30] = AnimationFrame.new(Rectangle.new(32, 32, 16, 16)),
    }, 0.70, LoopType.Once)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            return Sword.idle_anim_state
        end

        return self:transition_to_any_movement_state(true, false, false)
    end)
end

---@package
---@param player player
---@return string? state
function default_sword_transition(player, ground_anim)
    if player:is_weapon_switch_queued() then
        return player:transition_to_any_movement_state(ground_anim, true, true)
    end

    if player.grounded then
        if player:consume_queued_attack(AttackInput.up) then
            return "sword_ground_uppercut"
        elseif player:consume_queued_attack(AttackInput.left) then
            return "sword_ground_stab_left"
        elseif player:consume_queued_attack(AttackInput.right) then
            return "sword_ground_stab_right"
        elseif player:consume_queued_attack(AttackInput.attack) or player:consume_queued_attack(AttackInput.down) then
            return "sword_ground_1"
        end
    else
        if player:consume_queued_attack(AttackInput.left) then
            return "sword_air_stab_left"
        elseif player:consume_queued_attack(AttackInput.right) then
            return "sword_air_stab_right"
        elseif player:consume_queued_attack(AttackInput.down) then
            return "sword_air_slam"
        end
    end

    return player:transition_to_any_movement_state(ground_anim, false, true)
end

function Sword:attack_input()
    local state = default_sword_transition(self.player)
    if state ~= nil then
        self.player.animation:change_state(state)
    end
end

function Sword:special_input() end