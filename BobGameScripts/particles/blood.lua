--#build
--#priority 450

---@class blood : particle
Blood = Particle.new()
Blood.__index = Blood

---@return blood
function Blood.new()
    local self = setmetatable({}, Blood)--[[@as blood]]
    return self
end

function Blood:initialize(particle, game)
    particle.data1 = 0
    particle.duration = 3 + math.random()
end

function Blood:update(particle, game)
    ---@cast game bob_game
    local dt = Time.delta_time

    local friction
    if particle.data1 > 0 then
        friction = 200
    else
        friction = 20
    end

    if particle.vel_x < 0 then
        particle.vel_x = math.min(particle.vel_x + (friction * dt), 0)
    elseif particle.vel_x > 0 then
        particle.vel_x = math.max(particle.vel_x - (friction * dt), 0)
    end

    particle.vel_y = particle.vel_y - ((game.level.gravity * 0.5) * dt)

    particle.x = particle.x + (particle.vel_x * dt)
    particle.y = particle.y + (particle.vel_y * dt)

    if particle.y < game.level.ground_level then
        particle.y = game.level.ground_level
        particle.data1 = 1
    end
end

function Blood:draw(particle, game)
    local x = math.floor(particle.x + 0.5);
    local y = math.floor(particle.y + 0.5);
    game.screen:draw_pixel(block.colordarkred, x, y, Layers.particles)
end