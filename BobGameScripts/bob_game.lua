--#build
--#priority 800

---@class bob_game : game
---@field public level level
---@field public options options
---@field private remaining_enemies_text string
---@field private wave_text string
---@field private active_enemies integer
---@field private time_until_next_spawn number
---@field private remaining_enemies integer
---@field private defeated_enemies integer
---@field private time_until_wave_start number
---@field private player_health_bar_sprite sprite
---@field private edge_flash number
---@field private menu menu
---@field private time_until_menu number
BobGame = Game.new()
BobGame.__index = BobGame

---@return bob_game
function BobGame.new()
    local self = setmetatable({}, BobGame)--[[@as bob_game]]
    self.is_active = true
    return self;
end

function BobGame:initialize()
    self.sprite_manager = sprite_manager
    self.font_manager = font_manager
    self:initialize_screen(sprite_manager, 0, 224, 0, 170, 128)
    self.font = self.font_manager:load("font")
    self.player_health_bar_sprite = self.sprite_manager:load("player_health_bar")
    self.input_1_text = "Attack"
    self.input_2_text = "Special"
    self.input_3_text = "Switch Weapon"
    self.debug_boxes = {}
    self.menu = Menu.new()
    self.menu:initialize(self)

    if get_history("bobgame\\target_fps") > 0 then
        self.target_time = 1000 / get_history("bobgame\\target_fps")
    elseif is_mod_swap_chain_enabled then
        self.target_time = 1000 / 60
    else
        -- 60 FPS is very inconsistent when using vanilla rendering, so we
        -- limit it to 30 by default. Swap Chain rendering can handle 60 fps
        -- well.
        self.target_time = 1000 / 30
    end

    self.options = Options.new()
    self.input.bindings = self.options.bindings
    self.history_folder = "bobgame\\"
end

function BobGame:initialize_level(level)
    self.level = level
    self.level.game = self
    self.level:initialize()
    self.time_until_next_spawn = self.level.wave.spawn_time
    self.remaining_enemies = self.level.wave.total_enemies
    self.defeated_enemies = 0
    self.active_enemies = 0
    self.time_until_wave_start = 0
    self.remaining_enemies_text = "0/" .. self.level.wave.total_enemies
    self.wave_text = "Wave 1"
    self.edge_flash = 0
    self.menu = nil
    self.time_until_menu = 0

    local player = Player.new()
    self:add_object(player)

    self.level:post_initialize()
end

---@return player?
function BobGame:get_nearest_player()
    return self:get_object_with_tag("player")--[[@as player]]
end

function BobGame:update()
    if self.menu ~= nil then
        self.menu:update()
        return
    end

    if self.time_until_menu > 0 then
        self.time_until_menu = self.time_until_menu - Time.delta_time
        if self.time_until_menu <= 0 then
            self:return_to_menu()
            return
        end
    end

    self.level:update()
    if self.menu ~= nil then
        return
    end
    local debug_boxes_to_remove = nil

    for i, v in ipairs(self.debug_boxes) do
        v[5] = v[5] + Time.delta_time
        if v[5] > 0.3 then
            if debug_boxes_to_remove == nil then
                debug_boxes_to_remove = {}
            end
            table.insert(debug_boxes_to_remove, 1, i)
        end
    end

    if debug_boxes_to_remove ~= nil then
        for i, v in ipairs(debug_boxes_to_remove) do
            table.remove(self.debug_boxes, v)
        end
    end

    self.edge_flash = self.edge_flash + Time.delta_time

    if self.time_until_wave_start > 0 then
        self.time_until_wave_start = self.time_until_wave_start - Time.delta_time
        if self.time_until_wave_start <= 0 then
            self:start_wave()
        end
    end

    self.time_until_next_spawn = self.time_until_next_spawn - Time.delta_time

    if self.active_enemies >= self.level.wave.max_active_enemies then
        return
    end

    if self.time_until_next_spawn <= 0 and self.remaining_enemies > 0 then
        self.level.wave:spawn_enemy()

        self.time_until_next_spawn = self.level.wave.spawn_time + (self.level.wave.spawn_time * math.random())
    end
end

function BobGame:return_to_menu()
    self:remove_all_objects()
    self.particles:destroy_all()
    self.level = nil
    self.menu = Menu.new()
    self.menu:initialize(self)
end

function BobGame:object_added(obj)
    if obj:has_tag("enemy") then
        if self.remaining_enemies == self.level.wave.total_enemies then
            self.wave_text = "Wave " .. self.level.wave.wave_number
            self.remaining_enemies_text = self.defeated_enemies .. "/" .. self.level.wave.total_enemies
        end

        self.active_enemies = self.active_enemies + 1
        self.remaining_enemies = self.remaining_enemies - 1
    end
end

function BobGame:object_removed(obj)
    if obj:has_tag("enemy") then
        self.active_enemies = self.active_enemies - 1
        self.defeated_enemies = self.defeated_enemies + 1
        self.remaining_enemies_text = self.defeated_enemies .. "/" .. self.level.wave.total_enemies

        if self.active_enemies == 0 and self.remaining_enemies == 0 then
            self:wave_complete()
        end
    elseif obj:has_tag("player") then
        self.time_until_menu = 5
    end
end

---@private
function BobGame:wave_complete()
    notify("Wave " .. self.level.wave.wave_number .. " complete!")
    self.level:wave_complete()
    self.time_until_wave_start = 5
end

function BobGame:start_wave()
    self.level:start_wave()
    notify("Wave " .. self.level.wave.wave_number)
    self.remaining_enemies = self.level.wave.total_enemies
    self.time_until_next_spawn = self.level.wave.spawn_time
    self.defeated_enemies = 0
    self.wave_text = "Wave " .. self.level.wave.wave_number
    self.remaining_enemies_text = "0/" .. self.level.wave.total_enemies
end

function BobGame:draw()
    if self.menu ~= nil then
        self.menu:draw()
        return
    end

    self.level:draw()
    self.particles:draw()

    if self.options.input_display then
        local x = self.screen.width - 36
        self:draw_input_press(InputType.move_left, x + 4, 8, 2, 2)
        self:draw_input_press(InputType.move_right, x + 12, 8, 2, 2)
        self:draw_input_press(InputType.move_forward, x + 8, 12, 2, 2)
        self:draw_input_press(InputType.move_backward, x + 8, 8, 2, 2)
        self:draw_input_press(InputType.jump, x + 8, 4, 18, 2)
        self:draw_input_press(InputType.input_1, x + 20, 8, 2, 2)
        self:draw_input_press(InputType.input_2, x + 24, 8, 2, 2)
        self:draw_input_press(InputType.input_3, x + 28, 8, 2, 2)
        self:draw_input_press(InputType.crouch, x, 4, 2, 2)
    end

    for i, v in ipairs(self.debug_boxes) do
        self.screen:draw_box_outline(v[1], v[2], v[1] + v[3], v[2] + v[4], block.colorred, Layers.ui)
    end

    self.screen:draw_text(self.font, self.wave_text, 5, self.screen.height - 11, Layers.ui, block.colorwhite)
    local mx, my = self.font:measure(self.remaining_enemies_text)
    self.screen:draw_text(self.font, self.remaining_enemies_text, self.screen.width - mx - 5, self.screen.height - 11, Layers.ui, block.colorwhite)

    self:draw_player_health()

    local player = self:get_nearest_player()
    if self.edge_flash % 0.2 > 0.1 and player ~= nil and (player.x < 20 or player.x > self.screen.width - 20) then
        local left_edge = false
        local right_edge = false
        for _, obj in ipairs(self.game_objects) do
            if obj:has_tag("enemy") then
                if obj.x < 0 and obj.x > -30 then
                    left_edge = true
                elseif obj.x > self.screen.width and obj.x < self.screen.width + 30 then
                    right_edge = true
                end
            end
        end

        if player.x < 20 and left_edge then
            self.screen:draw_box(0, self.level.ground_level, 0, self.level.ground_level + 10, block.colorred, Layers.ui)
        elseif player.x > self.screen.width - 20 and right_edge then
            self.screen:draw_box(self.screen.width - 1, self.level.ground_level, self.screen.width - 1, self.level.ground_level + 10, block.colorred, Layers.ui)
        end
    end
end

function BobGame:draw_player_health()
    local player = self:get_nearest_player()
    local health = 0
    local max_health = 100
    if player ~= nil then
        health = player.health
        max_health = player.max_health
    end

    local amount = health / max_health
    local total_width = 32
    local width = math.ceil((total_width - 2) * amount)
    self.screen:draw(self.player_health_bar_sprite, 0, 0, total_width, 5, 4, 4, Layers.ui)
    self.screen:draw(self.player_health_bar_sprite, 1, 6, width, 3, 5, 5, Layers.ui)
end

---@param input input_type
---@param x integer
---@param y integer
---@param w integer
---@param h integer
function BobGame:draw_input_press(input, x, y, w, h)
    local b
    if self.input:is_input_held(input) then
        b = block.colorwhite
    else
        b = block.colorblack
    end

    self.screen:draw_box(x, y, x + w - 1, y + h - 1, b, Layers.ui)
end

function BobGame:post_draw_object(obj)
    ---@cast obj +entity
    -- if obj.hitbox ~= nil and obj.hitbox.w > 0 and obj.hitbox.h > 0 then
    --     local hitbox = obj.hitbox
    --     self.screen:draw_box_outline(hitbox.x, hitbox.y, hitbox.x + hitbox.w, hitbox.y + hitbox.h, block.colorred, Layers.text)
    -- end
end

function BobGame:add_debug_box(min_x, min_y, max_x, max_y)
    --table.insert(self.debug_boxes, { min_x, min_y, max_x, max_y, 0 })
end

---@param area rectangle
---@param tags string[]?
---@return entity[]?
function BobGame:get_all_entities(area, tags)
    ---@type entity[]?
    local entities = nil

    for i, entity in ipairs(self.game_objects) do
        ---@cast entity +entity
        if entity:has_tag("entity") and (tags == nil or entity:has_any_tag(tags)) then
            if entity.hitbox:intersects(area) then
                if entities == nil then
                    entities = {}
                end
               table.insert(entities, entity)
            end
        end
    end

    return entities
end