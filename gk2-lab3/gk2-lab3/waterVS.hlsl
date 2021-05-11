matrix modelMtx, viewProjMtx;
float waterLevel;
struct VSOutput
{
	float4 pos:SV_POSITION;
	float3 localPos:POSITION0;
	float3 worldPos:POSITION1;
};


VSOutput main(float3 pos:POSITION0)
{
	VSOutput o;
	o.worldPos = mul(modelMtx, float4(pos.x, waterLevel, pos.z, 1.0f));
	o.localPos = float3(pos.x, waterLevel, pos.z);
	o.pos = mul(viewProjMtx, o.worldPos);
	return o;
}