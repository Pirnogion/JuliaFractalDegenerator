local function new(g, px, py, vx, vy, bcr, scr)
	local g = g

	return
	{
		isSelecting = false,

		pos = {x = px, y = py},
		value = {x = vx, y = vy},

		boundaryCircleRadius = bcr,
		selectorCircleRadius = scr,

		style = {
			outline = {
				thickness = 3,
				color = {0.1, 0.1, 0.1}
			},

			lines = {
				thickness = 1,
				color = {0.98, 0.98, 0.98}
			},
		},

		draw = function(self)
			-- cross --
			g.setColor(self.style.outline.color)
			g.setLineWidth(self.style.lines.thickness)
			g.line(self.pos.x - self.selectorCircleRadius/2, self.pos.y, self.pos.x + self.selectorCircleRadius/2, self.pos.y)
			g.line(self.pos.x, self.pos.y - self.selectorCircleRadius/2, self.pos.x, self.pos.y + self.selectorCircleRadius/2)

			-- boundary and selector --
			g.setColor(self.style.outline.color)
			g.setLineWidth(self.style.outline.thickness)
			g.circle("line", self.pos.x, self.pos.y, self.boundaryCircleRadius)
			g.circle("fill", self.pos.x + self.value.x*self.boundaryCircleRadius, self.pos.y + self.value.y*self.boundaryCircleRadius, self.selectorCircleRadius + 2)

			g.setColor(self.style.lines.color)
			g.setLineWidth(self.style.lines.thickness)
			g.circle("line", self.pos.x, self.pos.y, self.boundaryCircleRadius)
			g.circle("fill", self.pos.x + self.value.x*self.boundaryCircleRadius, self.pos.y + self.value.y*self.boundaryCircleRadius, self.selectorCircleRadius)

			-- initial constant value --
			local str = string.format("C = %.3f %s %.3fi", self.value.x, (self.value.y > 0) and '+' or '-', math.abs(self.value.y))

			g.setColor(self.style.outline.color)
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
				self.value.x = self.value.x + (mx - mouse.prev.x) * 1/2 * dt
				self.value.y = self.value.y + (my - mouse.prev.y) * 1/2 * dt

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
