Shader "shixiu/CameraGlowEffect" 
{
	Properties 
	{
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_GlowColor ("GlowColor", Color) = (0,0,0,1)
	}
	
	SubShader 
	{
		Pass
		{
			CGPROGRAM
			#pragma vertex vert_img
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			#include "UnityCG.cginc"
			
			uniform sampler2D _MainTex;
			uniform float4 _GlowColor;

			fixed4 frag(v2f_img i) : COLOR
			{
				//Get the colors from the RenderTexture and the uv's
				//from the v2f_img struct
				fixed4 renderTex = tex2D(_MainTex, i.uv);
				renderTex.rgb += _GlowColor.rgb*0.1;
				return renderTex;
			}
			ENDCG
		}
	} 
	FallBack off
}
