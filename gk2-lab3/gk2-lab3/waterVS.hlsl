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
	float4 _pos = mul(modelMtx, float4(pos.x, waterLevel, pos.z, 1.0f));
	o.worldPos = _pos;
	o.localPos = float3(pos.x, waterLevel, pos.z);
	o.pos = mul(viewProjMtx, _pos);
	return o;
}