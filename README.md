# Roblox Geometry Module
This is a module which contains two important geometry functions for Roblox tooling.

## getGeometry

This is a function which returns a detailed mesh representation of the geometry of a Roblox primitive. That is, one of the five primitive types between a Box, WedgePart, CornerWedgePart, Sphere, or Cylinder. It contains all the logic to decide which of those geometries is appropriate for a given BasePart.

You can optionally pass a CFrame as the third argument to get the geometry assuming that the part were at that CFrame rather than where it currently is. Note: Passing `CFrame.identity` here will effectively give you the geometry in the local space of the object rather than in world space like it is normally given.

The id on each element is a stable id from invocation to invocation allowing you to track the same element across multiple invocations.

The vertexMargin / edgeMargin are the minimum amount of "safe" space perpendicular to the feature, and can be used to determine a reasonable sizing of visualizations around the feature.

The data is returned in the following format:
```luau
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
```

## blackboxFindClosestMeshEdge

For mouse hit in the form of a RaycastResult, find the edge closest to that hit. The edge is returned in the same `GeometryEdge` format as edges in the table returned by getGeometry. The function may be used for hits against primitive parts, but keep in mind that it will never return a result for Spheres / Cylinders since there aren't any straight edges to find.

The function operates by using up to 50 raycasts to inspect the geometry around the hit and then working out exactly where the edge must be analytically from that information. This means it comes at a significant perforance cost, and will run fine for tooling purposes, but should not be used in live experiences for gameplay purposes.
