local world
local objects

local num_circles = 1000
local radius = 2

local side = 800
local min_force = 10
local max_force = 20

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
  objects = { balls = {} }

  for _ = 1, num_circles do
    local ball = {}
    ball.body = love.physics.newBody(world, math.random(0, side), math.random(0, side), "dynamic")
    ball.shape = love.physics.newCircleShape(radius)
    ball.fixture = love.physics.newFixture(ball.body, ball.shape, 1)
    ball.fixture:setRestitution(1.0)
    ball.body:applyForce(
      random_sign() * math.random(min_force, max_force),
      random_sign() * math.random(min_force, max_force)
    )
    ball.color = { r = math.random(), g = math.random(), b = math.random() }
    table.insert(objects.balls, ball)
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
  for _, ball in ipairs(objects.balls) do
    -- add randomness
    ball.body:applyForce(
      random_factor * random_sign() * math.random(min_force, max_force),
      random_factor * random_sign() * math.random(min_force, max_force)
    )
  end
end

function love.draw()
  for _, ball in ipairs(objects.balls) do
    love.graphics.setColor(ball.color.r, ball.color.g, ball.color.b)
    love.graphics.circle(
      "fill",
      ball.body:getX(),
      ball.body:getY(),
      ball.shape:getRadius()
    )
  end
end
