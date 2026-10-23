# Future ideas

Ideas that have been thought through but not implemented yet. Each one describes what it would do, how it fits into the current code, and what it would cost.

## Dark rooms and a torchlight effect

The server room could demonstrate that there is less light than elsewhere in the building. There are two ways to do this, and they can be combined.

### Option 1: dimmed colours

Every Atari colour register holds a hue in its upper four bits and a brightness in its lower four bits. When the player enters a dark room, the program would load darker values into `COLOR0`–`COLOR4` (a few `MVA` instructions in the room's setup) and restore the normal values when he leaves. The whole room then looks dim. This needs practically no code, but the darkness is even over the whole room; there is no light around the player.

### Option 2: a circle of light around the player

This is the effect from EdVenture episode 12 ("Torchlight View"). Only the tiles near the player are drawn; the rest of the room stays black, and the lit circle moves with him.

It fits next to the current rendering instead of replacing it:

- When a dark room is entered, `display_map` does not expand the room into the canvas. It fills the canvas with an empty (or dedicated dark) tile instead. The tile map in `map_area` stays complete, so walking limits and any later collision logic still read the real room.
- After every player step, a new routine (for example `update_light`) erases the previous circle and then draws the tiles inside the new circle from the map into the canvas, using the existing `draw_tile`. The shape of the circle is a small table that says how many tiles are lit on each row above and below the player, the same idea as Ed's `blit_circle_line 5, 7, 9, 9, …`.
- `game_loop` gets one extra check: if the current room is dark, call `update_light` after the move. Normal rooms skip it and behave exactly as they do now.

Nothing else has to change. The wide canvas, the LMS scrolling in the display list, `player.asm`, the PMG sprite and `read_input` all stay as they are, and the server room map is an ordinary tile map; darkness is only a way of showing it. If the server room is no wider than one screen (20 tiles), the light circle never has to deal with scrolling at all.

The cost is CPU time only in the dark room. A circle the size of Ed's covers about 70 tiles, which is roughly 7,000 cycles per step, about a quarter of a frame. The code is one routine with its shape table, a "dark" flag for the room, and the one-line hook in `game_loop`.

### Prerequisite

Room properties such as `map_w`, `map_h`, `walk_row_top` and `walk_row_bottom` are currently assembly-time constants of the one room that exists. Once there are several rooms, each room needs a small block of its own properties that the program reads when the room is entered. The "dark" flag (and, for option 1, the room's colours) would simply be two more entries in that block, so the torchlight adds very little on top of the work that multiple rooms need anyway.

### Suggested order

Start with option 1, which is nearly free and already shows "less light". Add option 2 if the stronger effect is wanted for the thesis demonstration.
