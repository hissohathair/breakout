--[[
    GD50
    Breakout Remake

    -- Powerup Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents a "Powerup" which starts falling from the screen, and when hit
    by the player's paddle, will spawn additional balls.
]]

Powerup = Class{}

local POWERUP_SPEED = 30
local ROTATION_SPEED = 0.35

local POWERUPS_AVAILABLE = { 1, 2, 3, 4, 9 }
local NUM_POWERUPS = 5


local paletteColors = {
    -- red X
    [1] = { ['r'] = 217 / 255, ['g'] = 87 / 255, ['b'] = 99 / 255 },
    -- green X
    [2] = { ['r'] = 106 / 255, ['g'] = 190 / 255, ['b'] = 47 / 255 },
    -- red heart
    [3] = { ['r'] = 217 / 255, ['g'] = 87 / 255, ['b'] = 99 / 255 },
    -- red skull
    [4] = { ['r'] = 217 / 255, ['g'] = 87 / 255, ['b'] = 99 / 255 },
    -- gold up
    [5] = { ['r'] = 251 / 255, ['g'] = 242 / 255, ['b'] = 54 / 255 },
    -- gold down
    [6] = { ['r'] = 251 / 255, ['g'] = 242 / 255, ['b'] = 54 / 255 },
    -- blue small ball
    [7] = { ['r'] = 99 / 255, ['g'] = 155 / 255, ['b'] = 255 / 255 },
    -- blue big ball
    [8] = { ['r'] = 99 / 255, ['g'] = 155 / 255, ['b'] = 255 / 255 },
    -- blue plus ball
    [9] = { ['r'] = 99 / 255, ['g'] = 155 / 255, ['b'] = 255 / 255 },
    -- gold key
    [6] = { ['r'] = 251 / 255, ['g'] = 242 / 255, ['b'] = 54 / 255 }
}


--[[
    Create a power powerup. Will randomly select the powerup type
    (currently either 3 or 9)
]]
function Powerup:init(x, y)
    self.x = x
    self.y = y
    self.width = 16
    self.height = 16

    -- on init, reset
    self:reset(self)
end

--[[
    Called when a brick is spawning a new powerup
]]
function Powerup:reset(brick)
    -- reset powerup's position
    self.x = brick.x + brick.width / 2
    self.y = brick.y + brick.height / 2
    self.rotation = 0
    self.dy = POWERUP_SPEED
    self.inPlay = true 
    self.skin = POWERUPS_AVAILABLE[math.random(NUM_POWERUPS)]

    -- particle system for when powerup hits paddle
    self.psystem = love.graphics.newParticleSystem(gTextures['particle'], 64)

    -- lasts between 0.5-1 seconds seconds
    self.psystem:setParticleLifetime(0.5, 1.0)

    -- give it an acceleration of anywhere between X1,Y1 and X2,Y2
    -- had these different to the settings in Ball.lua but it didn't look good
    self.psystem:setLinearAcceleration(-15, 0, 15, 80)

    -- spread of particles; normal looks more natural than uniform
    self.psystem:setEmissionArea('normal', 10, 10)

    -- Fade to from blue to clear
    local n = self.skin
    self.psystem:setColors(paletteColors[n].r, paletteColors[n].g, paletteColors[n].b, 0.8,
        paletteColors[n].r, paletteColors[n].g, paletteColors[n].b, 0.0) 
end

--[[
    Expects an argument with a bounding box for the paddle, and returns true if
    the bounding boxes of this and the argument overlap.

    TODO: This code copied from Ball.lua, should probably move AABB test
    to Util.lua
]]
function Powerup:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end

--[[
    Called when the player hits the powerup with their paddle. Currently only
    skips #3 & #9 are supported -- this spawns more balls from the paddle.
]]
function Powerup:hit(playState)
    -- register the hit
    self.inPlay = false
    self.psystem:emit(64)

    -- execute the powerup based on skin
    if 3 == self.skin then
        -- add new life
        gSounds['recover']:play()
        playState.health = math.min(3, playState.health + 1)

    elseif 4 == self.skin then
        -- takes a life, but doesn't take the last one
        gSounds['hurt2']:play()
        playState.health = math.max(1, playState.health - 1)

    elseif 1 == self.skin then
        -- removes all balls except the first one
        gSounds['hurt2']:play()        
        playState.balls = { playState.balls[1] }

    elseif 2 == self.skin then
        -- splits all balls into 2
        gSounds['powerup']:play()
        local balls = { }
        local i = 1
        for k, ball in pairs(playState.balls) do
            if ball.inPlay then
                -- copy existing ball
                balls[i] = ball

                -- clone that ball, but have it go in opposite dx and always up
                newbie = Ball(ball.skin)
                newbie.x = ball.x
                newbie.y = ball.y 
                newbie.dx = -ball.dx
                newbie.dy = math.abs(ball.dy) * -1
            
                -- add to the list
                balls[i + 1] = newbie
                i = i + 2
            end
        end

        -- save the new list
        playState.balls = balls 

    elseif 9 == self.skin then
        -- 2 new balls, flying off randomly
        gSounds['powerup']:play()
        local balls = { }

        -- first, copy over the ones currently in play
        local i = 1
        for k, ball in pairs(playState.balls) do
            if ball.inPlay then
                balls[i] = ball
                i = i + 1
            end
        end

        local new_balls = { Ball(), Ball() }
        for k, ball in pairs(new_balls) do
            -- ball spawns at players paddle
            ball.skin = math.random(7)
            ball.x = playState.paddle.x + (playState.paddle.width / 2) - (ball.width / 2)
            ball.y = playState.paddle.y - ball.height

            -- ball flies off in randomish direction
            ball.dx = math.random(-200, 200)
            ball.dy = math.random(-50, -60)

            balls[i] = ball
            i = i + 1
        end

        -- save the new list
        playState.balls = balls

    else
        -- a powerup we haven't handled! Let's just give points...
        gSounds['powerup']:play()
        playState.score = playState.score + 250
    end
end


function Powerup:update(dt)
    if self.inPlay then
        -- fall and spin
        self.y = self.y + self.dy * dt
        self.rotation = self.rotation + ROTATION_SPEED * dt
        if self.rotation > math.pi * 2 then
            self.rotation = 0 
        end

        -- powerup goes out of play once it drops off screen
        if self.y > VIRTUAL_HEIGHT + self.height then
            self.inPlay = false
        end
    else
        self.psystem:update(dt)
    end
end

function Powerup:render()
    if self.inPlay then
        love.graphics.draw(gTextures['main'], gFrames['powerups'][self.skin],
            self.x, self.y, self.rotation)
    else
        love.graphics.draw(self.psystem, self.x, self.y + self.height / 2)
    end
end
