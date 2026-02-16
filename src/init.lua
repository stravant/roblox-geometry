local Geometry = {}

local UniformScale = Vector3.new(1, 1, 1)

local function getShape(part)
	if part:IsA('WedgePart') then
		return 'Wedge', UniformScale
	elseif part:IsA('CornerWedgePart') then
		return 'CornerWedge', UniformScale
	elseif part:IsA('Terrain') then
		return 'Terrain', UniformScale
	elseif part:IsA('UnionOperation') then
		return 'Brick', UniformScale
	elseif part:IsA('MeshPart') then
		return 'Brick', UniformScale
	elseif part:IsA('Part') then
		-- BasePart
		if part.Shape == Enum.PartType.Ball then
			return 'Sphere', UniformScale
		elseif part.Shape == Enum.PartType.Cylinder then
			return 'Cylinder', UniformScale
		elseif part.Shape == Enum.PartType.Block then
			return 'Brick', UniformScale
		elseif part.Shape == Enum.PartType.CornerWedge then
			return 'CornerWedge', UniformScale
		elseif part.Shape == Enum.PartType.Wedge then
			return 'Wedge', UniformScale
		else
			assert(false, "Unreachable")
		end
	else
		return 'Brick', UniformScale
	end
end

type UnitVector3 = Vector3

type GeometryVertex = {
	id: number,
	position: Vector3,
	type: "Vertex",
}

type GeometryEdge = {
	id: number,
	a: Vector3,
	b: Vector3,
	direction: UnitVector3,
	length: number,
	edgeMargin: number,
	vertexMargin: number,
	part: BasePart,
	type: "Edge",
}

type SurfaceType = "BottomSurface" | "TopSurface" | "LeftSurface" | "RightSurface" | "FrontSurface" | "BackSurface"

type GeometryFace = {
	id: number,
	point: Vector3,
	normal: UnitVector3,
	surface: SurfaceType,
	direction: UnitVector3,
	vertices: {Vector3},
	part: BasePart,
	type: "Face",
}

type GeometryResult = {
	part: BasePart,
	shape: "Sphere" | "Cylinder" | "Mesh",
	vertices: {GeometryVertex},
	edges: {GeometryEdge},
	faces: {GeometryFace},
	vertexMargin: number,
}

function Geometry.getGeometry(part: BasePart, hit: Vector3, assumedCFrame: CFrame?): GeometryResult
	local cf = assumedCFrame or part.CFrame
	local pos = cf.Position

	local sx = part.Size.x/2
	local sy = part.Size.y/2
	local sz = part.Size.z/2

	local xvec = cf.RightVector
	local yvec = cf.UpVector
	local zvec = -cf.LookVector

	local verts, edges, faces;

	local shape, scale = getShape(part)

	sx = sx * scale.X
	sy = sy * scale.Y
	sz = sz * scale.Z

	if shape == 'Brick' or shape == 'Sphere' or shape == 'Cylinder' then
		--8 vertices
		verts = {
			pos +xvec*sx  +yvec*sy  +zvec*sz, --top 4
			pos +xvec*sx  +yvec*sy  -zvec*sz,
			pos -xvec*sx  +yvec*sy  +zvec*sz,
			pos -xvec*sx  +yvec*sy  -zvec*sz,
			--
			pos +xvec*sx  -yvec*sy  +zvec*sz, --bottom 4
			pos +xvec*sx  -yvec*sy  -zvec*sz,
			pos -xvec*sx  -yvec*sy  +zvec*sz,
			pos -xvec*sx  -yvec*sy  -zvec*sz,
		}
		--12 edges
		edges = {
			{verts[1], verts[2], math.min(2*sx, 2*sy)}, --top 4
			{verts[3], verts[4], math.min(2*sx, 2*sy)},
			{verts[1], verts[3], math.min(2*sy, 2*sz)},
			{verts[2], verts[4], math.min(2*sy, 2*sz)},
			--
			{verts[5], verts[6], math.min(2*sx, 2*sy)}, --bottom 4
			{verts[7], verts[8], math.min(2*sx, 2*sy)},
			{verts[5], verts[7], math.min(2*sy, 2*sz)},
			{verts[6], verts[8], math.min(2*sy, 2*sz)},
			--
			{verts[1], verts[5], math.min(2*sx, 2*sz)}, --verticals
			{verts[2], verts[6], math.min(2*sx, 2*sz)},
			{verts[3], verts[7], math.min(2*sx, 2*sz)},
			{verts[4], verts[8], math.min(2*sx, 2*sz)},
		}
		--6 faces
		faces = {
			{verts[1],  xvec, 'RightSurface',  zvec, {verts[5], verts[6], verts[2], verts[1]}}, --right
			{verts[3], -xvec, 'LeftSurface',   zvec, {verts[3], verts[4], verts[8], verts[7]}}, --left
			{verts[1],  yvec, 'TopSurface',    xvec, {verts[1], verts[2], verts[4], verts[3]}}, --top
			{verts[5], -yvec, 'BottomSurface', xvec, {verts[7], verts[8], verts[6], verts[5]}}, --bottom
			{verts[1],  zvec, 'BackSurface',   xvec, {verts[1], verts[3], verts[7], verts[5]}}, --back
			{verts[2], -zvec, 'FrontSurface',  xvec, {verts[6], verts[8], verts[4], verts[2]}}, --front
		}
	elseif shape == 'Sphere' or shape == 'Cylinder' then
		-- Just have one face and vertex, at the hit pos
		verts = { hit }
		edges = {} --edge can be selected as the normal of the face if the user needs it
		local norm = (hit-pos).Unit
		local norm2 = norm:Cross(Vector3.new(0,1,0)).Unit

		local surfaceName
		if math.abs(norm.X) > math.abs(norm.Y) and math.abs(norm.X) > math.abs(norm.Z) then
			surfaceName = (norm.X > 0) and "RightSurface" or "LeftSurface"
		elseif math.abs(norm.Y) > math.abs(norm.Z) then
			surfaceName = (norm.Y > 0) and "TopSurface" or "BottomSurface"
		else
			surfaceName = (norm.Z > 0) and "BackSurface" or "FrontSurface"
		end
		faces = {
			{hit, norm, surfaceName, norm2, {}}
		}
	elseif shape == 'CornerWedge' then
		local slantVec1 = ( zvec*sy + yvec*sz).Unit
		local slantVec2 = (-xvec*sy + yvec*sx).Unit
		-- 5 verts
		verts = {
			pos +xvec*sx  +yvec*sy  -zvec*sz, --top 1
			--
			pos +xvec*sx  -yvec*sy  +zvec*sz, --bottom 4
			pos +xvec*sx  -yvec*sy  -zvec*sz,
			pos -xvec*sx  -yvec*sy  +zvec*sz,
			pos -xvec*sx  -yvec*sy  -zvec*sz,
		}
		-- 8 edges
		edges = {
			{verts[2], verts[3], 0}, -- bottom 4
			{verts[3], verts[5], 0},
			{verts[5], verts[4], 0},
			{verts[4], verts[2], 0},
			--
			{verts[1], verts[3], 0}, -- vertical
			--
			{verts[1], verts[2], 0}, -- side diagonals
			{verts[1], verts[5], 0},
			--
			{verts[1], verts[4], 0}, -- middle diagonal
		}
		-- 5 faces
		faces = {
			{verts[2], -yvec, 'BottomSurface', xvec, {verts[2], verts[3], verts[5], verts[4]}}, -- bottom
			--
			{verts[1],  xvec, 'RightSurface', -yvec, {verts[1], verts[3], verts[2]}}, -- sides
			{verts[1], -zvec, 'FrontSurface', -yvec, {verts[1], verts[3], verts[5]}},
			--
			{verts[1],  slantVec1, 'BackSurface', xvec, {verts[1], verts[2], verts[4]}}, -- tops
			{verts[1],  slantVec2, 'LeftSurface', zvec, {verts[1], verts[5], verts[4]}},
		}

	elseif shape == 'Wedge' then
		local slantVec = (-zvec*sy + yvec*sz).Unit
		--6 vertices
		verts = {
			pos +xvec*sx  +yvec*sy  +zvec*sz, --top 2
			pos -xvec*sx  +yvec*sy  +zvec*sz,
			--
			pos +xvec*sx  -yvec*sy  +zvec*sz, --bottom 4
			pos +xvec*sx  -yvec*sy  -zvec*sz,
			pos -xvec*sx  -yvec*sy  +zvec*sz,
			pos -xvec*sx  -yvec*sy  -zvec*sz,
		}
		--9 edges
		edges = {
			{verts[1], verts[2], math.min(2*sy, 2*sz)}, --top 1
			--
			{verts[1], verts[4], math.min(2*sy, 2*sz)}, --slanted 2
			{verts[2], verts[6], math.min(2*sy, 2*sz)},
			--
			{verts[3], verts[4], math.min(2*sx, 2*sy)}, --bottom 4
			{verts[5], verts[6], math.min(2*sx, 2*sy)},
			{verts[3], verts[5], math.min(2*sy, 2*sz)},
			{verts[4], verts[6], math.min(2*sy, 2*sz)},
			--
			{verts[1], verts[3], math.min(2*sx, 2*sz)}, --vertical 2
			{verts[2], verts[5], math.min(2*sx, 2*sz)},
		}
		--5 faces
		faces = {
			{verts[1],  xvec, 'RightSurface', zvec, {verts[4], verts[1], verts[3]}}, --right
			{verts[2], -xvec, 'LeftSurface', zvec, {verts[2], verts[6], verts[5]}}, --left
			{verts[3], -yvec, 'BottomSurface', xvec, {verts[5], verts[6], verts[4], verts[3]}}, --bottom
			{verts[1],  zvec, 'BackSurface', xvec, {verts[1], verts[2], verts[5], verts[3]}}, --back
			{verts[2], slantVec, 'FrontSurface', slantVec:Cross(xvec), {verts[2], verts[1], verts[4], verts[6]}}, --slanted
		}
	elseif shape == 'Terrain' then
		assert(false, "Called GetGeometry on Terrain")
	else
		assert(false, "Bad shape: "..shape)
	end

	local geometry = {
		part = part;
		shape = (shape == 'Sphere' or shape == 'Cylinder') and shape or 'Mesh';
		vertices = verts;
		edges = edges;
		faces = faces;
		vertexMargin = math.min(sx, sy, sz) * 2;
	}

	local geomId = 0

	for _, dat in ipairs(faces) do
		geomId = geomId + 1
		dat.id = geomId
		dat.point = dat[1]
		dat.normal = dat[2]
		dat.surface = dat[3]
		dat.direction = dat[4]
		dat.vertices = dat[5]
		dat.part = part
		dat.type = 'Face'
		--avoid Event bug (if both keys + indicies are present keys are discarded when passing tables)
		dat[1], dat[2], dat[3], dat[4] = nil, nil, nil, nil
	end
	for _, dat in ipairs(edges) do
		geomId = geomId + 1
		dat.id = geomId
		dat.a, dat.b = dat[1], dat[2]
		dat.direction = (dat.b - dat.a).Unit
		dat.length = (dat.b - dat.a).Magnitude
		dat.edgeMargin = dat[3]
		dat.part = part
		dat.vertexMargin = geometry.vertexMargin
		dat.type = 'Edge'
		--avoid Event bug (if both keys + indicies are present keys are discarded when passing tables)
		dat[1], dat[2], dat[3] = nil, nil, nil
	end
	for i, dat in ipairs(verts) do
		geomId = geomId + 1
		verts[i] = {
			position = dat;
			id = geomId;
			type = 'Vertex';
		}
	end

	return geometry
end

-- Get any perpendicular vector
local function perpendicularVector(v: Vector3): UnitVector3
	local differentVec;
	if math.abs(v:Dot(Vector3.xAxis)) > 0.7 then
		differentVec = Vector3.yAxis
	else
		differentVec = Vector3.xAxis
	end
	return differentVec:Cross(v).Unit
end

local function findNearestInterestingPoint(mainBasis: CFrame, part: BasePart): (Vector3?, UnitVector3?)
	local OFF_SURFACE = 1.0
	local DOWN_VECTOR = -mainBasis.YVector * (part.Size.Magnitude + OFF_SURFACE)
	
	-- Explore outwards in a cross pattern, doubling the distance every time
	--      ^ +zBasis
	--      |
	--  <---O---> +xBasis
	--      |
	--      V
	local foundPointOnOtherPlane: Vector3?
	local hitNothingFrom: Vector3?
	do
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Whitelist
		params.FilterDescendantsInstances = {part}
		local distanceStep = 0.01
		for i = 1, 12 do
			for dx = -1, 1, 2 do
				for dz = -1, 1, 2 do
					local localPosition = Vector3.new(dx * distanceStep, OFF_SURFACE, dz * distanceStep)
					local castFrom = mainBasis:PointToWorldSpace(localPosition)
					local hit = workspace:Raycast(castFrom, DOWN_VECTOR, params)
					if hit then
						if math.abs(hit.Distance - OFF_SURFACE) > 0.001 then
							return hit.Position, hit.Normal
						end
					else
						-- We missed the mesh, move down a bit, and then cast back towards the
						-- origin to find the edge / backface we missed
						castFrom -= mainBasis.YVector * (OFF_SURFACE + 0.1)
						local backToOrigin = (mainBasis.Position - castFrom)
						local sideHit = workspace:Raycast(castFrom, backToOrigin, params)
						if sideHit then
							return sideHit.Position, sideHit.Normal
						end
					end
				end
			end
			distanceStep *= 2
		end
	end
	return nil, nil
end

local function intersectPlanePlane(p1: Vector3, n1: Vector3, p2: Vector3, n2: Vector3)
	local dir = n1:Cross(n2).Unit
	local a1 = n1:Cross(dir).Unit
	local a2 = n2:Cross(dir).Unit
	
	-- p1 + a1 * i = p2 + a2 * j
	-- (p1 - p2) = a1 * i + a2 * j
	-- ((p1 - p2) . a1) = i + (a1 . a2) * j
	-- ((p1 - p2) . a2) = (a1 . a2) * i + j
	--
	-- ((p1 - p2) . a1) - (a1 . a2) * j = i
	local a1a2 = a1:Dot(a2)
	local delta = p1 - p2
	local j = (delta:Dot(a2) - a1a2 * delta:Dot(a1)) / (1 - a1a2 * a1a2)
	local origin = p2 + a2 * j
	return origin, dir
end

-- Insersect Ray(a + t*b) with plane (origin: o, normal: n), return t of the interesection
local function intersectRayPlane(a, b, o, n): number
	return (o - a):Dot(n) / b:Dot(n)
end

-- Intersect Ray(a + t*b) with plane (origin: o, normal :n), and return the intersection as Vector3
local function intersectRayPlanePoint(a, b, o, n): Vector3
	local t = intersectRayPlane(a, b, o, n)
	return a + t * b;
end

local function exploreEdge(part: BasePart, origin: Vector3, dir: Vector3, normal: Vector3, normal2: Vector3): GeometryEdge?
	local MAX_LENGTH = part.Size.Magnitude
	local HOVER_POINT_1 = origin + normal * 0.01 - normal2 * 0.01
	local HOVER_POINT_2 = origin + normal2 * 0.01 - normal * 0.01
	local SINK_POINT = origin - normal * 0.01 - normal2 * 0.01
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Whitelist
	params.FilterDescendantsInstances = {part}
	
	local span = dir * MAX_LENGTH
	
	-- Find a positive clip plane for edge (origin, dir)
	local positiveHit = workspace:Raycast(HOVER_POINT_1, span, params)
	if not positiveHit then
		positiveHit = workspace:Raycast(HOVER_POINT_2, span, params)
	end
	if not positiveHit then
		positiveHit = workspace:Raycast(SINK_POINT + span, -span, params)
	end
	if not positiveHit then
		return nil
	end
	
	-- Find a negative clip plane for edge (origin, dir)
	local negativeHit = workspace:Raycast(HOVER_POINT_1, -span, params)
	if not negativeHit then
		negativeHit = workspace:Raycast(HOVER_POINT_2, -span, params)
	end
	if not negativeHit then
		negativeHit = workspace:Raycast(SINK_POINT - span, span, params)
	end
	if not negativeHit then
		return nil
	end
	
	-- Clip (origin, dir) by planes
	local positivePoint = intersectRayPlanePoint(origin, dir, positiveHit.Position, positiveHit.Normal)
	local negativePoint = intersectRayPlanePoint(origin, dir, negativeHit.Position, negativeHit.Normal)
	
	local edge = {}
	edge.a = positivePoint
	edge.b = negativePoint
	edge.direction = (edge.b - edge.a).Unit
	edge.length = (edge.b - edge.a).Magnitude
	edge.edgeMargin = 0.5
	edge.part = part
	edge.type = 'Edge'
	edge.inferred = true
	
	-- Figure out the vertex margin
	local testPart = part:Clone()
	testPart.Material = Enum.Material.Plastic
	testPart.CustomPhysicalProperties = nil
	local referencePart = Instance.new("Part")
	referencePart.Size = testPart.Size
	referencePart.CustomPhysicalProperties = nil
	local massFraction = testPart:GetMass() / referencePart:GetMass()
	edge.vertexMargin = math.min(part.Size.X, part.Size.Y, part.Size.Z) * massFraction * massFraction
	
	return edge
end
	
function Geometry.blackboxFindClosestMeshEdge(hit: RaycastResult, viewDirection: Vector3): GeometryEdge?
	local part = hit.Instance :: BasePart
	
	-- We have a current plane defined by p,n
	local p = hit.Position
	local n = hit.Normal
	
	-- Basis within which we're about to do stuff
	local mainBasis = CFrame.fromMatrix(p, perpendicularVector(n), n)
	local xBasis = mainBasis.XVector
	local zBasis = mainBasis.ZVector
	
	-- We want to explore outwards over this plane until we find where it ends
	-- (that is, where parallel raycasts diverge from the plane)
	local p2, n2 = findNearestInterestingPoint(mainBasis, part)
	if not p2 or not n2 then
		return nil
	end

	-- Find the axis which goes through both (p, n) and (p2, n2)
	local origin, dir = intersectPlanePlane(p, n, p2, n2)
	
	-- (origin, dir) is now a ray along the edge of interest. From here we have
	-- to figure out how LONG the edge is along that ray. We know that origin is
	-- ONE of the points on the ray, so we can raycast out from there.
	return exploreEdge(part, origin, dir, n, n2)
end

return Geometry