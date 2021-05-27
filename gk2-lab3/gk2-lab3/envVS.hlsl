matrix mvpMtx;
struct VSOutput
{ 
	float4 pos:SV_POSITION;
	float3 tex:TEXCOORD0; 
};

VSOutput main(float3 pos:POSITION0)
{ 
	VSOutput o; 
	o.tex = normalize(pos); 
	o.pos = mul(mvpMtx, float4(pos, 1.0f));
	return o; 
}