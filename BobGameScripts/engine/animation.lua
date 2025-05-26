--#build
--#priority 130

---@enum loop_type
LoopType = {
    Once = 1,
    Loop = 2,
    Hold = 3
}

---@class animation_controller
---@field private states { [string]: animation_state }
---@field public default_state string
AnimationController = {}
AnimationController.__index = AnimationController

---@return animation_controller
function AnimationController.new()
    local self = setmetatable({}, AnimationController)--[[@as animation_controller]]
    self.states = {}
    self.default_state = nil
    return self
end

---@param name string
---@return animation_state?
function AnimationController:get_state(name)
    for key, value in pairs(self.states) do
        if key == name then
            return value
        end
    end
    return nil
end

---@param name string
---@return animation_state
function AnimationController:add_state(name)
    local state = AnimationState.new(name)
    self.states[name] = state
    return state
end

---@class animation_state
---@field public animation animation
---@field public name string
---@field private transitions (fun(object: game_object): string?)[]
AnimationState = {}
AnimationState.__index = AnimationState

---@param name string
---@return animation_state
function AnimationState.new(name)
    local self = setmetatable({}, AnimationState)--[[@as animation_state]]
    self.animation = nil
    self.name = name
    self.transitions = {}
    return self
end

---@param fun fun(object: game_object): string?
function AnimationState:add_transition(fun)
    table.insert(self.transitions, fun)
end

function AnimationState:transition(object)
    for i, fun in ipairs(self.transitions) do
        local target = fun(object)
        if target ~= nil then
            return target
        end
    end
    return nil
end

---@class callback_event_params
---@field public callback fun(self: game_object)

---@class event_trigger
---@field public name string
---@field public params table?
EventTrigger = {}
EventTrigger.__index = EventTrigger

---@param name string
---@param params table?
---@return event_trigger
function EventTrigger.new(name, params)
    local self = setmetatable({}, EventTrigger)--[[@as event_trigger]]
    self.name = name
    self.params = params
    return self
end

---@class animation_frame
---@field public src rectangle
---@field public events event_trigger[]?
AnimationFrame = {}
AnimationFrame.__index = AnimationFrame

---@param src rectangle
---@param events (event_trigger|string)[]?
---@overload fun(src: rectangle): animation_frame
---@overload fun(src: rectangle, event: string): animation_frame
---@overload fun(src: rectangle, event: event_trigger): animation_frame
---@return animation_frame
function AnimationFrame.new(src, events)
    local self = setmetatable({}, AnimationFrame)--[[@as animation_frame]]
    self.src = src
    if type(events) == "string" then
        self.events = { EventTrigger.new(events, nil) }
    elseif events ~= nil and events--[[@as event_trigger]].name ~= nil then
        self.events = { events }
    elseif events ~= nil then
        self.events = {}
        for i, event in ipairs(events) do
            if type(event) == "string" then
                self.events[i] = EventTrigger.new(event, nil)
            else
                self.events[i] = event
            end
        end
    end
    return self
end

---@class animation
---@field public length number
---@field public loop loop_type
---@field private frames { [number]: animation_frame }
Animation = {}
Animation.__index = Animation

---@param frames table<number, animation_frame>
---@param length number
---@param loop loop_type
---@return animation
function Animation.new(frames, length, loop)
    local self = setmetatable({}, Animation)--[[@as animation]]
    self.frames = frames
    self.length = length
    self.loop = loop
    return self
end

---@param time number
---@return animation_frame
function Animation:get_frame(time)
    local t = -1
    for key, value in pairs(self.frames) do
        if key > t and key <= time then
            t = key
        end
    end
    return self.frames[t]
end

---@return (animation_frame[]|animation_frame)?
function Animation:get_all_frames(min, max)
    local frames = nil
    local frame = nil
    for key, value in pairs(self.frames) do
        if key >= min and key <= max then
            if frames == nil then
                if frame ~= nil then
                    frames = {}
                    table.insert(frames, frame)
                    table.insert(frames, value)
                else
                    frame = value
                end
            else
                table.insert(frames, value)
            end
        end
    end

    if frames == nil then
        return frame
    end
    return frames
end

---@class animation_instance
---@field public state animation_state
---@field private owner game_object
---@field private controller animation_controller
---@field public time number
---@field public total_time number
---@field public finished boolean
---@field public length number
---@field private event_listeners { [string]: fun(self: game_object, params: table?)[] }
AnimationInstance = {}
AnimationInstance.__index = AnimationInstance

---@param controller animation_controller
---@return animation_instance
function AnimationInstance.new(owner, controller)
    local self = setmetatable({}, AnimationInstance)--[[@as animation_instance]]
    self.owner = owner
    self.controller = controller
    self.event_listeners = {}
    self:change_state(controller.default_state)
    return self
end

---@param event string
---@param listener fun(self: game_object, params: table?)
function AnimationInstance:add_event_listener(event, listener)
    local arr = self.event_listeners[event]
    if arr == nil then
        arr = {}
        self.event_listeners[event] = arr
    end
    table.insert(arr, listener)
end

function AnimationInstance:update()
    local prev_time = self.time
    local time = self.time
    time = time + Time.delta_time
    self.total_time = self.total_time + Time.delta_time
    if time >= self.length then
        self.finished = true
        if self.state.animation.loop == LoopType.Loop then
            time = time - self.length
        else
            time = self.length
        end
    end
    self.time = time

    -- The prev time and current time may be equal if the animation
    -- is holding
    if self.length == 0 and prev_time == 0 then
        -- specific fix for 0 length animations not triggering properly
        self:trigger_events(0, 0)
    elseif prev_time ~= time then
        -- animation looped
        if prev_time > time then
            self:trigger_events(0, time)
            self:trigger_events(prev_time, self.length)
        else
            self:trigger_events(prev_time, time)
        end
    end

    local target = self.state:transition(self.owner)
    if target ~= nil then
        self:change_state(target)
    end
end

---@private
---@param min number
---@param max number
function AnimationInstance:trigger_events(min, max)
    local frames = self.state.animation:get_all_frames(min, max)
    if frames ~= nil then
        -- If 1 is not nil, this must be an array, otherwise
        -- it's a single frame
        if frames[1] ~= nil then
            for i, frame in ipairs(frames) do
                self:trigger_event(frame)
            end
        else
            self:trigger_event(frames--[[@as animation_frame]])
        end
    end
end

---@private
---@param frame animation_frame
function AnimationInstance:trigger_event(frame)
    if frame.events ~= nil then
        for i, event in ipairs(frame.events) do
            if event.name == "callback" then
                local params = event.params--[[@as callback_event_params]]
                params.callback(self.owner)
                goto continue
            end

            local listeners = self.event_listeners[event.name]
            if listeners ~= nil then
                for j, listener in ipairs(listeners) do
                    listener(self.owner, event.params)
                end
            end

            ::continue::
        end
    end
end

---@param state_name string
function AnimationInstance:change_state(state_name)
    local state = self.controller:get_state(state_name)
    if state ~= nil then
        self.time = 0
        self.total_time = 0
        self.finished = false
        self.state = state
        self.length = state.animation.length
    end
end

---@return animation_frame
function AnimationInstance:get_current_frame()
    local anim = self.state.animation
    if self.finished and anim.loop == LoopType.Once then
        return anim:get_frame(0)
    else
        if self.finished and anim.loop == LoopType.Hold then
            return anim:get_frame(anim.length)
        end
    end

    return anim:get_frame(self.time)
end