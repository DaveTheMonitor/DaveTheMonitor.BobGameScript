--#build
--#priority 401

---@class weapon
---@field public sprite sprite
---@field protected player player
---@field public idle_anim_state string
---@field public run_anim_state string
---@field public air_anim_state string
Weapon = {}
Weapon.__index = Weapon

---@return weapon
function Weapon.new()
    local self = setmetatable({}, Weapon)--[[@as weapon]]
    return self
end

function Weapon:initialize() end
function Weapon:attack_input() end
function Weapon:special_input() end
function Weapon:equip() end
function Weapon:unqeuip() end