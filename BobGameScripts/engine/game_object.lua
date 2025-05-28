--#build
--#priority 190

---@class game_object
---@field public game game
---@field public x integer
---@field public y integer
---@field public tags string[]
GameObject = {}
GameObject.__index = GameObject

---@return game_object
function GameObject.new()
    local self = setmetatable({}, GameObject)--[[@as game_object]]
    self.game = nil
    self.x = 0
    self.y = 0
    self.tags = {}
    return self
end

function GameObject:update() end
function GameObject:draw() end
function GameObject:initialize() end
function GameObject:unload() end

---@param tag string
---@return boolean
function GameObject:has_tag(tag)
    if self.tags == nil then
        return false
    end

    for i, v in ipairs(self.tags) do
        if v == tag then
            return true
        end
    end
    return false
end

---@param tags string[]
---@return boolean
function GameObject:has_any_tag(tags)
    if self.tags == nil then
        return false
    end

    for i, v in ipairs(tags) do
        if self:has_tag(v) then
            return true
        end
    end
    return false
end

function GameObject:destroy()
    self.game:remove_object(self)
end