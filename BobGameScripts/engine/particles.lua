--#build
--#priority 191

---@class particle_manager
---@field private game game
---@field private particles particle_instance[]
---@field private particle_count integer
---@field private next_draw_id integer
ParticleManager = {}
ParticleManager.__index = ParticleManager

---@param game game
---@param initial_capacity integer
---@return particle_manager
function ParticleManager.new(game, initial_capacity)
    local self = setmetatable({}, ParticleManager)--[[@as particle_manager]]
    self.game = game
    self.particles = {}
    self.particle_count = 0
    self.next_draw_id = 1
    for i = 1, initial_capacity do
        self.particles[i] = self:new_particle(0, self.next_draw_id)
        self.next_draw_id = self.next_draw_id + 1
    end
    return self
end

---@param id integer
---@param draw_id integer
---@return particle_instance
function ParticleManager:new_particle(id, draw_id)
    return {
        -- never nil when in use
        ---@diagnostic disable-next-line: assign-type-mismatch
        id = id,
        draw_id = draw_id,
        ---@diagnostic disable-next-line: assign-type-mismatch
        type = nil,
        x = 0,
        y = 0,
        vel_x = 0,
        vel_y = 0,
        duration = 0,
        age = 0,
        data1 = 0,
        data2 = 0,
        data3 = 0,
        data4 = 0
    }--[[@as particle_instance]]
end

---@param type particle
---@param x number
---@param y number
---@param vel_x number
---@param vel_y number
function ParticleManager:add(type, x, y, vel_x, vel_y)
    local id = self.particle_count + 1
    local particle = self.particles[id]
    if particle == nil then
        -- this is the end of the list, so we expand
        particle = self:new_particle(id, self.next_draw_id)
        self.next_draw_id = self.next_draw_id + 1
        self.particles[id] = particle
    end

    particle.x = x
    particle.y = y
    particle.vel_x = vel_x
    particle.vel_y = vel_y
    particle.type = type
    particle.id = id
    particle.age = 0
    type:initialize(particle, self.game)
    self.particle_count = self.particle_count + 1
end

---@param particle particle_instance
function ParticleManager:destroy(particle)
    if particle.type == nil then
        notify("failed to destroy particle " .. particle.id)
        return
    end

    local id = particle.id
    if self.particle_count > 0 then
        self.particles[id] = self.particles[self.particle_count]
        self.particles[id].id = id
        self.particles[self.particle_count] = particle
        particle.id = self.particle_count
    end

    particle.type = nil
    self.particle_count = self.particle_count - 1
end

function ParticleManager:destroy_all()
    local count = self.particle_count
    for i = 1, count do
        self.particles[i].type = nil
    end
    self.particle_count = 0
end

function ParticleManager:update()
    local game = self.game
    local particles = self.particles
    local dt = Time.delta_time
    local i = 1
    local initial_count = self.particle_count
    local total_updates = 0
    while i <= self.particle_count do
        local particle = particles[i]
        particle.age = particle.age + dt
        if particle.duration ~= -1 and particle.age >= particle.duration then
            self:destroy(particle)
        end

        if particle.type ~= nil then
            particle.type:update(particle, game)

            -- If the particle type is nil, then it was destroyed
            -- When this happens, it swaps places with the particle
            -- at the end of the list, meaning we need to update the
            -- same index again since it is now a different particle
            -- We assume particles will never destroy other particles
            i = i + 1
        end

        total_updates = total_updates + 1
        if total_updates > initial_count then
            error("updated particles too many times")
            break
        end
    end
end

function ParticleManager:draw()
    local game = self.game
    local particle_count = self.particle_count
    local particles = self.particles
    for i = 1, particle_count do
        local particle = particles[i]
        particle.type:draw(particle, game)
    end
end

---@class (exact) particle
---@field public __index table
---@field new function
Particle = {}
Particle.__index = Particle

---@return particle
function Particle.new()
    local self = setmetatable({}, Particle)
    return self
end

---@param particle particle_instance
---@param game game
function Particle:initialize(particle, game) end

---@param particle particle_instance
---@param game game
function Particle:update(particle, game)
    local dt = Time.delta_time
    particle.x = particle.x + (particle.vel_x * dt)
    particle.y = particle.y + (particle.vel_y * dt)
end

---@param particle particle_instance
---@param game game
function Particle:draw(particle, game) end

---@class particle_instance
---@field public id integer
---@field public draw_id integer
---@field public type particle
---@field public x number
---@field public y number
---@field public vel_x number
---@field public vel_y number
---@field public duration number
---@field public age number
---@field public data1 number|boolean
---@field public data2 number|boolean
---@field public data3 number|boolean
---@field public data4 number|boolean