#include "common_ps_fxc.h"

struct PS_INPUT {
	float2 uv            : TEXCOORD0;	
	float3 pos           : TEXCOORD1;
	float3 normal        : TEXCOORD2;
	float4 color         : COLOR0;
	float4 coord         : VPOS;
};

#define AMBIENT_COLOR float3(0.308251, 0.454464, 0.547380)
#define SUN_DIR normalize(float3(-0.061628, -0.061628, 0.996195))

// edited from https://www.shadertoy.com/view/Ns23RV
float bayer(float2 coord)
{
	float2 bayerCoord = floor(coord);
	bayerCoord = bayerCoord % 4.;

	const float4x4 bayerMat = float4x4(
			0,8,2,10,
			12,4,14,6,
			3,11,1,9,
			15,7,13,5) / 15.;
	int bayerIndex = int(bayerCoord.x + bayerCoord.y * 4.);
	if(bayerIndex == 0) return bayerMat[0][0];
	if(bayerIndex == 1) return bayerMat[0][1];
	if(bayerIndex == 2) return bayerMat[0][2];
	if(bayerIndex == 3) return bayerMat[0][3];
	if(bayerIndex == 4) return bayerMat[1][0];
	if(bayerIndex == 5) return bayerMat[1][1];
	if(bayerIndex == 6) return bayerMat[1][2];
	if(bayerIndex == 7) return bayerMat[1][3];
	if(bayerIndex == 8) return bayerMat[2][0];
	if(bayerIndex == 9) return bayerMat[2][1];
	if(bayerIndex == 10) return bayerMat[2][2];
	if(bayerIndex == 11) return bayerMat[2][3];
	if(bayerIndex == 12) return bayerMat[3][0];
	if(bayerIndex == 13) return bayerMat[3][1];
	if(bayerIndex == 14) return bayerMat[3][2];
	return bayerMat[3][3];
}

float4 main(PS_INPUT frag) : COLOR {
	float3 final_color = float3(1.0, 1.0, 1.0);

	final_color *= max(dot(frag.normal, SUN_DIR), 0.0);
	// final_color += AMBIENT_COLOR;
	final_color *= frag.color.xyz;

	if (frag.color.w < bayer(frag.coord) / 1.01) {
		discard;
	}

	return FinalOutput(float4(final_color, 1.0), 0, PIXEL_FOG_TYPE_NONE, TONEMAP_SCALE_LINEAR);
}