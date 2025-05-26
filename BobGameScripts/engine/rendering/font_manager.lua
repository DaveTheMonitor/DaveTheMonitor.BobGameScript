--#build
--@priority 105

---@class font_manager
---@field private sprite_manager sprite_manager
---@field private font_data { [string]: font_data }
---@field private loaded_fonts { [string]: font }
FontManager = {}
FontManager.__index = FontManager

---@param sprite_manager sprite_manager
function FontManager.new(sprite_manager)
    local self = setmetatable({}, FontManager)
    self.sprite_manager = sprite_manager
    self.font_data = {}
    self.loaded_fonts = {}
    return self
end

---@param name string
---@return font
function FontManager:load(name)
    local font = self.loaded_fonts[name]
    if font ~= nil then
        return font
    end

    local data = self.font_data[name]
    if data == nil then
        warn("Invalid font " .. name)
        ---@diagnostic disable-next-line
        return nil
    end

    font = Font.new(name, sprite_manager:load(data.sprite), data.mask, data.unknown_glyph, data.glyph_table)
    self.loaded_fonts[name] = font
    return font
end

---@param font font
function FontManager:unload(font)
    self.loaded_fonts[font.name] = nil
end

function FontManager:unload_all()
    for key, value in pairs(self.loaded_fonts) do
        self.loaded_fonts[key] = nil
    end
end

---@param name string
---@param data font_data
function FontManager:add_data(name, data)
    self.font_data[name] = data
end