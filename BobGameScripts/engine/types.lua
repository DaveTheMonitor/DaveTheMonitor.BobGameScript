--#build
--#priority 101

---@class rectangle
---@field public x number The X position of the box.
---@field public y number The Y position of the box.
---@field public w number The width of the box.
---@field public h number The height of the box.
Rectangle = {}
Rectangle.__index = Rectangle

---@param x number
---@param y number
---@param w number
---@param h number
---@return rectangle
function Rectangle.new(x, y, w, h)
    local self = setmetatable({}, Rectangle)
    self.x = x
    self.y = y
    self.w = w
    self.h = h
    return self
end

---@param x number
---@param y number
---@return boolean
function Rectangle:contains(x, y)
    return x >= self.x and x <= self.x + self.w and y >= self.y and y <= self.y + self.h
end

---@param other rectangle
---@return boolean
function Rectangle:intersects(other)
    return self.x < other.x + other.w and other.x < self.x + self.w and self.y < other.y + other.h and other.y < self.y + self.h
end

---@return rectangle
function Rectangle:copy()
    return Rectangle.new(self.x, self.y, self.w, self.h)
end

---@param other rectangle
---@return boolean
function Rectangle:__eq(other)
    if getmetatable(other) ~= Rectangle then
        return false
    end

    return self.x == other.x and self.y == other.y and self.w == other.w and self.h == other.h
end

---@return string
function Rectangle:__tostring()
    return "{x: " .. self.x .. ", y: " .. self.y .. ", w: " .. self.w .. ", h: " .. self.h .."}"
end