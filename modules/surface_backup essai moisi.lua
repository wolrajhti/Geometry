local Surface = {}
Surface.__index = Surface

local function new(triangles)
	local surface = {}

	--création des points et des triangles
	surface.vertices = {}
	surface.vIndex = {}
	surface.index = {}
	surface.triangles = {}
	for i, t in ipairs(triangles) do
		for j = 1, 5, 2 do
			local x, y = t[j], t[j + 1]
			if not surface.index[x] then
				table.insert(surface.vertices, Vector(x, y))
				surface.vIndex[surface.vertices[#surface.vertices]] = #surface.vertices
				surface.index[x] = {}
				surface.index[x][y] = #surface.vertices
			elseif not surface.index[x][y] then
				table.insert(surface.vertices, Vector(x, y))
				surface.vIndex[surface.vertices[#surface.vertices]] = #surface.vertices
				surface.index[x][y] = #surface.vertices
			end
		end
		
		
			-- surface.index[t[j]] = surface.index[t[j]] or {}
			-- if not surface.index[t[j]][t[j + 1]] then
				-- table.insert(surface.vertices, Vector(t[j], t[j + 1]))
				-- surface.index[t[j]][t[j + 1]] = surface.vertices[#surface.vertices]
			-- end
		-- end
		table.insert(surface.triangles, {surface.index[t[1]][t[2]], surface.index[t[3]][t[4]], surface.index[t[5]][t[6]]})
		-- debug:write(string.format('triangle %d : p1 = %f, %f; p2 = %f, %f; p3 = %f, %f;\n',
			-- i,
			-- surface.triangles[#surface.triangles][1].x,
			-- surface.triangles[#surface.triangles][1].y,
			-- surface.triangles[#surface.triangles][2].x,
			-- surface.triangles[#surface.triangles][2].y,
			-- surface.triangles[#surface.triangles][3].x,
			-- surface.triangles[#surface.triangles][3].y
			-- )
		-- )
		debug:write(string.format('triangle %d : \tp1 = %d; \tp2 = %d; \tp3 = %d;\n',
			i,
			surface.triangles[#surface.triangles][1],
			surface.triangles[#surface.triangles][2],
			surface.triangles[#surface.triangles][3]
			)
		)
	end
	
	-- for i, t in ipairs(surface.triangles) do
		-- debug:write(string.format('triangle %d : p1 = %f, %f; p2 = %f, %f; p3 = %f, %f;\n',
			-- i,
			-- t[1].x,
			-- t[1].y,
			-- t[2].x,
			-- t[2].y,
			-- t[3].x,
			-- t[3].y
			-- )
		-- )
	-- end
	
	--création des triangles
	-- t[1], t[2], t[3] = vertices
	-- t[4], t[5], t[6] = neigbhor (triangle)
	-- surface.triangles ={}
	-- for i, t in ipairs(triangles) do
		-- table.insert(surface.triangles, {surface.index[t[1]][t[2]], surface.index[t[3]][t[4]], surface.index[t[5]][t[6]]})
	-- end
	
	--création des voisinnages
	local u, v = {}, {}
	local mod = function(v) return (v - 1) % 3 + 1 end
	for i = 1, #surface.triangles - 1 do
		u = surface.triangles[i]
		for j = i + 1, #surface.triangles do
			v = surface.triangles[j]
			for k = 1, 3 do
				for l = 1, 3 do
					if u[k] == v[l] then
						for m = 1, 2 do
							if u[mod(k + m)] == v[mod(l - m)] then
								u[mod(k + 2 * m) + 3] = j
								v[mod(l - 2 * m) + 3] = i 
							end
						end
					end
				end
			end
		end
	end
	
	--configuration des voisinnages
	-- for i, t in ipairs(surface.triangles) do
		-- for j = 1, 3 do
			-- if t[j + 3] then
				-- local intersections = {}
				-- local a, b = t[mod(j + 1)], t[mod(j + 2)]
				-- for k, u in ipairs(surface.triangles) do
					-- for l = 1, 3 do
						-- if not u[l + 3] then
							-- local c, d = u[mod(l + 1)], u[mod(l + 2)]
							-- table.insert(intersections, (d - c):cross(a - c) / (b - a):cross(d - c))
						-- end
					-- end
				-- end
				-- table.sort(intersections)
				-- if #intersections ~= 0 then
					-- local first, last = 0, 1
					-- for m, r in ipairs(intersections) do
						-- if r < 0 then first = r end
						-- if r > 1 then last = r end
					-- end
					-- local width = (a + (b - a) * last - (a + (b - a) * first)):norm()
					-- t[j + 6] = (first + last) / 2
					-- t[j + 9] = width
				-- end
			-- end
		-- end
	-- end
	
	for i, t in ipairs(surface.triangles) do
		debug:write(string.format('voisinnage de triangle %d : t1 = %d; t2 = %d; t3 = %d;\n', i, t[4], t[5], t[6]))
	end
	
	--création des couleurs
	surface.colors = {}
	for i, t in ipairs(surface.triangles) do
		table.insert(surface.colors, {math.random(1, 255), math.random(1, 255), math.random(1, 255), 100})
	end
	
	return setmetatable(surface, Surface)
end

function Surface:locate(vector)
	for i, t in ipairs(self.triangles) do
		if self.pointinpoly(vector, {t[1], t[2], t[3]}) then
			return t
		end
	end
end

function Surface.pointinpoly(pt, poly)
	local p, q, c = poly[#poly], poly[1], false
	for i = 1, #poly do
		if (p.y >= pt.y) ~= (q.y >= pt.y) and pt.x <= (q.x - p.x) * (pt.y - p.y) / (q.y - p.y) + p.x then
			c = not c
		end
		p, q = q, poly[i + 1]
	end
	return c
end

function Surface.intersegment(a, b, c, d)
	local ab, cd, ac = b - a, d - c, c - a
	if ac:cross(cd) * (c - b):cross(cd) < 0 and -ac:cross(ab) * (a - d):cross(ab) < 0 then
		return true
	end
end

function Surface.validsegment(a, b, c, d)
	local ba, ca, bd, cd = a - b, a - c, d - b, d - c
	if ba:dot(ca) * bd:cross(cd) < bd:dot(cd) * ba:cross(ca) then
		return true
	end
end

function Surface.proj(v, a, b)
	local coef = (v - a):normalize():dot((b - a):normalize()) * (v - a):norm() / (b - a):norm()
	return a + math.min(math.max(0, coef), 1) * (b - a)
end

function Surface:draw()
	local a, b, c = {}, {}, {}
	local mod = function(v) return (v - 1) % 3 + 1 end
	for i, t in ipairs(self.triangles) do
		if DEBUG then love.graphics.setColor(self.colors[i])
		else love.graphics.setColor(255, 255, 255, 200) end
		a, b, c = t[1], t[2], t[3]
		love.graphics.polygon("fill", a.x, a.y, b.x, b.y, c.x, c.y) 
	end
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.print(#self.vertices, 16, 16)
	love.graphics.print(#self.triangles, 16, 32)
	love.graphics.setColor(0, 0, 255, 255)
	for i, t in ipairs(self.triangles) do
		for j = 1, 3 do
			if not t[j + 3] then
				love.graphics.line(t[mod(j + 1)].x, t[mod(j + 1)].y, t[mod(j + 2)].x, t[mod(j + 2)].y)
			end
		end
	end
	------------------------------------INTERSECTIONS--------------------------
	-- for i, t in ipairs(self.triangles) do
		-- for j = 1, 3 do
			-- if not t[j + 3] then
				-- local v = t[j]
				-- local n = (v.next - v):rotate(math.pi / 2):normalize(15)
				-- local p = (v.prev - v):rotate(-math.pi / 2):normalize(15)
				-- love.graphics.setColor(0, 255, 0, 255)
				-- love.graphics.line(v.x, v.y, v.x + n.x, v.y + n.y)
				-- love.graphics.setColor(255, 0, 0, 255)
				-- love.graphics.line(v.x, v.y, v.x + p.x, v.y + p.y)
			-- end
		-- end
	-- end
end

return setmetatable({new = new}, {__call = function(_, ...) return new(...) end})