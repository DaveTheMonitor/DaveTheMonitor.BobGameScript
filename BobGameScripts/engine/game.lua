--#build
--#priority 199

---@class game
---@field public screen screen
---@field public screen_distance integer
---@field public input input_manager
---@field public is_active boolean
---@field protected sprite_manager sprite_manager
---@field protected target_time number
---@field protected input_1_text string
---@field protected input_2_text string
---@field protected input_3_text string
---@field private prev_input_1_text string
---@field private prev_input_2_text string
---@field private prev_input_3_text string
---@field private handle integer
---@field private handle_history string
---@field protected game_objects game_object[]
---@field private game_objects_to_remove game_object[]
---@field protected game_objects_count integer
---@field private game_objects_to_remove_count integer
---@field private updating_objects boolean
---@field public particles particle_manager
Game = {}
Game.__index = Game

function Game.new()
    local self = setmetatable({}, Game)
    self.is_active = true
    return self
end

function Game:run()
    self:initialize_base()

    if is_mod_input_enabled then
        self:clear_buttons()
    end

    timer_reset()
    timer_start()
    local accumulator = 0
    local frame_start = get_timer()
    local update_rate = 1 / 60
    while self.is_active do
        -- Input requires some wierd update logic
        -- is_input_pressed should return true of the first frame an input is pressed
        -- If we update input only once per loop, then multiple frames may get true for
        -- is_input_pressed
        -- If we update input once per step, then any calls after the first in the same
        -- frame will be ignore input as it will think nothing is pressed
        -- To avoid this, input has two update steps: pump, advance
        -- Pumping pumps input events from the mod (or queries player movement for vanilla)
        -- We pump once per frame
        -- Advance increments the time for every held input
        -- We advance every step
        -- Doing these separately allows us to properly register "first frame" inputs, while
        -- not ignoring inputs on subsequent steps
        local screen = self.screen
        self.input:pump(screen.x + (screen.width / 2), screen.y + (screen.height / 2) - 1.5, screen.z + self.screen_distance)

        local now = get_timer()
        local delta = (now - frame_start) / 1000
        frame_start = now
        accumulator = accumulator + delta
        Time.delta_time = update_rate
        while accumulator > update_rate do
            self:update_base()
            if not self.is_active then
                break
            end
            self.input:advance()
            accumulator = accumulator - (update_rate)
            updated = true
            Time.total_time = Time.total_time + Time.delta_time
        end
        if not self.is_active then
            break
        end

        self:draw_base()
        self:update_buttons()
        
        -- Allows force stopping the game by clearing the history
        if get_sys_history(self.handle_history) == 0 then
            self.is_active = false
            break
        end
        
        local t = get_timer() - frame_start
        report_frame_time(t)
        if t < self.target_time then
            local wait_time = math.floor(self.target_time - t)
            wait(wait_time)
            -- Game was probably paused, reset the timer to avoid
            -- accumulated updates
            -- Pausing the game causes wait to only end when unpaused,
            -- but the timer continues ticking. So if the time that we
            -- are supposed to wait and the time we actually waited are
            -- significantly different, the game was probably paused.
            -- A false positive may be possible when other scripts are
            -- running since they might cause the game to take longer to
            -- end the wait
            if (get_timer() - frame_start) - t > wait_time + 200 then
                timer_reset()
                timer_start()
                accumulator = 0
                frame_start = 0
            end
        end
    end
    
    self:cleanup()
end

function Game:initialize() end
function Game:update() end
function Game:draw() end
---@param object game_object
function Game:post_draw_object(object) end
---@param object game_object
function Game:object_removed(object) end
---@param object game_object
function Game:object_added(object) end

---@private
function Game:initialize_base()
    self.handle = math.random(1000000000)
    self.handle_history = "game_" .. self.handle
    set_sys_history(self.handle_history, 1)
    self.input = InputManager.new()
    self.input:unhook_events()
    if is_mod_input_enabled then
        -- pump twice to reset inputs
        self.input:pump_mod()
        self.input:pump_mod()
        set_flying()
    end
    self.game_objects = {}
    self.game_objects_to_remove = {}
    self.game_objects_count = 0
    self.game_objects_to_remove_count = 0
    self.particles = ParticleManager.new(self, 100)
    self.screen_distance = 0
    self:initialize()
    Time.delta_time = (1000 / self.target_time) / 1000
    if self.screen_distance == 0 then
        self.screen_distance = get_history("bobgame\\screen_distance")
        if self.screen_distance == 0 then
            self.screen_distance = 92
        end
    end

    remove_zone("GameControl")
    local screen = self.screen
    add_zone("GameControl", screen.x - 512, screen.y - 512, screen.z - 512, screen.x + 512, screen.y + 512, screen.z + 512, false)
    set_zone_props("GameControl", 0, 2, 0.05, 0.01, 1, 0)
end

---@private
function Game:update_base()
    self:update()
    self.particles:update()

    self.updating_objects = true
    -- While loop instead of for loop here so we also update objects
    -- added during the loop.
    local i = 1
    local next = self.game_objects[i]
    while next ~= nil do
        next:update()
        i = i + 1
        next = self.game_objects[i]
    end
    self.updating_objects = false

    if self.game_objects_to_remove_count > 0 then
        for index, value in ipairs(self.game_objects_to_remove) do
            self.game_objects_to_remove[index] = nil
            self:remove_object(value)
        end
        self.game_objects_to_remove_count = 0
    end
end

---@private
function Game:draw_base()
    self.screen:begin()
    self:draw()

    for i = 1, self.game_objects_count, 1 do
        self.game_objects[i]:draw()
        self:post_draw_object(self.game_objects[i])
    end
    self.screen:present()
end

---@param object game_object
function Game:add_object(object)
    table.insert(self.game_objects, object)
    self.game_objects_count = self.game_objects_count + 1
    object.game = self
    object:initialize()
    self:object_added(object)
end

---@param object game_object
function Game:remove_object(object)
    -- Objects cannot be removed while we're looping over them, so
    -- we queue the removal to execute once we're done looping,
    -- otherwise we remove them immediately.
    if self.updating_objects then
        table.insert(self.game_objects_to_remove, object)
        self.game_objects_to_remove_count = self.game_objects_to_remove_count + 1
    else
        local i = 0
        for index, value in ipairs(self.game_objects) do
            if value == object then
                i = index
                object = value
                break
            end
        end
        if i > 0 then
            table.remove(self.game_objects, i)
            self.game_objects_count = self.game_objects_count - 1
            object:unload()
            self:object_removed(object)
        end
    end
end

function Game:remove_all_objects()
    if self.updating_objects then
        for index, value in ipairs(self.game_objects) do
            self.game_objects_to_remove(value)
        end
    else
        while self.game_objects_count > 0 do
            local object = self.game_objects[1]
            table.remove(self.game_objects, 1)
            self.game_objects_count = self.game_objects_count - 1
            object:unload()
            self:object_removed(object)
        end
    end
end

---@param predicate fun(game_object: game_object): boolean
---@return game_object?
function Game:get_object(predicate)
    local count = self.game_objects_count
    for i = 1, count, 1 do
        local object = self.game_objects[i]
        if predicate(object) then
            return object
        end
    end
    return nil
end

---@param tag string
---@return game_object?
function Game:get_object_with_tag(tag)
    local count = self.game_objects_count
    for i = 1, count, 1 do
        local object = self.game_objects[i]
        if object:has_tag(tag) then
            return object
        end
    end
    return nil
end

---@param tags string[]
---@return game_object?
function Game:get_object_with_all_tags(tags)
    local count = self.game_objects_count
    for i = 1, count, 1 do
        local object = self.game_objects[i]
        local has_all = true
        for j, tag in ipairs(tags) do
            if not object:has_tag(tag) then
                has_all = false
                break
            end
        end
        if has_all then
            return object
        end
    end
    return nil
end

---@param tags string[]
---@return game_object?
function Game:get_object_with_any_tag(tags)
    local count = self.game_objects_count
    for i = 1, count, 1 do
        local object = self.game_objects[i]
        for j, tag in ipairs(tags) do
            if object:has_tag(tag) then
                return object
            end
        end
    end
    return nil
end

---@param x number
---@param y number
---@param w number
---@param h number
---@return game_object[]
function Game:get_all_objects_area(x, y, w, h)
    local objects = {}

    local count = self.game_objects_count
    for i = 1, count, 1 do
        local object = self.game_objects[i]
        if object.x >= x and object.x <= x + w and object.y >= y and object.y <= y + h then
            table.insert(objects, object)
        end
    end

    return objects
end

---@param predicate fun(obj: game_object): boolean
---@return game_object[]
function Game:get_all_objects(predicate)
    local objects = {}

    local count = self.game_objects_count
    for i = 1, count, 1 do
        local object = self.game_objects[i]
        if predicate(object) then
            table.insert(objects, object)
        end
    end

    return objects
end

---@protected
---@param sprite_manager sprite_manager
---@param x integer
---@param y integer
---@param z integer
---@param width integer
---@param height integer
function Game:initialize_screen(sprite_manager, x, y, z, width, height)
    local screen = Screen.new(sprite_manager, x, y, z, width, height)
    self.screen = screen
    set_region(x, y, z, x + width, y + height, z, block.none, 100, 0)
end

---@private
function Game:update_buttons()
    if is_mod_input_enabled then
        self.prev_input_1_text = nil
        self.prev_input_2_text = nil
        self.prev_input_3_text = nil
        self:clear_buttons()
        return
    end

    local y = 50
    if self.input_1_text ~= self.prev_input_1_text then
        set_event_button_script("ButtonX", "bobgame\\input_1_lua", self.input_1_text, 50, 50, 1)
        self.prev_input_1_text = self.input_1_text
        y = y + 25
    end
    if self.input_2_text ~= self.prev_input_2_text then
        set_event_button_script("ButtonB", "bobgame\\input_2_lua", self.input_2_text, 50, 75, 1)
        self.prev_input_2_text = self.input_2_text
        y = y + 25
    end
    if self.input_3_text ~= self.prev_input_3_text then
        set_event_button_script("ButtonY", "bobgame\\input_3_lua", self.input_3_text, 50, 100, 1)
        self.prev_input_3_text = self.input_3_text
        y = y + 25
    end
end

---@private
function Game:cleanup()
    InputManager:unhook_events()
    set_sys_history(self.handle_history, 0)
    remove_zone("GameControl")
    if not is_mod_input_enabled then
        self:clear_buttons()
    end
    if is_mod_swap_chain_enabled then
        swap_chain_dispose()
    else
        local screen = self.screen
        set_region(screen.x, screen.y, screen.z, screen.x + screen.width, screen.y + screen.height, screen.z, block.none, 100, 0)
    end
end

---@private
function Game:clear_buttons()
    set_event_button_script("ButtonX", nil, nil, 0, 0, 1)
    set_event_button_script("ButtonY", nil, nil, 0, 0, 1)
    set_event_button_script("ButtonB", nil, nil, 0, 0, 1)
end