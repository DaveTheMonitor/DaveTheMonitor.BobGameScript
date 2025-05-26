--#build
--@priority 102

---@class sprite
---@field public name string
---@field public data integer[]
---@field public width integer
---@field public height integer
Sprite = {}
Sprite.__index = Sprite

---@param name string
---@param data integer[]
---@param width integer
---@param height integer
function Sprite.new(name, data, width, height)
    local self = setmetatable({}, Sprite)
    self.name = name
    self.data = data
    self.width = width
    self.height = height
    return self
end

---@class sprite_data
---@field data integer[]
---@field data_length integer
---@field width integer
---@field height integer
SpriteData = {}
SpriteData.__index = SpriteData

---@param width integer
---@param height integer
---@param data integer[]
---@return sprite_data
function SpriteData.new(width, height, data)
    local self = setmetatable({}, SpriteData)
    self.width = width
    self.height = height
    self.data_length = #data
    self.data = data
    return self
end

---@return integer[]
function SpriteData:uncompress()
    local data = {}
    for i = 1, self.data_length, 2 do
        local count = self.data[i]
        local block = self.data[i + 1]
        for j = 1, count, 1 do
            table.insert(data, block)
        end
    end

    return data
end