#include "common_ps_fxc.h"

struct PS_INPUT {
	float2 uv            : TEXCOORD0;	
	float3 pos           : TEXCOORD1;
	float3 normal        : TEXCOORD2;
	float4 color         : COLOR0;
};

#define AMBIENT_COLOR float3(0.308251, 0.454464, 0.547380)
#define SUN_DIR normalize(float3(-0.061628, -0.061628, 0.996195))

float4 main(PS_INPUT frag) : COLOR {
	float3 final_color = float3(1.0, 1.0, 1.0);

	final_color *= max(dot(frag.normal, SUN_DIR), 0.0);
	// final_color += AMBIENT_COLOR;
	final_color *= frag.color.xyz;

	return FinalOutput(float4(final_color, frag.color.w), 0, PIXEL_FOG_TYPE_NONE, TONEMAP_SCALE_LINEAR);
}