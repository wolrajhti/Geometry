local Surface = {}
Surface.__index = Surface

local function new(...)
	local surface = {vertices = {}, index = {}, triangles = {}, colors = {}}
	--[[
	t[1], t[2], t[3] = vertices
	t[4], t[5], t[6] = neigbhor (triangle)
	t[7], t[8], t[9] = time of middle of edge (ex : middle = t[2] + t[7] * (t[3] - t[2]))
	t[10], t[11], t[12] = max width
	]]
	local coordinates = {...}
	local triangles = love.math.triangulate(...)
	local x, y = 0, 0
	--création des points
	for i = 1, #coordinates, 2 do
		x, y = coordinates[i], coordinates[i + 1]
		if not surface.index[x] then
			table.insert(surface.vertices, Vector(x, y))
			surface.index[x] = {}
			-- surface.index[x][y] = surface.vertices[#surface.vertices] -21/05/16
			surface.index[x][y] = #surface.vertices --21/05/16
		elseif not surface.index[x][y] then
			table.insert(surface.vertices, Vector(x, y))
			-- surface.index[x][y] = surface.vertices[#surface.vertices] --21/05/16
			surface.index[x][y] = #surface.vertices --21/05/16
		end
	end
	--création des triangles
	for i, t in ipairs(triangles) do
		table.insert(surface.triangles, {surface.index[t[1]][t[2]], surface.index[t[3]][t[4]], surface.index[t[5]][t[6]]})
	end
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
	--création des normales
	-- for i, t in ipairs(surface.triangles) do
		-- for j = 1, 3 do
			-- if not t[j + 3] then
				-- t[mod(j + 1)].next = t[mod(j + 2)]
				-- t[mod(j + 2)].prev = t[mod(j + 1)]
			-- end
		-- end
	-- end
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
	--création des couleurs
	for i, t in ipairs(surface.triangles) do
		table.insert(surface.colors, {math.random(1, 255), math.random(1, 255), math.random(1, 255), 100})
	end
	return setmetatable(surface, Surface)
end

function Surface.mod(v) return (v - 1) % 3 + 1 end

function Surface:getVertex(i, j) --21/05/16
	return self.vertices[self.triangles[i][j]]
end

function Surface:getVertices(i) --21/05/16
	return self.vertices[self.triangles[i][1]], self.vertices[self.triangles[i][2]], self.vertices[self.triangles[i][3]]
end

function Surface:getCoordinates(i) --21/05/16
	local a, b, c = self:getVertices(i)
	return a.x, a.y, b.x, b.y, c.x, c.y
end

function Surface:getCoordinatesFromVerticesIndex(indexes)
	local res = {}
	for i, index in ipairs(indexes) do
		table.insert(res, self.vertices[index].x)
		table.insert(res, self.vertices[index].y)
	end
	return res
end

function Surface:locate(vector)
	for i, t in ipairs(self.triangles) do
		-- if self.pointinpoly(vector, {t[1], t[2], t[3]}) then
		if self.pointinpoly(vector, {self:getVertices(i)}) then --21/05/16
			return t
		end
	end
end

function Surface:removeTriangle(t) --20/05/16
	for i, tri in ipairs(self.triangles) do
		if tri == t then
			for j = 4, 6 do
				if tri[j] then
					for k = 4, 6 do
						if self.triangles[tri[j]][k] and self.triangles[tri[j]][k] == i then
							self.triangles[tri[j]][k] = nil
						end
					end
				end
			end
			table.remove(self.triangles, i)
			for j, T in ipairs(self.triangles) do
				for k = 4, 6 do
					if T[k] and T[k] >= i then
						T[k] = T[k] - 1
					end
				end
			end
			break
		end
	end
end

function Surface:getOpposite(ta, tb) --20/05/16
	if ta ~= tb then
		for i = 1, 3 do
			if self.triangles[ta[i + 3]] == tb then return self.vertices[ta[i]] end
		end
	end
end

function Surface:tunnel(a, b) --20/05/16
	local ta, tb = self:locate(a), self:locate(b)
	if ta and tb then
		local t = ta
		local mod = function(v) return (v - 1) % 3 + 1 end
		-- local res = {{t[1].x, t[1].y, t[2].x, t[2].y, t[3].x, t[3].y}}
		local res = {t}
		local from
		while t ~= tb do
			for i = 1, 3 do
				if self.triangles[t[mod(i - 1) + 3]] and self.triangles[t[mod(i - 1) + 3]] ~= from and self.intersegment(self.vertices[t[i]], self.vertices[t[mod(i + 1)]], a, b) then
					from = t
					t = self.triangles[t[mod(i - 1) + 3]]
					-- table.insert(res, {t[1].x, t[1].y, t[2].x, t[2].y, t[3].x, t[3].y})
					table.insert(res, t)
					break
				end
				if i == 3 then return end
			end
		end
		return res, self:getOpposite(res[1], res[math.min(2, #res)]), self:getOpposite(res[#res], res[math.max(#res - 1, 1)])
	end
end

function Surface:getLeftBoundary(tunnel) --22/05/16
	local b = {}
	local vIdx, tIdx = 1, 1
	for i = 1, 3 do
		if self.triangles[tunnel[tIdx][i + 3]] and self.triangles[tunnel[tIdx][i + 3]] == tunnel[tIdx + 1] then
			table.insert(b, tunnel[tIdx][i])
			vIdx = i
			break
		end
	end
	debug:write(string.format('vIdx, tIdx = %d, %d\n', vIdx, tIdx))
	while tIdx < #tunnel do
		debug:write(string.format('\t\tb[#b] = %d\n', b[#b]))
		debug:write(string.format('\t\tvIdx, tIdx = %d, %d\n', vIdx, tIdx))
		-- if not tunnel[tIdx][self.mod(vIdx + 2) + 3] then
		if not self:findTriInTunnel(tunnel, tunnel[tIdx][self.mod(vIdx + 2) + 3]) then
			debug:write('\t\tnot tunnel['..tIdx..']['..(self.mod(vIdx + 2) + 3)..']\n')
			table.insert(b, tunnel[tIdx][self.mod(vIdx + 1)])
		end
		tIdx = tIdx + 1
		for i = 1, 3 do
			if tunnel[tIdx][i] == b[#b] then
				debug:write('\t\ttunnel['..tIdx..']['..i..'] == '..b[#b]..'\n')
				vIdx = i
				break
			end
		end
		debug:write('\n\n\n')
	end
	for i = 1, 3 do
		if self.triangles[tunnel[tIdx][i + 3]] and self.triangles[tunnel[tIdx][i + 3]] == tunnel[tIdx - 1] then
			table.insert(b, tunnel[tIdx][i])
			vIdx = i
			break
		end
	end
	return b
end

function Surface:getRightBoundary(tunnel) --22/05/16
	local b = {}
	local vIdx, tIdx = 1, 1
	for i = 1, 3 do
		if self.triangles[tunnel[tIdx][i + 3]] and self.triangles[tunnel[tIdx][i + 3]] == tunnel[tIdx + 1] then
			table.insert(b, tunnel[tIdx][i])
			vIdx = i
			break
		end
	end
	debug:write(string.format('vIdx, tIdx = %d, %d\n', vIdx, tIdx))
	while tIdx < #tunnel do
		debug:write(string.format('\t\tb[#b] = %d\n', b[#b]))
		debug:write(string.format('\t\tvIdx, tIdx = %d, %d\n', vIdx, tIdx))
		-- if not tunnel[tIdx][self.mod(vIdx + 2) + 3] then
		if not self:findTriInTunnel(tunnel, tunnel[tIdx][self.mod(vIdx - 2) + 3]) then
			debug:write('\t\tnot tunnel['..tIdx..']['..(self.mod(vIdx - 2) + 3)..']\n')
			table.insert(b, tunnel[tIdx][self.mod(vIdx - 1)])
		end
		tIdx = tIdx + 1
		for i = 1, 3 do
			if tunnel[tIdx][i] == b[#b] then
				debug:write('\t\ttunnel['..tIdx..']['..i..'] == '..b[#b]..'\n')
				vIdx = i
				break
			end
		end
		debug:write('\n\n\n')
	end
	for i = 1, 3 do
		if self.triangles[tunnel[tIdx][i + 3]] and self.triangles[tunnel[tIdx][i + 3]] == tunnel[tIdx - 1] then
			table.insert(b, tunnel[tIdx][i])
			vIdx = i
			break
		end
	end
	return b
end

function Surface:findTriInTunnel(tunnel, tri)
	if tri then
		for i, t in ipairs(tunnel) do
			if t == self.triangles[tri] then return true end
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
	-- local a, b, c = {}, {}, {}
	local mod = function(v) return (v - 1) % 3 + 1 end
	for i, t in ipairs(self.triangles) do
		if DEBUG then love.graphics.setColor(self.colors[i])
		else love.graphics.setColor(255, 255, 255, 200) end
		-- a, b, c = t[1], t[2], t[3]
		-- love.graphics.polygon("fill", a.x, a.y, b.x, b.y, c.x, c.y) 
		love.graphics.polygon("fill", self:getCoordinates(i)) --21/05/16
	end
	love.graphics.setColor(255, 255, 255, 255)
	love.graphics.print(#self.vertices, 16, 16)
	love.graphics.print(#self.triangles, 16, 32)
	love.graphics.setColor(0, 0, 255, 255)
	for i, t in ipairs(self.triangles) do
		for j = 1, 3 do
			if not t[j + 3] then
				-- love.graphics.line(t[mod(j + 1)].x, t[mod(j + 1)].y, t[mod(j + 2)].x, t[mod(j + 2)].y)
				love.graphics.line(self.vertices[t[mod(j + 1)]].x, self.vertices[t[mod(j + 1)]].y,
				self.vertices[t[mod(j + 2)]].x, self.vertices[t[mod(j + 2)]].y) --21/05/16
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