InfMap2.Shaders = {}

if not system.IsWindows() then
    return ErrorNoHalt("Shaders are not supported on systems other than windows (yet?). Sorry!")
end

if InfMap2.Visual.Shaders.Grass then
    print("[INFMAP2] Initialising grass shader!")
    include("infmap2/icl/shaders/grass.lua")

    InfMap2.Shaders.Grass.Init()
    hook.Add("Think", "InfMap2GrassShaderThink", function() InfMap2.Shaders.Grass.Think() end)
    hook.Add("PreDrawOpaqueRenderables", "InfMap2GrassShaderRender", function(_, _, sky3d) InfMap2.Shaders.Grass.Render() end)
end