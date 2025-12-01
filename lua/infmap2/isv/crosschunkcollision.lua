-- cross chunk collision is too expensive to be fully complete each tick...
-- ...apparently... ...according to infmap1 ccc...

local neighbors = {}
for x=-1,1 do for y=-1,1 do for z=-1,1 do
    if x == 0 and y == 0 and z == 0 then continue end -- same chunk, ignore
    neighbors[#neighbors+1] = Vector(x, y, z)
end end end

local vector_half = Vector(1, 1, 1) / 2

-- vvvvvv     coroutine and error handling setup 
local coro = coroutine.create(function() while true do local succ, err = pcall(function()
    do return end
    for _, ent in ents.Iterator() do
        if InfMap2.UselessEntitiesFilter(ent) then continue end
        if not ent:IsSolid() then continue end
        if not ent:GetModel() then continue end

        -- todo: is that even needed?
        if IsValid(ent:GetParent()) then continue end

        if ent:IsPlayer() and (ent:GetMoveType() == MOVETYPE_NOCLIP or not ent:Alive()) then continue end

        -- yield here, we're about to do some expensive shit
        coroutine.yield()
        -- entity may have became invalid
        if not IsValid(ent) then continue end

        -- fast bounding radius check
        local bounding_radius = ent:BoundingRadius()
        if bounding_radius < 10 then continue end -- too small, ignore

        if InfMap2.PositionInChunkSpace(ent:INF_GetPos(), InfMap2.ChunkSize - bounding_radius*2) then
            -- outside of cloning area
            if not ent.INF_Clones then continue end
            for i=1,table.maxn(ent.INF_Clones) do SafeRemoveEntity(ent.INF_Clones[i]) end
            ent.INF_Clones = nil
            continue
        end
        
        ent.INF_Clones = ent.INF_Clones or {}

        local aabb_min, aabb_max = ent:INF_WorldSpaceAABB()

        for i=1,#neighbors do
            local neighbor = neighbors[i]
            local chunk_pos = neighbor * InfMap2.ChunkSize
            local chunk_min, chunk_max = chunk_pos - vector_half * InfMap2.ChunkSize, chunk_pos + vector_half * InfMap2.ChunkSize

            if InfMap2.IntersectBox(aabb_min, aabb_max, chunk_min, chunk_max) then
                -- don't clone twice
                if IsValid(ent.INF_Clones[i]) then continue end

                local e = ents.Create("inf_crosschunkclone")
                ---@diagnostic disable-next-line: undefined-field
                e:SetReferenceEntity(ent)
                ---@diagnostic disable-next-line: undefined-field
                e:SetReferenceChunk(neighbor)
                e:Spawn()
                ent.INF_Clones[i] = e
            else
                if not ent.INF_Clones[i] then continue end
                SafeRemoveEntity(ent.INF_Clones[i])
                ent.INF_Clones[i] = nil
            end
        end
    end
end) if not succ then ErrorNoHalt("Cross Chunk Collision error: ", err) end coroutine.yield() end end)
-- ^^^^^^     error handle exit, yield coroutine, report error if any

hook.Add("Think", "InfMap2CrossChunkCollision", function() coroutine.resume(coro) end)