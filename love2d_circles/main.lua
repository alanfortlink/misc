local world
local objects

local num_circles = 250
local num_triangles = 250
local radius = 4

local side = 800
local min_force = 10
local max_force = 20

local rotated = function(x, y, rad, center_x, center_y)
  if rad == 0 then
    return x, y
  end

  local translated_x = x - center_x
  local translated_y = y - center_y

  local rotated_x = translated_x * math.cos(rad) - translated_y * math.sin(rad)
  local rotated_y = translated_x * math.sin(rad) + translated_y * math.cos(rad)

  local final_x = rotated_x + center_x
  local final_y = rotated_y + center_y

  return final_x, final_y
end

local random_sign = function()
  if math.random() > 0.5 then
    return 1
  end
  return -1
end

function love.load()
  love.physics.setMeter(64)
  love.window.setMode(side, side, { fullscreen = false })
  world = love.physics.newWorld(0, 0, true)
  objects = { circles = {}, triangles = {} }

  for _ = 1, num_circles do
    local circle = {}
    circle.body = love.physics.newBody(world, math.random(0, side), math.random(0, side), "dynamic")
    circle.shape = love.physics.newCircleShape(radius)
    circle.fixture = love.physics.newFixture(circle.body, circle.shape, 1)
    circle.fixture:setRestitution(1.0)
    circle.body:applyForce(
      random_sign() * math.random(min_force, max_force),
      random_sign() * math.random(min_force, max_force)
    )
    circle.color = { r = math.random(), g = math.random(), b = math.random() }
    table.insert(objects.circles, circle)
  end

  for _ = 1, num_triangles do
    local triangle = {}
    local center_x, center_y = math.random(0, side), math.random(0, side)

    local x1, y1 = rotated(0, 2 * radius, 2 * math.pi * (0.333), 0, 0)
    local x2, y2 = rotated(0, 2 * radius, 2 * math.pi * (0.666), 0, 0)
    local x3, y3 = rotated(0, 2 * radius, 2 * math.pi * (0.999), 0, 0)

    triangle.body = love.physics.newBody(world, center_x, center_y, "dynamic")
    triangle.shape = love.physics.newPolygonShape({ x1, y1, x2, y2, x3, y3 })
    triangle.fixture = love.physics.newFixture(triangle.body, triangle.shape, 1)
    triangle.fixture:setRestitution(1.0)
    triangle.body:applyForce(
      random_sign() * math.random(min_force, max_force),
      random_sign() * math.random(min_force, max_force)
    )
    triangle.color = { r = math.random(), g = math.random(), b = math.random() }
    table.insert(objects.triangles, triangle)
  end

  do
    objects.border = love.physics.newBody(world, 0, 0, "static")
    local shape = love.physics.newChainShape(true, {
      0, 0,       --
      side, 0,    --
      side, side, --
      0, side     --
    })
    local fixture = love.physics.newFixture(objects.border, shape)
    fixture:setRestitution(1.0)
  end
end

function love.update(dt)
  world:update(dt)
  local random_factor = 0.1
  for _, circle in ipairs(objects.circles) do
    -- add randomness
    circle.body:applyForce(
      random_factor * random_sign() * math.random(min_force, max_force),
      random_factor * random_sign() * math.random(min_force, max_force)
    )
  end

  for _, triangle in ipairs(objects.triangles) do
    -- add randomness
    triangle.body:applyForce(
      random_factor * random_sign() * math.random(min_force, max_force),
      random_factor * random_sign() * math.random(min_force, max_force)
    )
  end
end

function love.draw()
  for _, circle in ipairs(objects.circles) do
    love.graphics.setColor(circle.color.r, circle.color.g, circle.color.b)
    love.graphics.circle(
      "fill",
      circle.body:getX(),
      circle.body:getY(),
      circle.shape:getRadius()
    )
  end

  for _, triangle in ipairs(objects.triangles) do
    love.graphics.setColor(triangle.color.r, triangle.color.g, triangle.color.b)
    love.graphics.polygon( "fill", triangle.body:getWorldPoints(triangle.shape:getPoints()))
  end
end
