local world
local objects

local num_circles = 500
local radius = 4
local fac = 8

local restitution = 1.0
local boundary_restitution = 1.0

function love.load()
  love.physics.setMeter(64)
  love.window.setMode(650, 650, { fullscreen = false })
  world = love.physics.newWorld(0, 0, true)
  objects = {}

  objects.balls = {}

  for _ = 1, num_circles do
    local ball = {}
    ball.body = love.physics.newBody(world, math.random(50, 600), math.random(50, 600), "dynamic")
    ball.shape = love.physics.newCircleShape(radius)
    ball.fixture = love.physics.newFixture(ball.body, ball.shape, 1)
    ball.fixture:setRestitution(restitution)
    ball.body:applyForce(math.random(-radius * fac, radius * fac), math.random(-radius * fac, radius * fac))
    ball.color = { r = math.random(), g = math.random(), b = math.random() }
    table.insert(objects.balls, ball)
  end

  objects.ground = {}
  objects.ground.body = love.physics.newBody(world, 650 / 2, 650 + 50 / 2)
  objects.ground.shape = love.physics.newRectangleShape(650, 50)
  objects.ground.fixture = love.physics.newFixture(objects.ground.body, objects.ground.shape)
  objects.ground.fixture:setRestitution(boundary_restitution)

  objects.ceiling = {}
  objects.ceiling.body = love.physics.newBody(world, 650 / 2, -50 / 2)
  objects.ceiling.shape = love.physics.newRectangleShape(650, 50)
  objects.ceiling.fixture = love.physics.newFixture(objects.ceiling.body, objects.ceiling.shape)
  objects.ceiling.fixture:setRestitution(boundary_restitution)

  objects.left = {}
  objects.left.body = love.physics.newBody(world, -50 / 2, 650 / 2)
  objects.left.shape = love.physics.newRectangleShape(50, 650)
  objects.left.fixture = love.physics.newFixture(objects.left.body, objects.left.shape)
  objects.left.fixture:setRestitution(boundary_restitution)

  objects.right = {}
  objects.right.body = love.physics.newBody(world, 650 + 50 / 2, 650 / 2)
  objects.right.shape = love.physics.newRectangleShape(50, 650)
  objects.right.fixture = love.physics.newFixture(objects.right.body, objects.right.shape)
  objects.right.fixture:setRestitution(boundary_restitution)
end

function love.update(dt)
  world:update(dt)
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
