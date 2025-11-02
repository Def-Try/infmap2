#include "common_vs_fxc.h"
#include "simplex.h"

sampler3D BASETEXTURE : register(s0);
// TODO: USE VOLUME TEXTURE LOOKUP INSTEAD OF SIMPLEX AND CONVERT US BACK TO "sm2" SO LINUX WORKS!!!!!
// TODO: OPTIMISE SHADER IN GENERAL!!!!!

struct VS_INPUT {
	float4 vPos      : POSITION;
	float4 vTexCoord : TEXCOORD0;
	float3 vNormal   : NORMAL0;
	float4 vColor    : COLOR0;
	float4 vTangent0 : TANGENT0;
};

struct VS_OUTPUT {
	float4 proj_pos : POSITION;
	float2 uv       : TEXCOORD0;
	float3 pos      : TEXCOORD1;
	float3 normal   : TEXCOORD2;
	float4 color    : COLOR0;
};

float random(float2 p){return cos(dot(p,float2(23.14069263277926,2.665144142690225)))*12345.6789 % 1;}

VS_OUTPUT main(VS_INPUT vert) {
	float3 world_pos;
	float3 world_normal;
	SkinPositionAndNormal(0, vert.vPos, vert.vNormal, 0, 0, world_pos, world_normal);

	// first we get dynamic info that we got passed from lua
	float offx = cAmbientCubeX[0].x;    // offset x. for fadeout and wind
	float offy = cAmbientCubeX[0].y;    // offset y. for fadeout and wind
	float curtime = cAmbientCubeX[0].z; // curtime.  for wind
	float plyx = cAmbientCubeX[1].x;    // player x. for fadeout
	float plyy = cAmbientCubeX[1].y;    // player y. for fadeout

	// terrain heights.
	float v00 = cAmbientCubeX[1].z;
	float v10 = cAmbientCubeY[0].x;
	float v01 = cAmbientCubeY[0].y;
	float v11 = cAmbientCubeY[0].z;

	// triangle x/y on grid. for wind
	float truex = vert.vTangent0[1];
	float truey = vert.vTangent0[2];
	// triangles per grid side. for wind
	float blades_sqrt = vert.vTangent0[3];
	// actual blade x/y fon infinite grid (accounting for mesh offset). for wind
	float bladex = truex + offx;
	float bladey = truey + offy;
	// vert multiplier. 1 for vertex that moves, 0 for one that doesnt
	float vertmul = vert.vTangent0[0];
	// truex/y no longer used for their original values, make then fractions instead of positions on grid
	truex = truex / blades_sqrt;
	truey = truey / blades_sqrt;

	// calculate triangle heights for terrain now
	// code adapted from infmap2/ish/world.sh :: InfMap2.GetTerrainHeightAt
	float tri0 = ((truex + truey) > 1) ? 1 : 0;
	float height = 0;
	height += tri0 * ((1 - truey) * v01 + (1 - truex) * v10 + (truex + truey - 1) * v11);
	height += (1 - tri0) * ((1 - truex - truey) * v00 + truex * v01 + truey * v10);
	
	// random offset for *variation*
	// TODO: move to meshgen?
	world_pos.x += random(float2(bladex, bladey+1000)) * 10;
	world_pos.y += random(float2(bladex+1000, bladey)) * 10;

	// calculate wind
	// TODO: use (volume?) texture lookup instead of simplex noise -- it's too expensive instruction-wise
	// TODO: compile back to sm2 (..._vs20.hlsl) to support linux
	
	// shear 1: base move - minor winds
	float base_move_y = snoise(float2(curtime + bladey * 0.02, 1000));
	// shear 2: burst move - bursts of wind that are more noticable, faster, and affect more ground
	float burst_move_y = max(0.0, snoise(float2((curtime * 10 + bladey * 0.1) * 0.1, 6000)) * 25 + 25 - 40) / 10;

	// apply wind
	// multiply by negative so it looks correct (otherwise blades bend in the direction that "wind" "comes from", instead of away)
	float total_move_y = base_move_y * -5 + burst_move_y * -16;
	float3 worldpos_deviation = normalize(float3(0, total_move_y, 25.0)) * 25.0;
	world_pos += vertmul * worldpos_deviation;
	// ^^^ might seem dumb to calculate all that and then multiply by zero, but we're on gpu so we should minimise branching to maximise performance

	// calculate transparency
	float deviationx = plyx - world_pos.x;
	float deviationy = plyy - world_pos.y;
	// don't sqrt and instead divide by squared value, don't lose performance on that
	float dist = (deviationx * deviationx + deviationy * deviationy) / 1250000;
	dist = 1 - dist;
	dist = dist * dist * dist;

	// finally apply terrain height to every vertex
	world_pos.z += height;

	// project vertex onto screen
	float4 proj_pos = mul(float4(world_pos, 1), cViewProj);

	// pass data to The Pixel Shader
	VS_OUTPUT output = (VS_OUTPUT)0;
	output.proj_pos = proj_pos;
	output.uv = vert.vTexCoord.xy;
	output.pos = world_pos;
	output.normal = world_normal;
	output.color = vert.vColor;
	output.color.w *= min(dist * 4.0, 1.0);

	return output;
};