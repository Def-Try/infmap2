<div align="center"><h1>InfMap2</h1><p>Breaking source bounds since 2024</p></div>

[![see the workshop item](https://img.shields.io/badge/see%20on-steam%20workshop-0077ff?style=for-the-badge&logo=steam&logoColor=%230077ff)](https://steamcommunity.com/sharedfiles/itemedittext/?id=3423422716)
---

This is a successor to [Infinite Map Base](https://github.com/meetric1/gmod-infinite-map) (hereinafter: infmap1) made by [meetric1](https://github.com/meetric1).
Because infinite map base is now (pretty much) discontinued, I decided to attempt to rewrite it, providing better performance, easier API, more features and better compatibility.

Features
---
- Example infinite map `gm_inf_bliss` (duh)
- Even better addon support (compared to infmap1)
- Ability to see over 2bil+ hammer units in real time (depends on map and your computer)
- Most vehicle bases support (including Glide!)

How It Works
---
The map isnt actually infinite - its impossible to go past the source bounds physically, so the entirety of the play space in the map is occupied in the same location.
A hook is used to determine which props should and should not collide, and all entities are given perceived visual offsets per entity depending on which chunk (or cell) they are in, giving the illusion that the map is (presumably) infinite. \
For a video explanation, see Meetric's video - infmap2 isn't any different. [`Infinite Map - Better Explanation`](https://www.youtube.com/watch?v=NPsxeRELlNY)

Documentation
---
TODO: docs

Creating Your Own Infmap
---
For a quick start, see comments for default [`gm_inf_bliss`](https://github.com/Def-Try/infmap2/blob/main/lua/infmap2/gm_inf_bliss) map.
In short, entire map is generated using math - a function is defined to turn point on a plane into height at that point. \
For example,
```lua
-- z = |x| + |y| - 15
function height_function(x, y)
    return math.abs(x) + math.abs(y) - 15
end
```
will make a map with terrain going up in each indefinitely. \
If we'd want our terrain to be sloped on X axis while limiting it at heights -1000 and 1000, we'd have our function be like:
```lua
-- z = max(-1000, min(0.5x, 1000))
function height_function(x, y)
    -- you don't have to use both coordinates!
    return math.max(-1000, math.min(0.5 * x, 1000))
end
```
To make our map work, we have to:
1. Create a BSP base. Copying default (gm_inf_bliss) one should work. Please note that second word in it *has* to be `inf`, otherwise map won't be recognized!
2. Create `lua/infmap2/<your_map_name>` directory in your addon.
3. Create `lua/infmap2/<your_map_name>/main.lua` file in your addon with next contents:
```lua
return {
    world = {
        terrain = {
            has_terrain = true, -- don't change!!
            height_function = function(x, y) -- your height function here!
                return math.max(-1000, math.min(0.5 * x, 1000))
            end,
        }
    },
    visual = {
        renderdistance = 2, -- how much to render
        terrain = {
            material = "infmap2/grasslit", -- your map material here!
            uvscale = 100 -- change to scale texture to terrain!
        }
    }
}
```
Everything else just describes how map looks or behaves. \
If you want to know more, see Documentation.
