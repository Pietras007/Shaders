float4 camPos;
sampler samp;
textureCUBE envMap;
texture3D perlin;
float time;
texture2D screenColor;
texture2D screenDepth;
matrix viewProjMtx;
float2 viewportDim;
float nearZ;
static float maxDistance = 30.0f;
matrix projInvMtx;
float depthThickness;


struct PSInput
{
	float4 pos:SV_POSITION;
	float3 localPos:POSITION0;
	float3 worldPos:POSITION1;
};


float3 intersectRay(float3 p, float3 d)
{
	float tx = max((1 - p.x) / d.x, (-1 - p.x) / d.x);
	float ty = max((1 - p.y) / d.y, (-1 - p.y) / d.y);
	float tz = max((1 - p.z) / d.z, (-1 - p.z) / d.z);

	float t = min(tx, min(ty, tz));
	return p + d * t;
}

float fresnel(float n1, float n2, float3 N, float3 V)
{
	float F0 = pow((n2 - n1) / (n2 + n1), 2);
	if (dot(N, V) < 0)
	{
		N = -N;
	}

	float cos = max(dot(N, V), 0);
	return F0 + (1.0f - F0) * pow((1.0f - cos), 5);
}

float linearizeDepth(float depth)
{
	float4 p = float4(0.0f, 0.0f, depth, 1.0f);
	p = mul(projInvMtx, p);
	return p.z / p.w;
}

float4 screenSpaceRayCast(float3 wOrg, float3 wDir)
{
	float3 wEnd = wOrg + wDir * maxDistance;
	//NDC ray endpoints
	float4 ssOrg = mul(viewProjMtx, float4(wOrg, 1.0f));
	float4 ssEnd = mul(viewProjMtx, float4(wEnd, 1.0f));

	if (ssEnd.w < nearZ) {
		float toNearZ = maxDistance * (nearZ - ssOrg.w) / (ssEnd.w - ssOrg.w);
		wEnd = wOrg + wDir * toNearZ;
		ssEnd = mul(viewProjMtx, float4(wEnd, 1.0f));
	}

	ssOrg = float4(ssOrg.xyz, 1.0f) / ssOrg.w;
	ssEnd = float4(ssEnd.xyz, 1.0f) / ssEnd.w;

	ssOrg.xy = (float2(ssOrg.x, -ssOrg.y) + 1.0f) *
		viewportDim / 2.0f;
	ssEnd.xy = (float2(ssEnd.x, -ssEnd.y) + 1.0f) *
		viewportDim / 2.0f;

	float2 delta = (ssEnd.xy - ssOrg.xy);
	bool coordSwap = false;
	if (abs(delta.x) < abs(delta.y))
	{
		//DDA will iterate vertically, swap coordinates
		delta = delta.yx;
		ssOrg.xy = ssOrg.yx;
		ssEnd.xy = ssEnd.yx;
		coordSwap = true;
	}

	float stepDir = sign(delta.x);
	float4 dP = stepDir * (ssEnd - ssOrg) / delta.x;
	float4 P = ssOrg;
	float endX = stepDir * ssEnd.x;
	float prevZ = 1 / P.w;

	for (; (P.x * stepDir) < endX; P += dP)
	{
		int3 pxCoord = int3(coordSwap ? P.yx : P.xy, 0);
		//float screenZ = screenDepth.Load(pxCoord).r;
		float screenZ = linearizeDepth(screenDepth.Load(pxCoord).r);
		float rayZ = 1.0f / (P.w + 0.5f * dP.w);
		/*if (screenZ < rayZ)
			return screenColor.Load(pxCoord);*/

		float maxZ = max(rayZ, prevZ);
		float minZ = min(rayZ, prevZ);
		prevZ = rayZ;
		if (screenZ - depthThickness < maxZ)
		{
			if (screenZ > minZ)
				return screenColor.Load(pxCoord);
			else break;
		}
	}
	return float4(0.0f, 0.0f, 0.0f, 0.0f);


}


float4 main(PSInput i) :SV_TARGET
{
	float3 viewVec = normalize(camPos.xyz - i.worldPos);
	//float3 norm = float3(0.0f, 1.0f, 0.0f);

	float3 tex = float3(i.localPos.xz * 10.0f, time);
	float ex = perlin.Sample(samp, tex);
	tex.x += float3(0.5f, 0.5f, 0.5f);

	float ez = perlin.Sample(samp, tex);
	float3 N = normalize(float3(ex, 20.0f, ez));

	float3 reflection = reflect(-viewVec, N);
	float n1 = 1.0f;
	float n2 = 4.0f / 3.0f;
	float x = n1 / n2;
	if (dot(N, viewVec) < 0) x = n2 / n1;
	float3 refraction = refract(-viewVec, N, x);
	float fres = fresnel(n1, n2, N, viewVec);

	float3 reflect = intersectRay(i.localPos, reflection);
	float3 colorReflect = envMap.Sample(samp, reflect).rgb;

	float4 ssReflColor = screenSpaceRayCast(i.worldPos, reflect);
	ssReflColor = pow(ssReflColor, 1.0f / 0.4545f);
	colorReflect = lerp(colorReflect, ssReflColor.rgb, ssReflColor.a);


	float3 refract = intersectRay(i.localPos, refraction);
	float3 colorRefract = envMap.Sample(samp, refract).rgb;

	float4 ssRefrColor = screenSpaceRayCast(i.worldPos, refract);
	ssRefrColor = pow(ssRefrColor, 1.0f / 0.4545f);
	colorRefract = lerp(colorRefract, ssRefrColor.rgb, ssRefrColor.a);


	float3 color = fres* colorReflect + (1.0f - fres) * colorRefract;

	//float3 color = colorReflect;
	//if (any(refraction))
	//{
	//	color = lerp(colorRefract, colorReflect, float3(fres, fres, fres));
	//}

	if (dot(N, viewVec) < 0)
	{
		refract.y = -refract.y;
		color = envMap.Sample(samp, refract).rgb;
		if (!any(refraction))
		{
			color = colorReflect;
		}
	}

	color = pow(color, 0.4545f);
	return float4(color, 1.0f);
}