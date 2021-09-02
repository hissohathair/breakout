--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.balls = params.balls
    self.level = params.level
    self.paused = false
    self.music_paused = false
    self.sleep_enabled = love.window.isDisplaySleepEnabled()

    self.recoverPoints = 5000

    -- give ball random starting velocity
    self.balls[1].dx = math.random(-200, 200)
    self.balls[1].dy = math.random(-50, -60)

    -- no powerups in play yet
    self.powerup = Powerup(VIRTUAL_WIDTH / 2, 0)
    self.powerup.inPlay = false

    -- are any bricks locked?
    self.canBreakLocks = false
    for k, brick in pairs(self.bricks) do
        if brick.isLocked then
            self.powerup.unlockAllowed = true
            break
        end
    end
    print(string.format("DEBUG: unlock power up allowed = %s", 
        tostring(self.powerup.unlockAllowed)))
end

function PlayState:update(dt)

    -- Let the user turn music off during game play
    if love.keyboard.wasPressed('m') then
        if gSounds['music']:isPlaying() then
            gSounds['music']:pause()
            self.music_paused = true
        else
            gSounds['music']:play()
            self.music_paused = false
        end
    end

    -- TODO: Remove. For testing, hit a key to spawn a powerup
    if love.keyboard.wasPressed('x') then
        self.powerup:reset(self.paddle.x + self.paddle.width / 2,
            self.paddle.y - self.paddle.height * 3)
    end

    -- Check for pause / unpause conditions
    if self.paused then
        if love.keyboard.wasPressed('space') then
            -- unpause resumes music only if it was playing when paused, and
            -- prevents display from sleeping if that was original setting
            self.paused = false
            gSounds['pause']:play()
            if not self.music_paused then
                gSounds['music']:play()
            end
            love.window.setDisplaySleepEnabled(self.sleep_enabled)
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        -- pausing always pauses music and allows display to sleep
        self.paused = true
        gSounds['pause']:play()
        gSounds['music']:pause()
        love.window.setDisplaySleepEnabled(true)
        return
    end

    -- update positions based on velocity
    self.paddle:update(dt)
    for k, ball in pairs(self.balls) do
        ball:update(dt)
    end

    -- update powerup if in play
    self.powerup:update(dt)
    if self.powerup.inPlay and self.powerup:collides(self.paddle) then
        self.powerup:hit(self)
    end

    -- check if any balls have collided with paddle
    for k, ball in pairs(self.balls) do
        if ball:collides(self.paddle) then
            -- raise ball above paddle in case it goes below it, then reverse dy
            ball.y = self.paddle.y - ball.height
            ball.dy = -ball.dy

            --
            -- tweak angle of bounce based on where it hits the paddle
            --

            -- if we hit the paddle on its left side while moving left...
            if ball.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
                ball.dx = -50 + -(ball.width * (self.paddle.x + self.paddle.width / 2 - ball.x))
            
            -- else if we hit the paddle on its right side while moving right...
            elseif ball.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
                ball.dx = 50 + (ball.width * math.abs(self.paddle.x + self.paddle.width / 2 - ball.x))
            end

            gSounds['paddle-hit']:play()
        end
    end

    -- detect collision across all bricks with all balls
    for k, brick in pairs(self.bricks) do
        for l, ball in pairs(self.balls) do

            -- only check collision if we're in play
            if brick.inPlay and ball:collides(brick) then

                -- add to score
                self.score = self.score + (brick.tier * 200 + brick.color * 25)

                -- trigger the brick's hit function, which removes it from play
                brick:hit(self.canBreakLocks)

                -- sometimes, a brick will spawn a power up
                if math.random(3) == 1 and not self.powerup.inPlay then
                    self.powerup:reset(brick.x + brick.width / 2,
                        brick.y + brick.height / 2)
                end

                -- if we have enough points, recover a point of health
                if self.score > self.recoverPoints then
                    -- can't go above 3 health
                    self.health = math.min(3, self.health + 1)

                    -- multiply recover points by 2
                    self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                    -- play recover sound effect
                    gSounds['recover']:play()
                end

                -- go to our victory screen if there are no more bricks left
                if self:checkVictory() then
                    gSounds['victory']:play()

                    gStateMachine:change('victory', {
                        level = self.level,
                        paddle = self.paddle,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        balls = self.balls,
                        recoverPoints = self.recoverPoints
                    })
                end

                --
                -- collision code for bricks
                --
                -- we check to see if the opposite side of our velocity is outside of the brick;
                -- if it is, we trigger a collision on that side. else we're within the X + width of
                -- the brick and should check to see if the top or bottom edge is outside of the brick,
                -- colliding on the top or bottom accordingly 
                --

                -- left edge; only check if we're moving right, and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                if ball.x + 2 < brick.x and ball.dx > 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x - ball.width
                
                -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
                -- so that flush corner hits register as Y flips, not X flips
                elseif ball.x + 6 > brick.x + brick.width and ball.dx < 0 then
                    
                    -- flip x velocity and reset position outside of brick
                    ball.dx = -ball.dx
                    ball.x = brick.x + 32
                
                -- top edge if no X collisions, always check
                elseif ball.y < brick.y then
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y -  ball.height
                
                -- bottom edge if no X collisions or top collision, last possibility
                else
                    
                    -- flip y velocity and reset position outside of brick
                    ball.dy = -ball.dy
                    ball.y = brick.y + 16
                end

                -- slightly scale the y velocity to speed up the game, capping at +- 150
                if math.abs(ball.dy) < 150 then
                    ball.dy = ball.dy * 1.02
                end

                -- only allow colliding with one brick, for corners
                break
            end
        end -- for l, ball
    end -- for k, brick

    -- if ball goes below bounds, take it out of play
    local num_balls = 0
    for k, ball in pairs(self.balls) do
        if ball.y >= VIRTUAL_HEIGHT then
            gSounds['hurt']:play()
            ball.inPlay = false
        else
            num_balls = num_balls + 1
        end
    end

    -- remove any balls from self.balls that have gone out of play
    for k, ball in pairs(self.balls) do
        if not ball.inPlay then
            table.remove(self.balls, k)
        end
    end

    -- only lose health if all balls are now out of play
    if num_balls <= 0 then
        self.health = self.health - 1
        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints
            })
        end
    end


    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)
    end

    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end

function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    -- render powerup
    self.powerup:render()

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()
    for k, ball in pairs(self.balls) do
        ball:render()
    end

    renderScore(self.score)
    renderHealth(self.health)

    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end

function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end