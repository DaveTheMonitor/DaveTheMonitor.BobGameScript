--#build
--#priority 450

---@class cloud : particle
---@field private sprite_1 sprite
---@field private sprite_2 sprite
Cloud = setmetatable({}, Particle)
Cloud.__index = Cloud

---@return cloud
function Cloud.new()
    local self = setmetatable(Particle.new(), Cloud)--[[@as cloud]]
    return self
end

function Cloud:initialize(particle, game)
    if self.sprite_1 == nil then
        self.sprite_1 = sprite_manager:load("cloud_1")
        self.sprite_2 = sprite_manager:load("cloud_2")
    end

    if math.random() > 0.66 then
        particle.data1 = 1
        particle.vel_x = 2 + (math.random() * 1.5)
    else
        particle.data1 = 2
        particle.vel_x = 3 + (math.random() * 1.5)
    end

    local layer = math.random(1, 3)
    if layer == 1 then
        particle.data2 = Layers.bg_particle
        particle.vel_x = particle.vel_x - 1.5
    elseif layer == 2 then
        particle.data2 = Layers.mg_particle
    else
        particle.data2 = Layers.objects
        particle.vel_x = particle.vel_x + 1.5
    end

    particle.duration = -1
end

function Cloud:update(particle, game)
    ---@cast game bob_game
    local dt = Time.delta_time
    particle.x = particle.x + (particle.vel_x * dt)
    particle.y = particle.y + (particle.vel_y * dt)

    if particle.x > game.screen.width + 20 then
        game.particles:destroy(particle)
    end
end

function Cloud:draw(particle, game)
    local x = math.floor(particle.x + 0.5);
    local y = math.floor(particle.y + 0.5);

    local sprite
    local offset_x
    local offset_y
    if particle.data1 == 1 then
        sprite = self.sprite_1
        offset_x = -12
        offset_y = -6
    else
        sprite = self.sprite_2
        offset_x = -6
        offset_y = -3
    end
    game.screen:draw(sprite, 0, 0, sprite.width, sprite.height, x + offset_x, y + offset_y, particle.data2--[[@as integer]])
end