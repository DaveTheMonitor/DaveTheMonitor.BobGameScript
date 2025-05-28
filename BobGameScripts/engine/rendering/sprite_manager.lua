--#build
--@priority 103

---@class sprite_manager
---@field private sprite_data { [string]: sprite_data }
---@field private loaded_sprites { [string]: sprite }
SpriteManager = {}
SpriteManager.__index = SpriteManager

---@return sprite_manager
function SpriteManager.new()
    local self = setmetatable({}, SpriteManager)--[[@as sprite_manager]]
    self.sprite_data = {}
    self.loaded_sprites = {}
    return self
end

---@param name string
---@return sprite
function SpriteManager:load(name)
    local sprite = self.loaded_sprites[name]
    if sprite ~= nil then
        return sprite
    end

    local data = self.sprite_data[name]
    if data == nil then
        warn("Invalid sprite " .. name)
        return Sprite.new(name, {}, 0, 0)
    end

    sprite = Sprite.new(name, data:uncompress(), data.width, data.height)
    self.loaded_sprites[name] = sprite
    return sprite
end

---@param sprite sprite
function SpriteManager:unload(sprite)
    self.loaded_sprites[sprite.name] = nil
    sprite.data = nil
end

function SpriteManager:unload_all()
    for key, _ in pairs(self.loaded_sprites) do
        self.loaded_sprites[key] = nil
        self.loaded_sprites[key].data = nil
    end
end

---@param name string
---@param data sprite_data
function SpriteManager:add_data(name, data)
    self.sprite_data[name] = data
end