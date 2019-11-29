local function map(x, in_min, in_max, out_min, out_max)
	return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min
end

local function new(g, px, py, vx, vy, bcr, scr)
	local g = g

	return
	{
		isSelecting = false,

		pos = {x = px, y = py},
		value = {x = vx, y = vy},

		boundaryCircleRadius = bcr,
		selectorCircleRadius = scr,

		draw = function(self)
			-- cross --
			g.setColor(0.1, 0.1, 0.1)
			g.line(self.pos.x - self.selectorCircleRadius/2, self.pos.y, self.pos.x + self.selectorCircleRadius/2, self.pos.y)
			g.line(self.pos.x, self.pos.y - self.selectorCircleRadius/2, self.pos.x, self.pos.y + self.selectorCircleRadius/2)

			-- boundary --
			g.setColor(0.1, 0.1, 0.1)
			g.circle("line", self.pos.x, self.pos.y, self.boundaryCircleRadius)

			-- selector --
			g.setColor(0.98, 0.1, 0.1)
			g.circle("line", self.pos.x + self.value.x*self.boundaryCircleRadius, self.pos.y + self.value.y*self.boundaryCircleRadius, self.selectorCircleRadius + 2)
			g.circle("fill", self.pos.x + self.value.x*self.boundaryCircleRadius, self.pos.y + self.value.y*self.boundaryCircleRadius, 2)

			-- initial constant value --
			local str = string.format("C = %.3f %s %.3fi", self.value.x, (self.value.y > 0) and '+' or '-', math.abs(self.value.y))

			g.setColor(0.1, 0.1, 0.1, 0.75)
			g.print(str, self.pos.x - g.getFont():getWidth(str)/2, self.pos.y + self.boundaryCircleRadius)
		end,

		update = function(self, dt, mouse)
			local mx, my = love.mouse.getX(), love.mouse.getY()

			if mouse.isDragging then
				if (mx-self.pos.x-self.value.x*self.boundaryCircleRadius)^2 + (my-self.pos.y-self.value.y*self.boundaryCircleRadius)^2 < self.selectorCircleRadius^2 then
					self.isSelecting = true
				end
			else
				self.isSelecting = false
			end

			if self.isSelecting then
				self.value.x = map(mx, love.graphics.getWidth()-self.boundaryCircleRadius*2 - 5, love.graphics.getWidth() - 5, -1, 1)
				self.value.y = map(my, 5, self.boundaryCircleRadius*2 + 5, -1, 1)

				if self.value.x^2 + self.value.y^2 > 1 then
					local len = math.sqrt(self.value.x^2 + self.value.y^2)

					self.value.x, self.value.y = self.value.x/len, self.value.y/len
				end
			end
		end
	}
end

return
{
	new = new
}
