﻿// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Noise/OBNI" {
	Properties{
		_Tess("Tessellation", Range(1,32)) = 4

		_MainTex("Texture", 2D) = "white" {}
		_Color1("Color1", color) = (1,1,1,0)
		_ColorTexRepetition("ColorRepetition", Range(-10,100)) = 1
		_ColorReadingSpeed("ColorReadingSpeed", Range(-100,100)) = 0
		_ColorOffset("Color Offset", Float)= 0

		[Toggle] _UseTwoTextures("Use2Textures", Range(0,1)) = 0
		_MainTex2("Base (RGB)", 2D) = "white" {}
		_Color2("Color2", color) = (0.5,0.5,0.5,0.5)

		_DispTex("Disp Texture", 2D) = "gray" {}
		_Displacement1Intensity("Displacement1 intensity", Range(0, 1.0)) = 0.3
		_Tiling("Tiling", Range(1,10)) = 1

		[Toggle] _SubstractNoises("SubstractNoises", Range(0,1)) = 0
		[Toggle] _AddNoises("AddNoises", Range(0,1)) = 0
		[Toggle] _MultiplyNoises("MultiplyNoises", Range(0,1)) = 0
		[Toggle] _DivideNoises("DivideNoises", Range(0,1)) = 0
		[Toggle] _LimitByNoises("LimitByNoises", Range(0,1)) = 0
		_Seuil("Seuil", Range(-0.5,0.5)) = 0

		_DispTex2("Disp Texture2", 2D) = "gray" {}
		_Displacement2Intensity("Displacement2 intensity", Range(0, 1.0)) = 0.3
		_Tiling2("Tiling2", Range(1,10)) = 1

		_NormalMap("Normalmap", 2D) = "bump" {}
		_NormalCoeff("Normal coeff", Range(-0.1,0.1)) = 0.001
		
		_Glossiness("Smoothness", Range(0,1)) = 0.5
		_Metallic("Metallic", Range(0,1)) = 0.0
	}
	SubShader{
		Tags{ "RenderType" = "Transparent" }
		Cull Off

		CGPROGRAM
		#pragma surface surf Standard addshadow fullforwardshadows vertex:disp tessellate:tessFixed nolightmap
		#pragma target 5.0

		struct appdata {
			float4 vertex : POSITION;
			float4 tangent : TANGENT;
			float3 normal : NORMAL;
			float2 texcoord : TEXCOORD0;
		};

		float _Tess;

		float4 tessFixed()
		{
			return _Tess;
		}

		sampler2D _DispTex;
		sampler2D _DispTex2;
		float _Displacement1Intensity;
		float _Displacement2Intensity;

		float _NormalCoeff;
		float _Tiling;
		float _Tiling2;

		float _SubstractNoises;
		float _AddNoises;
		float _MultiplyNoises;
		float _DivideNoises;
		float _LimitByNoises;
		float _Seuil;


		void disp(inout appdata_full v)
		{
			float disp = 0;
			float d = tex2Dlod(_DispTex, float4(v.texcoord.xy*_Tiling,0,0)).r * _Displacement1Intensity;
			disp = d;
			float d2 = tex2Dlod(_DispTex2, float4((v.texcoord.xy)*_Tiling2, 0, 0)).r * _Displacement2Intensity;
			
			if (_SubstractNoises) {
				disp = d - d2;
			}
			if (_AddNoises) {
				disp = d + d2;
			}	
			if (_MultiplyNoises) {
				disp = d * d2;
			}
			if (_DivideNoises) {
				disp = d / d2;
			}
			if (_LimitByNoises) {
				if (disp > _Seuil) {
				//	if (disp > d2)
						disp = d2;

				}
			}

			float3 bitangent = cross(v.normal, v.tangent);
			float3 position = v.vertex + disp;

			float3 positionAndTangent = v.vertex + v.tangent * _NormalCoeff + disp;
			float3 positionAndBitangent = v.vertex + bitangent * _NormalCoeff + disp;

			float3 newTangent = (positionAndTangent - position); // leaves just 'tangent'
			float3 newBitangent = (positionAndBitangent - position); // leaves just 'bitangent'

			float3 newNormal = normalize(cross(newTangent, newBitangent));

			v.vertex.xyz += (newNormal*disp);
			v.normal = newNormal;
		}


		struct Input {
			float2 uv_MainTex;
		};

		sampler2D _MainTex;
		sampler2D _MainTex2;
		float _UseTwoTextures;

		sampler2D _NormalMap;
		fixed4 _Color1;
		fixed4 _Color2;
		float _ColorTexRepetition, _ColorReadingSpeed, _ColorOffset;
		half _Glossiness;
		half _Metallic;

		// Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
		// See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
		// #pragma instancing_options assumeuniformscaling
		UNITY_INSTANCING_BUFFER_START(Props)
		// put more per-instance properties here
		UNITY_INSTANCING_BUFFER_END(Props)

		void surf(Input IN, inout SurfaceOutputStandard o) {
			float d = tex2D(_DispTex, IN.uv_MainTex).r * _Displacement1Intensity;
			float d2 = tex2D(_DispTex2, IN.uv_MainTex).r * _Displacement2Intensity;
		

			float disp = d;
			if (_SubstractNoises) {
				disp = d - d2;
			}
			if (_AddNoises) {
				disp = d + d2;
			}
			if (_MultiplyNoises) {
				disp = d * d2;
			}
			if (_DivideNoises) {
				disp = d / d2;
			}
			if (_LimitByNoises) {
				if (disp > _Seuil) {
					//	if (disp > d2)
					disp = _Seuil;

				}
			}

			float2 colorReader = (1.0f, _ColorOffset + disp * _ColorTexRepetition + _Time.x *_ColorReadingSpeed);
			half4 c = tex2D(_MainTex, colorReader) * _Color1;
			if(disp == d2) {
			if (_UseTwoTextures) {
					c = tex2D(_MainTex2, IN.uv_MainTex.xy) * _Color2;
				}
			}
		
			o.Albedo = c.rgb;
			o.Metallic = _Metallic;
			o.Smoothness = _Glossiness;
			o.Alpha = c.a;
		}
		ENDCG
	}
	FallBack "Diffuse"
}