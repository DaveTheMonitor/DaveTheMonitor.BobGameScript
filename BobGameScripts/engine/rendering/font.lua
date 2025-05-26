--#build
--@priority 104

---@class glyph
---@field public x integer
---@field public y integer
---@field public width integer
---@field public height integer
---@field public bearing_y integer
---@field public advance integer
Glyph = {}
Glyph.__index = Glyph

---@param x integer
---@param y integer
---@param width integer
---@param height integer
---@param bearing_y integer
---@param advance integer
function Glyph.new(x, y, width, height, bearing_y, advance)
    local self = setmetatable({}, Glyph)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.bearing_y = bearing_y
    self.advance = advance
    return self
end

---@class font
---@field public name string
---@field public sprite sprite
---@field public mask integer
---@field public unknown_glyph integer
---@field private glyph_table table<integer, glyph>
Font = {}
Font.__index = Font

---@param name string
---@param sprite sprite
---@param mask integer
---@param unknown_glyph integer
---@param glyph_table table<integer, glyph>
function Font.new(name, sprite, mask, unknown_glyph, glyph_table)
    local self = setmetatable({}, Font)
    self.name = name
    self.sprite = sprite
    self.mask = mask
    self.unknown_glyph = unknown_glyph
    self.glyph_table = glyph_table
    return self
end

---@param glyph integer
---@return glyph
function Font:get_glyph(glyph)
    if not self:glyph_valid(glyph) then
        glyph = self.unknown_glyph
    end

    return self.glyph_table[glyph]
end

---@param glyph integer
---@return boolean
function Font:glyph_valid(glyph)
    return self.glyph_table[glyph] ~= nil
end

---@param str string
---@param i integer
---@return integer
function Font:get_glyph_index(str, i)
    local glyph = str:byte(i)
    if glyph >= 65 and glyph <= 90 then
        -- uppercase char, convert to lowercase
        glyph = glyph + 32
    end
    return glyph
end

---@param str string
---@return integer x
---@return integer y
function Font:measure(str)
    local x = 0
    local y = 0
    local w = 0
    local h = 0
    for i = 1, str:len() do
        local byte = str:byte(i, i)
        local glyph = self:get_glyph(self:get_glyph_index(str, i))
        if byte == 10 then
            -- 10 == \n
            y = y + glyph.advance
            x = 0
        elseif byte == 32 then
            -- 32 == space
            x = x + glyph.advance
        else
            x = x + glyph.advance
            if x > w then
                w = x
            end
            if y + glyph.height > h then
                h = y + glyph.height
            end
        end
    end

    return w, h
end

---@class font_data
---@field public sprite string
---@field public mask integer
---@field public unknown_glyph integer
---@field public glyph_table table<integer, glyph>
FontData = {}
FontData.__index = FontData

---@param sprite string
---@param mask integer
---@param unknown_glyph integer
---@param glyph_table table<integer, glyph>
function FontData.new(sprite, mask, unknown_glyph, glyph_table)
    local self = setmetatable({}, FontData)
    self.sprite = sprite
    self.mask = mask
    self.unknown_glyph = unknown_glyph
    self.glyph_table = glyph_table
    return self
end