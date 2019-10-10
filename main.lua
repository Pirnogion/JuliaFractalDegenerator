local sel = require "core/selector"

local mouse = {
	isDragging = false,
	prev = {x = 0, y = 0},

	update = function(self)
		if self.isDragging then
			self.prev.x = love.mouse.getX()
			self.prev.y = love.mouse.getY()
		end
	end,

	mousepressed = function(self, x, y, button)
		if button == 1 then
			self.isDragging = true

			self.prev.x, self.prev.y = x, y
		end
	end,

	mousereleased = function(self, x, y, button)
		if button == 1 then
			self.isDragging = false
		end
	end
}

local gpu = love.graphics
local screenWidth, screenHeight = gpu.getWidth(), gpu.getHeight()

local juliaSet, juliaSetIsDrawed = nil, false
local minimap, minimapIsDrawed = nil, false
local shader = nil

local const = {-0.0085, 0.71} --{-0.6655218, 0.234455}
local r = (1+math.sqrt(1+4*(const[1]*const[1]+const[2]*const[2])))/2 + 0.6

local isChangingIterations = false
local iterationDelta = 6
local iterationsMax = 10

local zoom = 1.0
local zoomDelta = 0.0271
local shift = {0.0, 0.0}
local shiftDelta = -0.05

local iterations = 2^iterationDelta

local selector = sel.new(gpu, screenWidth-65, 65, const[1], -const[2], 60, 6)

local function bound(v, min, max)
	return (v > max) and max or (v < min) and min or v
end

function love.keypressed(key)
	if key == "kp+" then
		if (isChangingIterations) then
    		iterationDelta = bound(iterationDelta+1, 1, iterationsMax)
    		iterations = 2^iterationDelta
    	else
        	zoom = bound(zoom - zoomDelta, zoomDelta, 1.0)
        end
	elseif key == "kp-" then
		if (isChangingIterations) then
    		iterationDelta = bound(iterationDelta-1, 1, iterationsMax)
    		iterations = 2^iterationDelta
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

	juliaSetIsDrawed = false
end

function love.keyreleased(key)
	if key == "lctrl" then
		isChangingIterations = false
	end
end

function love.wheelmoved(dx, dy)
    if dy > 0 then
    	if (isChangingIterations) then
    		iterationDelta = bound(iterationDelta+1, 1, iterationsMax)
    		iterations = 2^iterationDelta
    	else
        	zoom = bound(zoom - zoomDelta*zoom, 0, 1.0)
        end
    elseif dy < 0 then
    	if (isChangingIterations) then
    		iterationDelta = bound(iterationDelta-1, 1, iterationsMax)
    		iterations = 2^iterationDelta
    	else
        	zoom = bound(zoom + zoomDelta*zoom, 0, 1.0)
        end
    end

    juliaSetIsDrawed = false
end

function love.mousepressed(x, y, button)
	mouse:mousepressed(x, y, button)

	juliaSetIsDrawed = false
end

function love.mousereleased(x, y, button)
	mouse:mousereleased(x, y, button)
end

function love.load()
	love.window.setTitle("Julia set viewer")
	love.window.setMode(800, 600, {vsync=true, stencil=false})

	gpu.setBackgroundColor(0.98, 0.98, 0.98)
	gpu.setColor(0.1, 0.1, 0.1)

	local julia = [[
		extern float iterations;
		extern float radius;
		extern float zoom;
		extern vec2 shift;
		extern vec2 constant;

        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
        {
        	vec2 point = (((2*radius)*pixel_coords.xy/love_ScreenSize.xy - radius) * zoom) + shift.xy;

        	float j;
			for (j = 0; j < iterations && dot(point, point) < radius*radius; ++j)
				point = vec2(point.x*point.x - point.y*point.y, 2*point.x*point.y) + constant;

            return vec4(0.0, 0.1373, 0.4, j / iterations);
        }
    ]]

    juliaSet = gpu.newCanvas()
    minimap = gpu.newCanvas()
    shader = gpu.newShader(julia)
end

function love.update(dt)
	selector:update(dt, mouse)
	const[1], const[2] = selector.value.x, -selector.value.y

	if mouse.isDragging and not selector.isSelecting then
		local x, y = love.mouse.getX(), love.mouse.getY()

		shift[1] = shift[1] - (x - mouse.prev.x) * zoom * dt
		shift[2] = shift[2] - (y - mouse.prev.y) * zoom * dt
	end

	if mouse.isDragging or selector.isSelecting then
		juliaSetIsDrawed = false
	end

	if selector.isSelecting then
		minimapIsDrawed = false
	end

	mouse:update()
end

function love.draw()
	if not juliaSetIsDrawed then
		gpu.setCanvas(juliaSet)
			gpu.clear()
			gpu.setShader(shader)
				shader:send("iterations", iterations)
				shader:send("radius",     r)
				shader:send("zoom",       zoom)
				shader:send("shift",      shift)
				shader:send("constant",   const)
			    gpu.rectangle('fill', 0, 0, gpu.getWidth(), gpu.getHeight())
			gpu.setShader()
		gpu.setCanvas()

		juliaSetIsDrawed = true
	end

	if not minimapIsDrawed then
		gpu.setCanvas(minimap)
			gpu.clear()
			gpu.setShader(shader)
				shader:send("iterations", 32)
				shader:send("radius",     r)
				shader:send("zoom",       1)
				shader:send("shift",      {0, 0})
				shader:send("constant",   const)
			    gpu.rectangle('fill', 0, 0, gpu.getWidth(), gpu.getHeight())
			gpu.setShader()
		gpu.setCanvas()

		minimapIsDrawed = true
	end

	gpu.draw(juliaSet)
	gpu.setColor(1, 1, 1, 0.75)
	gpu.circle("fill", -5 + screenWidth-0.1*screenHeight, -5 + 0.9*screenHeight, 0.1*screenHeight)
	gpu.setColor(0, 0, 0)
	gpu.circle("line", -5 + screenWidth-0.1*screenHeight, -5 + 0.9*screenHeight, 0.1*screenHeight)
	gpu.draw(minimap, -5 + 0.9*screenWidth - 0.1*screenHeight, -5 + 0.8*screenHeight, 0, 0.2, 0.2)

	local minimapShiftX, minimapShiftY = (0.2*screenWidth)*shift[1]/(2*r), (0.2*screenHeight)*shift[2]/(2*r)
	gpu.setColor(1, 0, 0)
	gpu.circle("line", -5 + screenWidth-0.1*screenHeight + minimapShiftX, -5 + 0.9*screenHeight + minimapShiftY, 0.1*screenHeight * zoom)
	gpu.circle("fill", -5 + screenWidth-0.1*screenHeight + minimapShiftX, -5 + 0.9*screenHeight + minimapShiftY, 2)

	selector:draw()

	gpu.setColor(0.1, 0.1, 0.1)
	gpu.print("FPS: " .. love.timer.getFPS(), 0, 0)
	gpu.print("Precision: " .. iterations .. ", radius: " .. r, 0, 10)
	gpu.print("C = " .. const[1] .. ((const[2] > 0) and " + " or " - ") .. math.abs(const[2]) .. "i", 0, 20)
end
