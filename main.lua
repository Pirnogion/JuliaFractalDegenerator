------ Интересные константы ------
-- {0.0941001, 0.6050800000001} --
-- {-0.0085, 0.71}              --
-- {0.285, 0.01}                --
-- {0, 1}                       --
----------------------------------

local gpu = love.graphics
local screenWidth, screenHeight = gpu.getWidth(), gpu.getHeight()

local shader = nil

local const = {-0.74543, 0.11301}
local r = (1+math.sqrt(1+4*(const[1]*const[1]+const[2]*const[2])))/2 + 0.6

local isDragging = false
local isChangingIterations = false
local mousePrevPos = {0.0, 0.0}
local iterationDelta = 1

local zoom = 1.0
local zoomDelta = 0.0271
local shift = {0.0, 0.0}
local shiftDelta = -0.05

local iterations = 30

local function bound(v, min, max)
	return (v > max) and max or (v < min) and min or v
end

function love.keypressed(key)
	if key == "kp+" then
		if (isChangingIterations) then
    		iterations = bound(iterations+1, 1, 1000)
    	else
        	zoom = bound(zoom - zoomDelta, zoomDelta, 1.0)
        end
	elseif key == "kp-" then
		if (isChangingIterations) then
    		iterations = bound(iterations-1, 1, 1000)
    	else
        	zoom = bound(zoom + zoomDelta, zoomDelta, 1.0)
        end
	elseif key == "up" then
		shift[2] = shift[2] + shiftDelta
	elseif key == "down" then
		shift[2] = shift[2] - shiftDelta
	elseif key == "left" then
		shift[1] = shift[1] + shiftDelta
	elseif key == "right" then
		shift[1] = shift[1] - shiftDelta
	elseif key == "lctrl" then
		isChangingIterations = true
	end
end

function love.keyreleased(key)
	if key == "lctrl" then
		isChangingIterations = false
	end
end

function love.wheelmoved(dx, dy)
    if dy > 0 then
    	if (isChangingIterations) then
    		iterations = bound(iterations+1, 1, 1000)
    	else
        	zoom = bound(zoom - zoomDelta, zoomDelta, 1.0)
        end
    elseif dy < 0 then
    	if (isChangingIterations) then
    		iterations = bound(iterations-1, 1, 1000)
    	else
        	zoom = bound(zoom + zoomDelta, zoomDelta, 1.0)
        end
    end
end

function love.mousepressed(x, y, button)
	if button == 1 then
		mousePrevPos[1] = x
		mousePrevPos[2] = y
		isDragging = true
	end
end

function love.mousereleased(x, y, button)
	if button == 1 then
		isDragging = false
	end
end

function love.load()
	gpu.setBackgroundColor(0.98, 0.98, 0.98)
	gpu.setColor(0.1, 0.1, 0.1)

	local effect = [[
		extern float iterations;
		extern float radius;
		extern float zoom;
		extern vec2 shift;
		extern vec2 constant;

        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
        {
        	vec2 point = vec2((2*pixel_coords.x*radius)/love_ScreenSize.x - radius, (2*pixel_coords.y*radius)/love_ScreenSize.y - radius);
        	point *= zoom;
        	point += shift;
        	float j;
			for (j = 0; j < iterations && dot(point, point) < radius; ++j)
				point = vec2(point.x*point.x - point.y*point.y, 2*point.x*point.y) + constant;

            return vec4(color.r, color.g, color.b, j / iterations);
        }
    ]]

    overlay = love.graphics.newCanvas()
    shader = love.graphics.newShader(effect)
end

function love.update(dt)
	if isDragging then
		shift[1] = shift[1] - (love.mouse.getX() - mousePrevPos[1]) * zoom * dt
		shift[2] = shift[2] - (love.mouse.getY() - mousePrevPos[2]) * zoom * dt

		mousePrevPos[1] = love.mouse.getX()
		mousePrevPos[2] = love.mouse.getY()
	end
end

function love.draw()
	love.graphics.setShader(shader)
	shader:send("iterations", iterations)
	shader:send("radius",     r)
	shader:send("zoom",       zoom)
	shader:send("shift",      shift)
	shader:send("constant",   const)
    love.graphics.rectangle('fill', 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
	love.graphics.setShader()

	gpu.print("FPS: " .. love.timer.getFPS(), 0, 0)
	gpu.print("Zoom: " .. zoom, 0, 10)
	gpu.print("Precision: " .. iterations .. ", radius: " .. r, 0, 20)
	gpu.print("C = " .. const[1] .. ((const[2] > 0) and " + " or " - ") .. const[2] .. "i", 0, 30)
end
