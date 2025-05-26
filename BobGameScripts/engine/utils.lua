--#build
--#priority 001

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function distance(x1, y1, x2, y2)
    local dx = x1 - x2
    local dy = y1 - y2
    return math.sqrt((dx * dx) + (dy * dy))
end

---@param x number
---@param y number
---@return number
function length(x, y)
    return math.sqrt((x * x) + (y * y))
end

---@param x number
---@param y number
---@return number x
---@return number y
function normalize(x, y)
    local len = length(x, y)
    return x / len, y / len
end

---@param x1 number
---@param y1 number
---@param x2 number
---@param y2 number
---@return number
function dot(x1, y1, x2, y2)
    return (x1 * x2) + (y1 * y2);
end