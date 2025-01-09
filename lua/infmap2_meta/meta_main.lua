---@meta

---InfMap2 main table.
---@class InfMap2 table
InfMap2 = {}

---Show debug information?
InfMap2.Debug = false

---InfMap2 cache
InfMap2.Cache = {}

---Max velocity on infmap. Default is Mach 20 in hammer units
InfMap2.MaxVelocity = 13503.95 * 20

---Whether that infmap uses default terrain generator
InfMap2.UsesGenerator = true

---Height function for default infmap generator
InfMap2.HeightFunction = function(x, y) end
---Sample size for default infmap generator
InfMap2.SampleSize = 5000
---Whether to generate normals per vertex or per face on default infmap generator
InfMap2.PerFaceNormals = true
---Whether to do custom lighting using default infmap generator
InfMap2.DoLighting = false

---Terrain material for default infmap generator
InfMap2.Material = "infmap2/grasslit"
---UV Material scale for default infmap generator
InfMap2.UVScale = 100
---Render distance in chunks
InfMap2.RenderDistance = 1


---Chunk size.
InfMap2.ChunkSize = 20000
---Megachunk size.
InfMap2.MegachunkSize = 10

--Source bounds
InfMap2.SourceBounds = Vector(2^14, 2^14, 2^14)