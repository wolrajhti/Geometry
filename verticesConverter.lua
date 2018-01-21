local class = require 'middleclass'
local VerticesConverter = class('VerticesConverter')

local Vector = require 'geometry.vector'

function VerticesConverter:initialize()
end

function VerticesConverter.getVertices(args)
	local vertices = {}
	if #args == 1 then args = args[1] end
	for i = 1, #args - 1, 2 do
		table.insert(vertices, Vector(args[i], args[i + 1]))
	end
	return vertices
end

function VerticesConverter.getVerticesFromCells(cell_size, cells)
	local vertices = {}
	for i, cell in ipairs(cells) do
		table.insert(vertices, Vector(cell_size * (cell.i + 0.5), cell_size * (cell.j + 0.5)))
	end
	return vertices
end

function VerticesConverter:getBezier(cPts)
	local args = {}
	for i, cPt in ipairs(cPts) do
		table.insert(args, cPt.x)
		table.insert(args, cPt.y)
	end
	-- return self.getVertices(love.math.newBezierCurve(args):render(2))
	return self.getVertices(love.math.newBezierCurve(args):render())
end

function VerticesConverter.clean(vertices)
	for i = #vertices, 2, -1 do
		if vertices[i]:dist(vertices[i - 1]) == 0 then table.remove(vertices, i) end
	end
	-- TODO : ajouter la suppression des points en trop
end

return VerticesConverter
