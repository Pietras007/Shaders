struct VSOutput
{
	float4 pos:SV_POSITION;
	float2 tex : TEXCOORD0;
};


VSOutput main(float3 pos:POSITION0)
{
	VSOutput o;
	o.pos = float4(pos.x, pos.z, 0.0f, 1.0f);
	o.tex = float2((pos.x + 1.0f) / 2, (-pos.z + 1.0f) / 2);
	return o;
}