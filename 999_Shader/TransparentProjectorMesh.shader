Shader "WL3/Scene/S_OnProjectorMesh"
{
	Properties
	{
	}
	
	SubShader
	{
		LOD 200

		Tags
		{
			"Queue" = "Geometry+1" 
			"IgnoreProjector" = "False"
			"RenderType" = "Opaque"
		}
		Pass{
			Cull Off
			Lighting Off
			ZWrite Off
			//πÿ±’—’…´ª∫≥Â–¥»Î
			ColorMask 0
		}
	}
	FallBack "Transparent/Cutout/VertexLit"
}
