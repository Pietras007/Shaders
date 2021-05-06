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

	XMFLOAT4 lightPos[2] = { { -1,0,-1.7f,1 },{ 0,1.7f,0,1 } };
	XMFLOAT3 lightColor[2] = { { 1, 0.8f, 0.9f },{ 0.1f, 0, 1 } };
	m_variables.AddGuiVariable("lightPos", lightPos, -10, 10);
	m_variables.AddGuiColorsVariable("lightColor", lightColor);
	m_variables.AddGuiColorVariable("surfaceColor", XMFLOAT3{ 0.5f, 1.0f, 0.8f });
	m_variables.AddGuiVariable("ks", 0.8f);
	m_variables.AddGuiVariable("kd", 0.5f);
	m_variables.AddGuiVariable("ka", 0.2f);
	m_variables.AddGuiVariable("m", 50.f, 10.f, 200.f);
	m_variables.AddSampler(m_device, "samp");
	m_variables.AddTexture(m_device, "normTex", L"textures/normal.jpg");

	//Models
	//const auto sphere = addModelFromString("s 0 0 0 0.5");
	auto teapot = addModelFromFile("models/Teapot.3ds");

	//Transform teapot
	XMFLOAT4X4 modelMtx;
	float scale = 1 / 60.0f;
	float rotation = -AI_MATH_HALF_PI;
	XMMATRIX modelMatrix = XMMatrixScaling(scale, scale, scale) * XMMatrixRotationX(rotation) * XMMatrixTranslation(0.0f, 0.5f, 0.0f);
	XMStoreFloat4x4(&modelMtx, modelMatrix);
	model(teapot).applyTransform(modelMtx);

	//Render Passes
	//const auto passSphere = addPass(L"sphereVS.cso", L"spherePS.cso");
	const auto passTeapot = addPass(L"teapotVS.cso", L"teapotPS.cso");

	//addModelToPass(passSphere, sphere);
	addModelToPass(passTeapot, teapot);
}
