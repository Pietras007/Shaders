#include "shaderDemo.h"

using namespace mini;
using namespace gk2;
using namespace DirectX;
using namespace std;
using namespace utils;

ShaderDemo::ShaderDemo(HINSTANCE hInst): GK2ShaderDemoBase(hInst)
{
	//Shader Variables
	m_variables.AddSemanticVariable("modelMtx", VariableSemantic::MatM);
	m_variables.AddSemanticVariable("modelInvTMtx", VariableSemantic::MatMInvT);
	m_variables.AddSemanticVariable("viewProjMtx", VariableSemantic::MatVP);
	m_variables.AddSemanticVariable("camPos", VariableSemantic::Vec4CamPos);

	//XMFLOAT4 lightPos[2] = { { -1,0,-1.7f,1 },{ 0,1.7f,0,1 } };
	//XMFLOAT3 lightColor[2] = { { 1, 0.8f, 0.9f },{ 0.1f, 0, 1 } };
	//m_variables.AddGuiVariable("lightPos", lightPos, -10, 10);
	//m_variables.AddGuiColorsVariable("lightColor", lightColor);
	/*m_variables.AddGuiColorVariable("surfaceColor", XMFLOAT3{ 0.5f, 1.0f, 0.8f });
	m_variables.AddGuiVariable("ks", 0.8f);
	m_variables.AddGuiVariable("kd", 0.5f);
	m_variables.AddGuiVariable("ka", 0.2f);*/
	m_variables.AddGuiVariable("m", 50.f, 10.f, 200.f);
	m_variables.AddSampler(m_device, "samp");
	m_variables.AddTexture(m_device, "normTex", L"textures/normal.jpg");

	auto h0 = 1.5f;
	m_variables.AddGuiVariable("h0", h0, 0, 3);
	m_variables.AddGuiVariable("l", 15.f, 5, 25);
	m_variables.AddGuiVariable("r", 0.5f, 0.01f, 1);
	m_variables.AddGuiVariable("rsmall", 0.1f, 0.01f, 0.5f);

	m_variables.AddGuiVariable("thalf", 3.f, 1.f, 5.f);
	m_variables.AddGuiVariable("xmax", .5f, .1f, 1.f);
	m_variables.AddGuiVariable("vmax", 4.f, .5f, 10.f);
	m_variables.AddSemanticVariable("time", VariableSemantic::FloatT);

	m_variables.AddTexture(m_device, "envMap", L"textures/cubeMap.dds");
	m_variables.AddTexture(m_device, "perlin", L"textures/NoiseVolume.dds");
	m_variables.AddSemanticVariable("mvpMtx", VariableSemantic::MatMVP);
	m_variables.AddGuiVariable("waterLevel", -0.05f, -1, 1, 0.001f);


	m_variables.AddTexture(m_device, "albedoTex", L"textures/rustediron2/albedo.png");
	m_variables.AddTexture(m_device, "roughnessTex", L"textures/rustediron2/roughness.png");
	m_variables.AddTexture(m_device, "metallicTex", L"textures/rustediron2/metallic.png");


	m_variables.AddTexture(m_device, "irMap",
		L"textures/cubeMapIrradiance.dds");
	m_variables.AddTexture(m_device, "pfEnvMap",
		L"textures/cubeMapRadiance.dds");
	m_variables.AddTexture(m_device, "brdfTex",
		L"textures/brdf_lut.png");


	XMFLOAT4 lightPos[2] = { { -1.f, 0.0f, -3.5f, 1.f },{  0.f, 3.5f,  0.0f, 1.f } };
	XMFLOAT3 lightColor[2] = { { 12.f, 9.f, 10.f },{  1.f, 0.f, 30.f } };
	m_variables.AddGuiVariable("lightPos", lightPos, -10, 10);
	m_variables.AddGuiVariable("lightColor", lightColor, 0, 100, 1);
	m_variables.AddGuiColorVariable("albedo", XMFLOAT3{ 1.f, 1.f, 1.f });
	m_variables.AddGuiVariable("metallness", 1.0f);
	m_variables.AddGuiVariable("roughness", .3f, .1f);



	//Models
	//const auto sphere = addModelFromString("s 0 0 0 0.5");
	auto teapot = addModelFromFile("models/Teapot.3ds");
	auto plane = addModelFromFile("models/Plane.obj");
	auto quad = addModelFromString("pp 4\n1 0 1 0 1 0\n1 0 -1 0 1 0\n"
									"-1 0 -1 0 1 0\n-1 0 1 0 1 0\n");
	auto envModel = addModelFromString("hex 0 0 0 1.73205");


	auto screenSize = m_window.getClientSize();
	m_variables.AddRenderableTexture(m_device, "screen", screenSize);
	m_variables.AddRenderableTexture(m_device, "halfscreen1", SIZE{ screenSize.cx / 2,screenSize.cy / 2 });
	m_variables.AddRenderableTexture(m_device, "halfscreen2", SIZE{ screenSize.cx / 2,screenSize.cy / 2 });

	m_variables.AddSemanticVariable("viewportDim", VariableSemantic::Vec2ViewportDims);
	m_variables.AddGuiVariable("blurScale", 1.0f, 0.1f, 2.0f);

	m_variables.AddGuiVariable("cutoff", 0.72f, 0.1f, 1.0f);


	SamplerDescription sDesc;
	sDesc.Filter = D3D11_FILTER_MIN_MAG_MIP_LINEAR;
	sDesc.AddressU = D3D11_TEXTURE_ADDRESS_CLAMP;
	sDesc.AddressV = D3D11_TEXTURE_ADDRESS_CLAMP;
	sDesc.AddressW = D3D11_TEXTURE_ADDRESS_CLAMP;

	m_variables.AddSampler(m_device, "blurSampler", sDesc);


	//Transform teapot
	XMFLOAT4X4 modelMtx;
	float scale = 1 / 60.0f;
	float rotation = -AI_MATH_HALF_PI;
	XMMATRIX modelMatrix = XMMatrixScaling(scale, scale, scale) * XMMatrixRotationX(rotation) * XMMatrixTranslation(0.0f, 0.5f - h0, 0.0f);
	XMStoreFloat4x4(&modelMtx, modelMatrix);
	model(teapot).applyTransform(modelMtx);

	XMStoreFloat4x4(&modelMtx, XMMatrixTranslation(0, -h0, 0));
	model(plane).applyTransform(modelMtx);


	XMStoreFloat4x4(&modelMtx, XMMatrixScaling(20, 20, 20));
	model(quad).applyTransform(modelMtx);
	model(envModel).applyTransform(modelMtx);

	//Render Passes
	//const auto passSphere = addPass(L"sphereVS.cso", L"spherePS.cso");
	//const auto passTeapot = addPass(L"teapotVS.cso", L"teapotPS.cso");
	auto passTeapot = addPass(L"teapotVS.cso", L"teapotPS.cso", "screen");

	auto passSpring = addPass(L"springVS.cso", L"springPS.cso");
	auto passEnv = addPass(L"envVS.cso", L"envPS.cso");
	auto passWater = addPass(L"waterVS.cso", L"waterPS.cso");
	
	
	addModelToPass(passWater, quad);
	RasterizerDescription rs;
	rs.CullMode = D3D11_CULL_NONE; 
	addRasterizerState(passWater, rs);

	addModelToPass(passEnv, envModel);
	addRasterizerState(passEnv, RasterizerDescription(true));
	
	addModelToPass(passSpring, plane);
	//addModelToPass(passSphere, sphere);
	addModelToPass(passTeapot, teapot);

	auto passDownsample = addPass(L"fullScreenQuadVS.cso", L"downsamplePS.cso",	"halfscreen1");
	addModelToPass(passDownsample, quad);

	auto passHBlur = addPass(L"fullScreenQuadVS.cso", L"hblurPS.cso", "halfscreen2");
	addModelToPass(passHBlur, quad);

	auto passVBlur = addPass(L"fullScreenQuadVS.cso", L"vblurPS.cso", "halfscreen1", true);
	addModelToPass(passVBlur, quad);

	auto passComposite = addPass(L"fullScreenQuadVS.cso", L"compositePS.cso", getDefaultRenderTarget());
	addModelToPass(passComposite, quad);
}


