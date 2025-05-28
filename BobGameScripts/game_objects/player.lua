--#build
--#priority 411

---@enum attack_input
AttackInput = {
    attack = 1,
    special = 2,
    up = 3,
    down = 4,
    left = 5,
    right = 6
}

---@class player : entity
---@field private weapons weapon[]
---@field private weapon_index integer
---@field private combo_type string?
---@field private input_dir integer
---@field private queued_attack input_type?
---@field private queued_attack_time number
---@field private queued_weapon_index integer?
Player = setmetatable({}, Entity)
Player.__index = Player

---@return player
function Player.new()
    local self = setmetatable(Entity.new(), Player)--[[@as player]]
    return self
end

function Player:initialize()
    Entity.initialize(self)
    self.x = self.game.screen.width / 2
    self.y = self.game.level.ground_level
    self.sprite = sprite_manager:load("player")
    self.animation_controller = AnimationController.new("unarmed_idle")

    local anim = self.animation_controller:add_state("unarmed_idle")
    anim.animation = Animation.new({
        [0.0] = AnimationFrame.new(Rectangle.new(0, 0, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil }),
        }),
    }, 0, LoopType.Loop)
    anim:add_transition(function (self)
        ---@cast self player
        if not self.grounded then
            return "unarmed_air"
        elseif self.vel_x > 0.01 or self.vel_x < -0.01 then
            return "unarmed_run"
        end
        return nil
    end)

    anim = self.animation_controller:add_state("unarmed_run")
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
            return "unarmed_air"
        elseif self.vel_x < 0.01 and self.vel_x > -0.01 then
            return "unarmed_idle"
        end
        return nil
    end)

    anim = self.animation_controller:add_state("unarmed_air")
    anim.animation = Animation.new({
        [0.0] = AnimationFrame.new(Rectangle.new(32, 0, 16, 16), {
            "enable_movement",
            EventTrigger.new("set_combo_type", { type = nil }),
        }),
    }, 0.0, LoopType.Loop)
    anim:add_transition(function (self)
        ---@cast self player
        if self.grounded and (self.vel_x > 0.01 or self.vel_x < -0.01) then
            return "unarmed_run"
        elseif self.grounded and self.vel_x < 0.01 and self.vel_x > -0.01 then
            return "unarmed_idle"
        end
        return nil
    end)

    self.animation = AnimationInstance.new(self, self.animation_controller)
    self:add_event_listeners()
    self.weapons = {
        Sword.new(self),
        Spear.new(self),
        Warhammer.new(self)
    }
    for _, weapon in ipairs(self.weapons) do
        weapon:initialize()
    end
    self.weapon_index = 1
    self.tags = { "entity", "player" }
    self.max_health = 100
    self.health = 100
    self.stagger_knockback_threshold_x = 100
    self.stagger_knockback_threshold_y = 100
    self.stagger_force_multiplier = 1
    self.stagger_recovery = 100
    self.hitbox_size_x = 4
    self.hitbox_size_y = 10
    self.hitbox_offset_x = -2
end

---@class combo_type_event_params
---@field public type string?

function Player:add_event_listeners()
    Entity.add_event_listeners(self)
    self.animation:add_event_listener("set_combo_type", self.set_combo_type_event)
end

function Player:update()
    Entity.update(self)
    self:update_input()

    if self.x < 0 then
        self.x = 0
        self.vel_x = 0
    elseif self.x > self.game.screen.width - 1 then
        -- subtract 1 so both pixels of the body are visible
        self.x = self.game.screen.width - 1
        self.vel_x = 0
    end
end

---@param params combo_type_event_params
function Player:set_combo_type_event(params)
    self.combo_type = params.type
end

function Player:get_attack_target_tag()
    return "enemy"
end

---@private
function Player:update_input()
    local input = self.game.input

    if input:is_input_pressed(InputType.input_3) then
        self:queue_next_weapon()
    end

    if input:is_input_pressed(InputType.input_2) then
        self.queued_attack = AttackInput.special
        self.queued_attack_time = 0
    end

    if input:is_input_pressed(InputType.input_1) then
        if input:is_input_held(InputType.move_left) then
            self.queued_attack = AttackInput.left
        elseif input:is_input_held(InputType.move_right) then
            self.queued_attack = AttackInput.right
        elseif input:is_input_held(InputType.move_backward) then
            self.queued_attack = AttackInput.down
        elseif input:is_input_held(InputType.move_forward) then
            self.queued_attack = AttackInput.up
        else
            self.queued_attack = AttackInput.attack
        end
        self.queued_attack_time = 0
    end

    if self.combo_type == nil then
        if self.queued_attack ~= nil then
            self.weapons[self.weapon_index]:attack_input()
        end
    end

    if self.can_move and self:is_weapon_switch_queued() then
        self:switch_to_queued_weapon()
    end

    if self.queued_attack ~= nil then
        self.queued_attack_time = self.queued_attack_time + Time.delta_time
        if self.queued_attack_time > 0.15 then
            self.queued_attack = nil
        end
    end

    self:update_movement_input()
end

---@param type attack_input
---@return boolean
function Player:consume_queued_attack(type)
    if self.queued_attack == type then
        self.queued_attack = nil
        return true
    end
    return false
end

function Player:update_movement_input()
    local input = self.game.input

    if not self.can_move then
        self.target_vel_x = 0
        self.input_dir = 0
        return
    end

    local speed = 50

    self.target_vel_x = 0
    local input_dir = 0
    if input:is_input_held(InputType.move_left) then
        self.target_vel_x = self.target_vel_x - speed
        self.dir = -1
        input_dir = input_dir - 1
    end

    if input:is_input_held(InputType.move_right) then
        self.target_vel_x = self.target_vel_x + speed
        self.dir = 1
        input_dir = input_dir + 1
    end
    self.input_dir = input_dir

    if input:is_input_held(InputType.jump) then
        if self.grounded and self.can_move then
            self:jump()
        end
    end
    
    if self.vel_x < self.target_vel_x then
        local acc
        if input_dir == 1 then
            acc = 700
        elseif input_dir == -1 then
            acc =  25
        else
            acc =  350
        end
        acc = acc * self.friction
        self.acceleration = acc
    elseif self.vel_x > self.target_vel_x then
        local acc
        if input_dir == -1 then
            acc = 700
        elseif input_dir == 1 then
            acc = 25
        else
            acc = 350
        end
        acc = acc * self.friction
        self.acceleration = acc
    end
end

function Player:jump()
    self:apply_force(0, 130)
end

---@private
---@param index integer
function Player:switch_weapon(index)
    if self.weapon_index ~= index then
        local current = self.weapons[self.weapon_index]
        local next = self.weapons[index]
        current:unqeuip()
        next:equip()
        self.weapon_index = index

        local state = self:transition_to_any_movement_state(self.grounded, true, false)
        if state == nil then
            state = next.idle_anim_state
        end

        -- We transfer time so the run animation doesn't reset
        -- when switching weapons
        local time = self.animation.time
        self.animation:change_state(state)
        self.animation.time = math.min(time, self.animation.length)
    end
end

function Player:queue_next_weapon()
    local index = self.queued_weapon_index
    if index == nil then
        index = self.weapon_index
    end

    local next_index = index + 1
    if next_index > #self.weapons then
        next_index = 1
    end

    self.queued_weapon_index = next_index
end

---@return boolean
function Player:is_weapon_switch_queued()
    return self.queued_weapon_index ~= nil and self.queued_weapon_index ~= self.weapon_index
end

function Player:switch_to_queued_weapon()
    self:switch_weapon(self.queued_weapon_index)
    self.queued_weapon_index = nil
end

---@param ground_anim boolean
---@param can_idle boolean
---@param anim_must_finish boolean
---@return string?
function Player:transition_to_any_movement_state(ground_anim, can_idle, anim_must_finish)
    if anim_must_finish and not self.animation.finished then
        return nil
    end

    local weapon = self.weapons[self.weapon_index]

    if (not ground_anim) and self.grounded then
        return weapon.idle_anim_state
    elseif ground_anim and not self.grounded then
        return weapon.air_anim_state
    elseif self.can_move and (self.input_dir == -1 or self.input_dir == 1) and math.abs(self.vel_x) > 0.01 then
        if ground_anim then
            return weapon.run_anim_state
        else
            return weapon.air_anim_state
        end
    elseif can_idle then
        if ground_anim then
            return weapon.idle_anim_state
        else
            return weapon.air_anim_state
        end
    end
    return nil
end

function Player:draw()
    local x = math.floor(self.x + 0.5);
    local y = math.floor(self.y + 0.5);
    local rect = self.animation:get_current_frame().src
    local weapon_sprite = self.weapons[self.weapon_index].sprite

    local offset_x
    local offset_y
    local flip = false
    if self.dir == -1 then
        if rect.w == 32 then
            offset_x = -15
        else
            offset_x = -11
        end
        flip = true
    else
        if rect.w == 32 then
            offset_x = -16
        else
            offset_x = -4
        end
    end

    if rect.h == 32 then
        offset_y = -16
    else
        offset_y = 0
    end

    local b = nil
    if self.time_since_damaged < 0.1 then
        b = block.colorred
    end
    self.game.screen:draw(self.sprite, rect.x, rect.y, rect.w, rect.h, x + offset_x, y + offset_y, Layers.player, flip, false, b)
    self.game.screen:draw(weapon_sprite, rect.x, rect.y, rect.w, rect.h, x + offset_x, y + offset_y, Layers.player_weapon, flip, false, b)
end