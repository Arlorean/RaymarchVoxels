// A Fast Voxel Traversal Algorithm for Ray Tracing
//    John Amanatides, Andrew Woo - August 1987
// http://www.cse.yorku.ca/~amana/research/grid.pdf


// Ray intersection with axis aligned box centered at the origin, with unit size
// https://gist.github.com/DomNomNom/46bb1ce47f68d255fd5d
float2 intersectAABB(float3 rayOrigin, float3 rayDir) {
    float3 tMin = (-0.5 - rayOrigin) / rayDir;
    float3 tMax = (0.5 - rayOrigin) / rayDir;
    float3 t1 = min(tMin, tMax);
    float3 t2 = max(tMin, tMax);
    float tNear = max(max(t1.x, t1.y), t1.z);
    float tFar = min(min(t2.x, t2.y), t2.z);
	// Clamp the tNear to the camera origin
	if (tNear < 0) {
		tNear = 0;
	}
    return float2(tNear, tFar);
};

static float staticRawDepth;

// Raymarch a 3D voxels texture in an AABB unit cube at the origin
// from a camera origin and direction, both also in object space
// return the color of the pixel on the front face of the cube and the face normal (in object space).
void RaymarchVoxels_float(
	float3 origin, float3 direction, UnityTexture3D voxels,  
    out float4 color, out float3 normal, out float rawDepth)
{
	// https://docs.unity3d.com/Packages/com.unity.shadergraph@16.0/manual/Custom-Function-Node.html#:~:text=10.3%20or%20later.-,How%20to%20upgrade,-Change%20all%20of
	int3 dimensions;
	voxels.tex.GetDimensions(dimensions.x,dimensions.y,dimensions.z);

	float3 voxelSize = 1.0/dimensions;

	// Get just in front of the front face intersection (back faces should be being rendered)
	float2 rayDistances = intersectAABB(origin, direction);
	origin += direction*rayDistances.x*0.9999;

	// Ray origin and direction in voxel space (assumes object origin at 0,0,0 and voxels are 1x1x1 in size in object space)
	float3 p = (origin+0.5) / voxelSize;
	float3 d = normalize(direction / voxelSize); // Convert to voxel space

	// The amount to step in whole voxels based on direction
	int3 step = sign(direction);

	// The first voxel where the ray enters - tracks voxels passed through in loop below
	int3 v = floor(p);

	// TDelta indicates how far along the ray we must move (in units of t) for the component of such a movement to equal the width of a voxel
	float3 tDelta = abs(1.0 / d);

	// Initialize tMax - The value of t at which the ray crosses the first voxel boundary for that component
	// https://github.com/DJayalath/RayTracingEngine/blob/master/shader.frag
	float3 tMax = 0;
	if (d.x < 0) {
		tMax.x = (p.x - v.x) * tDelta.x;
	}
	else if (d.x > 0) {
		tMax.x = (v.x + 1.0 - p.x) * tDelta.x;
	}
	if (d.y < 0) {
		tMax.y = (p.y - v.y) * tDelta.y;
	}
	else if (d.y > 0) {
		tMax.y = (v.y + 1.0 - p.y) * tDelta.y;
	}
	if (d.z < 0) {
		tMax.z = (p.z - v.z) * tDelta.z;
	}
	else if (d.z > 0) {
		tMax.z = (v.z + 1.0 - p.z) * tDelta.z;
	}

	float t = 0;

	UNITY_LOOP
	int maxIterations = dimensions.x+dimensions.y+dimensions.z; // Shouldn't be needed but just in case
	for (int i=0; i < maxIterations; i++) {
		// Look up the exact voxel color in the 3D texture (don't sample)
		color = voxels.Load(int4(v,0));
		if (color.a) {
			float3 objectPosition = (p + d*t)*voxelSize - 0.5;
			float4 clipPosition = mul(UNITY_MATRIX_MVP, float4(objectPosition, 1.0));
			rawDepth = staticRawDepth = clipPosition.z / clipPosition.w;
			return;
		}

		if (tMax.x < tMax.y) {
			if(tMax.x < tMax.z) {
				v.x = v.x + step.x;
				if (v.x < 0 || v.x >= dimensions.x) { break; }
				t = tMax.x;
				tMax.x += tDelta.x;
				normal = float3(-step.x,0,0);
			} else {
				v.z = v.z + step.z;
				if (v.z < 0 || v.z >= dimensions.z) { break; }
				t = tMax.z;
				tMax.z += tDelta.z;
				normal = float3(0,0,-step.z);
			}
		} else {
			if (tMax.y < tMax.z) {
				v.y = v.y + step.y;
				if (v.y < 0 || v.y >= dimensions.y) { break; }
				t = tMax.y;
				tMax.y += tDelta.y;
				normal = float3(0,-step.y,0);
			} else {
				v.z = v.z + step.z;
				if (v.z < 0 || v.z >= dimensions.z) { break; }
				t = tMax.z;
				tMax.z += tDelta.z;
				normal = float3(0,0,-step.z);
			}
		}
	}

	discard;
}

