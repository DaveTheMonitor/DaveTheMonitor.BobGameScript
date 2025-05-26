--#build
--#priority 404

---@class warhammer : weapon
Warhammer = Weapon.new()
Warhammer.__index = Warhammer
Warhammer.idle_anim_state = "warhammer_idle"
Warhammer.run_anim_state = "warhammer_run"
Warhammer.air_anim_state = "warhammer_air"

---@param player player
---@return warhammer
function Warhammer.new(player)
    local self = setmetatable({}, Warhammer)--[[@as warhammer]]
    self.player = player
    return self
end

function Warhammer:initialize()
    self.sprite = sprite_manager:load("player_warhammer")
    local anim_controller = self.player.animation_controller

    local anim = anim_controller:add_state("warhammer_idle")
    anim.animation = Animation.new({
        [0.0] = AnimationFrame.new(Rectangle.new(0, 128, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil }),
        }),
    }, 0, LoopType.Loop)
    anim:add_transition(function (self)
        ---@cast self player
        if not self.grounded then
            return Warhammer.air_anim_state
        elseif self.vel_x > 0.01 or self.vel_x < -0.01 then
            return Warhammer.run_anim_state
        end
        return nil
    end)

    anim = anim_controller:add_state("warhammer_run")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(16, 128, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil }),
        }),
        [0.14] = AnimationFrame.new(Rectangle.new(32, 128, 16, 16)),
        [0.28] = AnimationFrame.new(Rectangle.new(48, 128, 16, 16)),
        [0.42] = AnimationFrame.new(Rectangle.new(64, 128, 16, 16)),
    }, 0.56, LoopType.Loop)
    anim:add_transition(function (self)
        ---@cast self player
        if not self.grounded then
            return Warhammer.air_anim_state
        elseif self.vel_x < 0.01 and self.vel_x > -0.01 then
            return Warhammer.idle_anim_state
        end
        return nil
    end)

    anim = anim_controller:add_state("warhammer_air")
    anim.animation = Animation.new({
        [0.0] = AnimationFrame.new(Rectangle.new(32, 128, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil }),
        }),
    }, 0.0, LoopType.Loop)
    anim:add_transition(function (self)
        ---@cast self player
        if self.grounded and (self.vel_x > 0.01 or self.vel_x < -0.01) then
            return Warhammer.run_anim_state
        elseif self.grounded and self.vel_x < 0.01 and self.vel_x > -0.01 then
            return Warhammer.idle_anim_state
        end
        return nil
    end)

    anim = anim_controller:add_state("warhammer_ground_1")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(16, 144, 16, 16), {
            "disable_movement",
            EventTrigger.new("set_combo_type", { type = "warhammer" })
        }),
        [0.12] = AnimationFrame.new(Rectangle.new(32, 144, 16, 16)),
        [0.28] = AnimationFrame.new(Rectangle.new(48, 144, 16, 16), {
            EventTrigger.new("attack", { damage = 30, box = Rectangle.new(0, 0, 14, 16), stagger = StaggerInfo.new(100, 30, 1), on_hit = create_impact_applier(20) }),
            EventTrigger.new("apply_force", { x = 40, directional = true })
        }),
        [0.32] = AnimationFrame.new(Rectangle.new(64, 144, 16, 16)),
        [0.36] = AnimationFrame.new(Rectangle.new(80, 144, 16, 16)),
        [0.40] = AnimationFrame.new(Rectangle.new(96, 144, 16, 16)),
        [0.68] = AnimationFrame.new(Rectangle.new(96, 144, 16, 16), {
            "enable_movement"
        }),
    }, 0.68, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            if self:consume_queued_attack(AttackInput.attack) or self:consume_queued_attack(AttackInput.down) then
                return "warhammer_ground_2"
            end
        end

        if self.animation.total_time > 1.08 then
            return "warhammer_ground_end_1"
        end
        
        if self.animation.finished then
            return default_warhammer_transition(self, true)
        end
    end)

    anim = anim_controller:add_state("warhammer_ground_2")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(48, 160, 16, 16), {
            "disable_movement",
            EventTrigger.new("set_combo_type", { type = "warhammer" })
        }),
        [0.12] = AnimationFrame.new(Rectangle.new(64, 160, 16, 16)),
        [0.24] = AnimationFrame.new(Rectangle.new(80, 160, 16, 16), {
            EventTrigger.new("attack", { damage = 10, box = Rectangle.new(-4, 0, 14, 12), stagger = StaggerInfo.new(-70, 20, 1) }),
            EventTrigger.new("apply_force", { x = -40, directional = true, absolute = true }),
        }),
        [0.32] = AnimationFrame.new(Rectangle.new(96, 160, 32, 16), {
            EventTrigger.new("attack", { damage = 10, box = Rectangle.new(-6, 0, 12, 12), stagger = StaggerInfo.new(-70, 20, 1) }),
            EventTrigger.new("apply_force", { x = -40, directional = true, absolute = true }),
        }),
        [0.40] = AnimationFrame.new(Rectangle.new(0, 176, 32, 16), {
            EventTrigger.new("attack", { damage = 10, box = Rectangle.new(-10, 0, 18, 12), stagger = StaggerInfo.new(70, 20, 1) }),
            EventTrigger.new("apply_force", { x = 60, directional = true, absolute = true }),
        }),
        [0.48] = AnimationFrame.new(Rectangle.new(32, 176, 16, 16), {
            EventTrigger.new("attack", { damage = 10, box = Rectangle.new(-4, 0, 18, 12), stagger = StaggerInfo.new(70, 20, 1) }),
            EventTrigger.new("apply_force", { x = 60, directional = true, absolute = true }),
        }),
        [0.56] = AnimationFrame.new(Rectangle.new(48, 176, 16, 16)),
        [0.68] = AnimationFrame.new(Rectangle.new(64, 176, 16, 16)),
        [0.80] = AnimationFrame.new(Rectangle.new(80, 176, 16, 16), {
            "enable_movement"
        }),
    }, 0.92, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            if self:consume_queued_attack(AttackInput.attack) or self:consume_queued_attack(AttackInput.down) then
                return "warhammer_ground_3"
            end
        end

        if self.animation.total_time > 1.32 then
            return "warhammer_ground_end_2"
        end
        
        if self.animation.finished then
            return default_warhammer_transition(self, true)
        end
    end)

    anim = anim_controller:add_state("warhammer_ground_3")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(0, 192, 16, 16), {
            "disable_movement",
            EventTrigger.new("set_combo_type", { type = "warhammer" })
        }),
        [0.08] = AnimationFrame.new(Rectangle.new(16, 192, 16, 16)),
        [0.16] = AnimationFrame.new(Rectangle.new(32, 192, 16, 16), {
            EventTrigger.new("attack", { damage = 30, box = Rectangle.new(0, 0, 14, 16), stagger = StaggerInfo.new(100, 30, 1), on_hit = create_impact_applier(20) }),
            EventTrigger.new("apply_force", { x = 50, directional = true }),
            EventTrigger.new("callback", { callback = create_hammer_wave_spawner(15, 2, 80, 8, 0.3) }),
        }),
        [0.20] = AnimationFrame.new(Rectangle.new(48, 192, 16, 16)),
        [0.24] = AnimationFrame.new(Rectangle.new(64, 192, 16, 16)),
        [0.28] = AnimationFrame.new(Rectangle.new(80, 192, 16, 16)),
        [0.60] = AnimationFrame.new(Rectangle.new(80, 192, 16, 16), {
            "enable_movement"
        }),
    }, 0.60, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.total_time > 1.00 then
            return "warhammer_ground_end_3"
        end
        
        if self.animation.finished then
            return default_warhammer_transition(self, true)
        end
    end)

    anim = anim_controller:add_state("warhammer_uppercut")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(16, 192, 16, 16), {
            "disable_movement",
            EventTrigger.new("set_combo_type", { type = "warhammer" })
        }),
        [0.10] = AnimationFrame.new(Rectangle.new(0, 208, 16, 16)),
        [0.20] = AnimationFrame.new(Rectangle.new(16, 208, 32, 16), {
            EventTrigger.new("apply_force", { x = 40, directional = true }),
        }),
        [0.26] = AnimationFrame.new(Rectangle.new(48, 208, 32, 16)),
        [0.42] = AnimationFrame.new(Rectangle.new(80, 208, 32, 16), {
            EventTrigger.new("attack", { damage = 10, box = Rectangle.new(-12, 0, 10, 16), stagger = StaggerInfo.new(100, 20, 1) }),
        }),
        [0.46] = AnimationFrame.new(Rectangle.new(96, 176, 32, 16), {
            EventTrigger.new("apply_force", { x = 60, directional = true }),
        }),
        [0.50] = AnimationFrame.new(Rectangle.new(112, 208, 16, 16), {
            EventTrigger.new("attack", { damage = 30, box = Rectangle.new(-2, 0, 16, 16), stagger = StaggerInfo.new(80, 160, -1), on_hit = create_impact_applier(30) }),
            EventTrigger.new("callback", { callback = create_hammer_wave_spawner(10, 2, 80, 12, 0.3) }),
        }),
        [0.54] = AnimationFrame.new(Rectangle.new(0, 224, 16, 16)),
        [0.58] = AnimationFrame.new(Rectangle.new(16, 224, 32, 16)),
        [0.64] = AnimationFrame.new(Rectangle.new(48, 224, 32, 16)),
        [0.80] = AnimationFrame.new(Rectangle.new(48, 224, 32, 16), {
            "enable_movement"
        }),
    }, 0.80, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.total_time > 1.10 then
            return "warhammer_ground_end_uppercut"
        end
        
        if self.animation.finished then
            return default_warhammer_transition(self, true)
        end
    end)

    anim = anim_controller:add_state("warhammer_ground_stab")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(16, 144, 16, 16), {
            "disable_movement",
            EventTrigger.new("set_combo_type", { type = "warhammer" }),
            EventTrigger.new("set_friction", { friction = 0.2 }),
            EventTrigger.new("apply_force", { x = 90, y = 85, directional = true, absolute = true })
        }),
        -- Transition doesn't work if the animation is 0 seconds
    }, 0.04, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        -- this delay is required otherwise the grounded transition activates instantly
        if self.animation.total_time > 0.1 and self.grounded then
            return "warhammer_ground_stab_landing"
        end

        -- shouldn't happen but just in case
        if self.animation.total_time > 2 then
            return default_warhammer_transition(self, true)
        end
    end)

    anim = anim_controller:add_state("warhammer_ground_stab_landing")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(48, 144, 16, 16), {
            EventTrigger.new("attack", { damage = 30, box = Rectangle.new(-4, 0, 18, 16), stagger = StaggerInfo.new(100, 30, 1), on_hit = create_impact_applier(20) }),
            EventTrigger.new("apply_force", { x = 20, directional = true, absolute = true }),
            EventTrigger.new("set_friction", { friction = 1 }),
            EventTrigger.new("callback", { callback = create_hammer_wave_spawner(10, 2, 80, 8, 0.3) }),
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(64, 144, 16, 16)),
        [0.08] = AnimationFrame.new(Rectangle.new(80, 144, 16, 16)),
        [0.12] = AnimationFrame.new(Rectangle.new(96, 144, 16, 16)),
        [0.40] = AnimationFrame.new(Rectangle.new(96, 144, 16, 16), {
            "enable_movement"
        }),
    }, 0.40, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            if self:consume_queued_attack(AttackInput.attack) or self:consume_queued_attack(AttackInput.down) then
                return "warhammer_ground_2"
            end
        end

        if self.animation.total_time > 1.08 then
            return "warhammer_ground_end_1"
        end
        
        if self.animation.finished then
            return default_warhammer_transition(self, true)
        end
    end)

    anim = anim_controller:add_state("warhammer_air_stab_right")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(16, 240, 16, 16), {
            "disable_movement",
            "disable_gravity",
            EventTrigger.new("set_combo_type", { type = "warhammer" }),
            EventTrigger.new("apply_force", { y = 10, directional = true, absolute = true }),
        }),
        [0.06] = AnimationFrame.new(Rectangle.new(32, 240, 16, 16)),
        [0.12] = AnimationFrame.new(Rectangle.new(48, 240, 16, 16)),
        [0.16] = AnimationFrame.new(Rectangle.new(64, 240, 16, 16), {
            EventTrigger.new("attack", { damage = 10, box = Rectangle.new(-6, 0, 16, 16), stagger = StaggerInfo.new(100, 0, -1) }),
            EventTrigger.new("apply_force", { x = -40, directional = true, absolute = true }),
        }),
        [0.20] = AnimationFrame.new(Rectangle.new(80, 240, 16, 16), {
            EventTrigger.new("set_dir", { dir = -1 }),
            EventTrigger.new("attack", { damage = 10, box = Rectangle.new(-4, 0, 20, 16) }),
            EventTrigger.new("apply_force", { x = 20, directional = true, absolute = true }),
        }),
        [0.26] = AnimationFrame.new(Rectangle.new(96, 240, 16, 16), {
            EventTrigger.new("attack", { damage = 10, box = Rectangle.new(-4, 0, 20, 16), stagger = StaggerInfo.new(10, 0, 1) }),
        }),
        [0.32] = AnimationFrame.new(Rectangle.new(112, 240, 16, 16)),
        [0.38] = AnimationFrame.new(Rectangle.new(32, 128, 16, 16), {
            "enable_gravity"
        }),
    }, 0.38, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.grounded then
            return self:transition_to_any_movement_state(false, true, false)
        end

        if self.animation.finished then
            local state = default_warhammer_transition(self, false)
            -- we don't allow chaining stabs in the same direction
            if state ~= "warhammer_air_stab_right" and state ~= nil then
                return state
            end
        end
    end)

    anim = anim_controller:add_state("warhammer_air_stab_left")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(16, 240, 16, 16), {
            "disable_movement",
            "disable_gravity",
            EventTrigger.new("set_combo_type", { type = "warhammer" }),
            EventTrigger.new("apply_force", { y = 10, directional = true, absolute = true }),
        }),
        [0.06] = AnimationFrame.new(Rectangle.new(32, 240, 16, 16)),
        [0.12] = AnimationFrame.new(Rectangle.new(48, 240, 16, 16)),
        [0.16] = AnimationFrame.new(Rectangle.new(64, 240, 16, 16), {
            EventTrigger.new("attack", { damage = 10, box = Rectangle.new(-6, 0, 16, 16), stagger = StaggerInfo.new(100, 0, -1) }),
            EventTrigger.new("apply_force", { x = -40, directional = true, absolute = true }),
        }),
        [0.20] = AnimationFrame.new(Rectangle.new(80, 240, 16, 16), {
            EventTrigger.new("set_dir", { dir = 1 }),
            EventTrigger.new("attack", { damage = 10, box = Rectangle.new(-4, 0, 20, 16) }),
            EventTrigger.new("apply_force", { x = 20, directional = true, absolute = true }),
        }),
        [0.26] = AnimationFrame.new(Rectangle.new(96, 240, 16, 16), {
            EventTrigger.new("attack", { damage = 10, box = Rectangle.new(-4, 0, 20, 16), stagger = StaggerInfo.new(10, 0, 1) }),
        }),
        [0.32] = AnimationFrame.new(Rectangle.new(112, 240, 16, 16)),
        [0.38] = AnimationFrame.new(Rectangle.new(32, 128, 16, 16), {
            "enable_gravity"
        }),
    }, 0.38, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.grounded then
            return self:transition_to_any_movement_state(false, true, false)
        end

        if self.animation.finished then
            local state = default_warhammer_transition(self, false)
            -- we don't allow chaining stabs in the same direction
            if state ~= "warhammer_air_stab_left" and state ~= nil then
                return state
            end
        end
    end)

    anim = anim_controller:add_state("warhammer_air_slam")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(0, 240, 16, 16), {
            "disable_movement",
            EventTrigger.new("set_combo_type", { type = "warhammer" }),
            EventTrigger.new("apply_force", { y = 100, absolute = true }),
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(0, 240, 16, 16))
    }, 0.04, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.grounded then
            return "warhammer_air_slam_landing"
        end
    end)

    anim = anim_controller:add_state("warhammer_air_slam_landing")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(48, 144, 16, 16), {
            EventTrigger.new("attack", { damage = 10, box = Rectangle.new(-2, 0, 18, 16), stagger = StaggerInfo.new(60, 30, 1), on_hit = create_impact_applier(20) }),
            EventTrigger.new("attack", { damage = 10, box = Rectangle.new(-16, 0, 14, 16), stagger = StaggerInfo.new(60, 30, -1), on_hit = create_impact_applier(20) }),
            EventTrigger.new("attack", { damage = 15, box = Rectangle.new(2, 0, 12, 16), stagger = StaggerInfo.new(100, 30, 1), on_hit = create_impact_applier(20) }),
            EventTrigger.new("callback", { callback = create_hammer_wave_spawner(10, 4, 80, 8, 0.3) }),
            EventTrigger.new("callback", { callback = create_hammer_wave_spawner(10, 4, -80, -8, 0.3) }),
        }),
        [0.04] = AnimationFrame.new(Rectangle.new(64, 144, 16, 16)),
        [0.08] = AnimationFrame.new(Rectangle.new(80, 144, 16, 16)),
        [0.12] = AnimationFrame.new(Rectangle.new(96, 144, 16, 16)),
        [0.40] = AnimationFrame.new(Rectangle.new(96, 144, 16, 16), {
            "enable_movement"
        }),
    }, 0.20, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            if self:consume_queued_attack(AttackInput.attack) or self:consume_queued_attack(AttackInput.down) then
                return "warhammer_ground_2"
            end
        end

        if self.animation.total_time > 1.08 then
            return "warhammer_ground_end_1"
        end
        
        if self.animation.finished then
            return default_warhammer_transition(self, true)
        end
    end)

    anim = anim_controller:add_state("spear_air_down_stab_miss")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(160, 96, 16, 16)),
        [0.70] = AnimationFrame.new(Rectangle.new(176, 96, 16, 16)),
        [0.82] = AnimationFrame.new(Rectangle.new(192, 96, 16, 16), {
            "enable_movement"
        }),
        [0.94] = AnimationFrame.new(Rectangle.new(208, 96, 16, 16)),
        [1.06] = AnimationFrame.new(Rectangle.new(208, 32, 16, 16)),
    }, 1.18, LoopType.Hold)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.time >= 0.82 then
            return self:transition_to_any_movement_state(true, true, false)
        end
    end)

    anim = anim_controller:add_state("warhammer_ground_end_1")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(0, 160, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil })
        }),
        [0.10] = AnimationFrame.new(Rectangle.new(16, 160, 16, 16)),
        [0.20] = AnimationFrame.new(Rectangle.new(32, 160, 16, 16)),
    }, 0.25, LoopType.Once)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            return Warhammer.idle_anim_state
        end

        return self:transition_to_any_movement_state(true, false, false)
    end)

    anim = anim_controller:add_state("warhammer_ground_end_2")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(64, 176, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil })
        }),
        [0.10] = AnimationFrame.new(Rectangle.new(32, 160, 16, 16)),
    }, 0.15, LoopType.Once)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            return Warhammer.idle_anim_state
        end

        return self:transition_to_any_movement_state(true, false, false)
    end)

    anim = anim_controller:add_state("warhammer_ground_end_3")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(96, 192, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil })
        }),
        [0.10] = AnimationFrame.new(Rectangle.new(16, 160, 16, 16)),
        [0.20] = AnimationFrame.new(Rectangle.new(32, 160, 16, 16)),
    }, 0.25, LoopType.Once)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            return Warhammer.idle_anim_state
        end

        return self:transition_to_any_movement_state(true, false, false)
    end)

    anim = anim_controller:add_state("warhammer_ground_end_uppercut")
    anim.animation = Animation.new({
        [0.00] = AnimationFrame.new(Rectangle.new(80, 224, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil })
        }),
        [0.10] = AnimationFrame.new(Rectangle.new(32, 144, 16, 16)),
    }, 0.20, LoopType.Once)
    anim:add_transition(function (self)
        ---@cast self player
        if self.animation.finished then
            return Warhammer.idle_anim_state
        end

        return self:transition_to_any_movement_state(true, false, false)
    end)
end

---@param player player
---@param ground_anim boolean
---@return string? state
function default_warhammer_transition(player, ground_anim)
    if player:is_weapon_switch_queued() then
        return player:transition_to_any_movement_state(ground_anim, true, true)
    end

    if player.grounded then
        if player:consume_queued_attack(AttackInput.up) then
            return "warhammer_uppercut"
        elseif player:consume_queued_attack(AttackInput.left) or player:consume_queued_attack(AttackInput.right) then
            return "warhammer_ground_stab"
        elseif player:consume_queued_attack(AttackInput.attack) or player:consume_queued_attack(AttackInput.down) then
            return "warhammer_ground_1"
        end
    else
        if player:consume_queued_attack(AttackInput.left) then
            return "warhammer_air_stab_left"
        elseif player:consume_queued_attack(AttackInput.right) then
            return "warhammer_air_stab_right"
        elseif player:consume_queued_attack(AttackInput.down) then
            return "warhammer_air_slam"
        end
    end

    return player:transition_to_any_movement_state(ground_anim, false, true)
end

function Warhammer:attack_input()
    local state = default_warhammer_transition(self.player, false)
    if state ~= nil then
        self.player.animation:change_state(state)
    end
end
function Warhammer:special_input() end

---@param damage number
---@return fun(self: player, targets: entity[])
function create_impact_applier(damage)
    ---@param self player
    ---@param targets entity[]
    local applier = function(self, targets)
        for _, target in ipairs(targets) do
            target:apply_damage_on_impact(damage, "enemy", self)
        end
    end

    return applier
end

---@param damage number
---@param pierce integer
---@param vel number
---@param offset number
---@param duration number
---@return fun(self: player)
function create_hammer_wave_spawner(damage, pierce, vel, offset, duration)
    ---@param self player
    local spawner = function(self)
        local vel = vel
        local offset = offset
        if self.dir == -1 then
            offset = -offset
            vel = -vel
        end

        self.game:add_object(HammerWave.new(self.x + offset, self.y, vel, pierce, damage, duration))
    end

    return spawner
end