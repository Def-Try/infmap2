#include "common_vs_fxc.h"
#include "simplex.h"

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

VS_OUTPUT main(VS_INPUT vert) {
	float3 world_pos;
	float3 world_normal;
	SkinPositionAndNormal(0, vert.vPos, vert.vNormal, 0, 0, world_pos, world_normal);

	float offx = cAmbientCubeX[0].x;
	float offy = cAmbientCubeX[0].y;
	float curtime = cAmbientCubeX[0].z;
	float plyx = cAmbientCubeX[1].x;
	float plyy = cAmbientCubeX[1].y;

	float bladex = vert.vTangent0[1] + offx;
	float bladey = vert.vTangent0[2] + offy;
	float vertmul = vert.vTangent0[0];

	float base_move_x = snoise(float2(curtime + bladex, 0));
	float base_move_y = snoise(float2(curtime + bladey, 1000));
	float burst_move_x = max(0.0, snoise(float2((curtime * 10 + bladex) * 0.1, 5000)) * 25 + 25 - 40) / 10;
	float burst_move_y = max(0.0, snoise(float2((curtime * 10 + bladey) * 0.1, 6000)) * 25 + 25 - 40) / 10;

	float total_move_x = base_move_x * 3 + burst_move_x * 16;
	float total_move_y = base_move_y * 3 + burst_move_y * 16;

	world_pos.z += vertmul * (25.0 - total_move_x - total_move_y);
	world_pos.x += total_move_x * vertmul;
	world_pos.y += total_move_y * vertmul;

	float deviationx = plyx - world_pos.x;
	float deviationy = plyy - world_pos.y;
	float dist = (deviationx * deviationx + deviationy * deviationy) / 1250000;
	// 1.0 - min(1.0, max((dist, 0.0));
	dist = 1 - dist;
	dist = dist * dist * dist;

	// Takes our world space coordinate and projects it onto the screen
	float4 proj_pos = mul(float4(world_pos, 1), cViewProj);

	// Define our output structure (initializes everything to 0)
	VS_OUTPUT output = (VS_OUTPUT)0;
	output.proj_pos = proj_pos;
	output.uv = vert.vTexCoord.xy;
	output.pos = world_pos;
	output.normal = world_normal;
	output.color = vert.vColor;
	output.color.w *= dist;

	return output;
};