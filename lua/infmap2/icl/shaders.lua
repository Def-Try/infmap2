InfMap2.Shaders = {}
include("infmap2/icl/shaders/grass.lua")

InfMap2.Shaders.Grass.Init()
hook.Add("Think", "InfMap2GrassShaderThink", function()
    InfMap2.Shaders.Grass.Think()
end)
hook.Add("PreDrawOpaqueRenderables", "InfMap2GrassShaderRender", function(_, _, sky3d)
    InfMap2.Shaders.Grass.Render()
end)