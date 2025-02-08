<div align="center"><h1>InfMap2</h1><p>Breaking source bounds since 2024</p></div>

[![see the workshop item](https://img.shields.io/badge/see%20on-steam%20workshop-0077ff?style=for-the-badge&logo=steam&logoColor=%230077ff)](https://steamcommunity.com/sharedfiles/itemedittext/?id=3423422716)
---

This is a successor to [Infinite Map Base](https://github.com/meetric1/gmod-infinite-map) (hereinafter: infmap1) made by [meetric1](https://github.com/meetric1).
Because infinite map base is now (pretty much) discontinued, I decided to attempt to rewrite it, providing better performance, easier API, more features and better compatibility.

Features
---
- Example infinite map `gm_inf_bliss` (duh)
- Even better addon support (compared to infmap1)
- Ability to see over 2bil+ hammer units in real time (depends on your computer)
- Most vehicle bases support (i think)

How It Works
---
The map isnt actually infinite - its impossible to go past the source bounds physically, so the entirety of the play space in the map is occupied in the same location.
A hook is used to determine which props should and should not collide, and all entities are given perceived visual offsets per entity depending on which chunk (or cell) they are in, giving the illusion that the map is (presumably) infinite. \
For a video explanation, see Meetric's video - infmap2 isn't any different. [`Infinite Map - Better Explanation`](https://www.youtube.com/watch?v=NPsxeRELlNY)

Documentation
---
TODO: docs
