# Roblox Geometry Module
This is a module which contains two important geometry functions for Roblox tooling.

## getGeometry

This is a function which returns a detailed mesh representation of the geometry of a Roblox primitive. That is, one of the five primitive types between a Box, WedgePart, CornerWedgePart, Sphere, or Cylinder. It contains all the logic to decide which of those geometries is appropriate for a given BasePart.

You can optionally pass a CFrame as the second argument to get the geometry assuming that the part were at that CFrame rather than where it currently is. Note: Passing `CFrame.identity` here will effectively give you the geometry in the local space of the object rather than in world space like it is normally given.

The id on each element is a stable id from invocation to invocation allowing you to track the same element across multiple invocations.

The vertexMargin / edgeMargin are the minimum amount of "safe" space perpendicular to the feature, and can be used to determine a reasonable sizing of visualizations around the feature.

The data is returned in the following format:
```luau
export type SurfaceType =
	| "BottomSurface"
	| "RightSurface"
	| "FrontSurface"
	| "LeftSurface"
	| "BackSurface"
	| "TopSurface"

export type Shape =
	| "Cylinder"
	| "Sphere"
	| "Mesh"

type Identifier<T> = {
	type: T,
	__index: Identifier<T>,
}

type BaseGeometryInfo<T, I, ID = number?> = typeof(setmetatable(
	{} :: I & {
		id: ID,
	},
	{} :: Identifier<T>
))

export type UnitVector = Vector3

export type Vertex<ID = nil> = BaseGeometryInfo<"Vertex", {
	position: Vector3,
}, ID>

export type Edge<ID = nil> = BaseGeometryInfo<"Edge", {
	direction: UnitVector,
	vertexMargin: number,
	edgeMargin: number,
	inferred: true?,
	length: number,
	part: BasePart,
	a: Vector3,
	b: Vector3,
}, ID>

export type Face<ID = nil> = BaseGeometryInfo<"Face", {
	direction: UnitVector,
	vertices: { Vector3 },
	surface: SurfaceType,
	normal: UnitVector,
	point: Vector3,
	part: BasePart,
}, ID>

export type GeometryResult = {
	vertices: { Vertex<number> },
	edges: { Edge<number> },
	faces: { Face<number> },
	vertexMargin: number,
	part: BasePart,
	shape: Shape,
}
```

## blackboxFindClosestMeshEdge

For mouse hit in the form of a RaycastResult, find the edge closest to that hit. The edge is returned in the same `GeometryEdge` format as edges in the table returned by getGeometry. The function may be used for hits against primitive parts, but keep in mind that it will never return a result for Spheres / Cylinders since there aren't any straight edges to find.

The function operates by using up to 50 raycasts to inspect the geometry around the hit and then working out exactly where the edge must be analytically from that information. This means it comes at a significant perforance cost, and will run fine for tooling purposes, but should not be used in live experiences for gameplay purposes.
