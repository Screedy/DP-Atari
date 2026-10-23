# Player movement

This document describes how the player character moves around a room, how the view scrolls with him, and why it is built this way. It reflects the code in `src/main.asm`, `src/player.asm`, `src/pmg.asm` and `src/dlist.asm`, and uses the first room, `university_outside`, as the running example.

## What the player can do

The player is a small character drawn with Player/Missile Graphics (PMG). He walks left and right along the whole width of the room and up and down within a narrow strip at the bottom of it. In `university_outside` that strip is the grass and the sidewalk in front of the university building. He cannot climb the building and he cannot step onto the road. The room is four screens wide, so when the player walks towards the edge of the screen, the room scrolls to follow him. When the room cannot scroll any further, because its first or last column is already visible, the player is allowed to walk all the way to the edge of the screen.

The player is controlled either with joystick 0 or with the keys W, A, S and D. Holding a key or the stick keeps him moving. He moves in one direction at a time; diagonal movement is not supported.

## The room on screen

A room is stored as a tile map in the reserved map area (`map_area`, `$8000`). Every byte of the map is a tile ID, and every tile is two characters placed side by side (see `src/tiles.asm`). `university_outside` is 80 tiles wide and 12 rows tall.

When a room is entered, `display_map` expands the whole tile map once into the canvas (`canvas`, `$4000`). The canvas therefore holds the complete room as characters: 12 rows of 160 characters each, 1920 bytes in total. The screen uses ANTIC mode 5, which shows 40 characters (20 tiles) per row and 12 rows, so only a window of 20 tiles out of the 80 is visible at any time.

Which part of the canvas is visible is decided by the display list in `src/dlist.asm`. Every one of its 12 mode lines has its own LMS (Load Memory Scan) address that tells ANTIC where in memory that line starts. Initially line *r* points at `canvas + r * 160`, which shows the leftmost 20 tiles of the room.

We expand the whole room into the canvas up front instead of drawing only the visible part, because it makes scrolling almost free. To scroll, the program only has to add or subtract a number from twelve addresses in the display list; no character data has to be copied while the game is running. The price is memory (1920 bytes instead of 480 for a single screen), which we can afford, and a rule that no canvas row may cross a 4 KB boundary, because ANTIC's address counter wraps around at 4 KB. With the canvas at `$4000-$477F` this rule is satisfied.

## Coordinates

The player sprite is built from all four players placed on top of each other, each one contributing one colour (hair, skin, clothes, boots). The sprite is 8 pixels wide and 8 lines tall.

The program uses two kinds of player coordinates, one for each axis.

**Horizontally** the position is a screen column, `player_col`, in tiles (0 to 19). A tile is two characters, an ANTIC mode 5 character is 4 colour clocks wide, so a tile is 8 colour clocks wide, and a normal-width player is also exactly 8 colour clocks wide. One tile therefore equals one player width, which is why the player moves one tile at a time. The hardware position is computed by `set_player_x` as `HPOS = 48 + 8 * player_col`, where 48 is the horizontal position of the left edge of the normal-width playfield.

**Vertically** the position is `player_y`, the PMG line on which the top of the sprite is drawn. The program uses double-line PMG resolution (bit 4 of `SDMCTL` is 0), so one PMG line covers two scanlines. One character row of ANTIC mode 5 is 16 scanlines tall, which is 8 PMG lines, which is exactly the height of the sprite. The display list starts with three blocks of 8 blank lines, which places screen row 0 at scanline 32, that is PMG line 16. Screen row *r* therefore starts at PMG line `16 + 8 * r`. This first value is the constant `pmg_row0` in `src/player.asm`.

Besides the player's screen position, the program remembers how far the view has been scrolled: `scroll_x` is the map column (in tiles) that is currently shown at the left edge of the screen. The player's position in the room is therefore `scroll_x + player_col`.

## Reading the controls

Every pass through `game_loop` first waits for the next video frame with `delay`, then calls `read_input`, and then performs at most one step of movement.

`read_input` returns the direction in the same format as the joystick register `STICK0`: four bits for up, down, left and right, where a 0 bit means "pressed". If a key is being held and it is one of W, A, S or D, the routine returns the bit pattern that the joystick would produce for that direction; otherwise it returns `STICK0` itself. Because both sources produce the same format, the rest of the program does not need to know where the input came from.

The keyboard is read directly from the POKEY chip rather than through the operating system's key buffer (`CH`). `SKSTAT` bit 2 is 0 for as long as any key is held down, and `KBCODE` contains the code of that key. This gives us "is the key held right now", which is what movement needs. The OS buffer, in contrast, reports a key once and then only repeats it after the auto-repeat delay, which would make the player stutter. The SHIFT and CTRL bits of `KBCODE` are masked off, so W and Shift+W behave the same. Keyboard control was added because development is currently done without a joystick; the joystick works exactly as before.

`game_loop` checks the directions in the order up, down, left, right and performs the first one that is pressed. This is why there is no diagonal movement. Diagonals would need two moves per step and more careful edge handling, and the game does not need them yet.

The `delay` at the start of the loop has two purposes. It sets the speed of the game (with a delay of one frame, the player can take up to 60 steps per second), and it makes sure that every change to the screen is made right after the vertical blank has begun. Changing the display list or the PMG memory at that moment means ANTIC never displays a half-updated picture.

## Walking left and right

`player_left` and `player_right` decide, for every step, whether the player moves on the screen or the room moves under him. The rule is the same in both directions.

If the player is still more than `scroll_margin` tiles (6) away from the screen edge he is walking towards, he simply moves one tile on the screen. If he has reached that margin and the room can still scroll in that direction, the room scrolls by one tile instead and the player stays where he is on the screen. If the room cannot scroll any further, because `scroll_x` is already 0 on the left or 60 (`map_w - view_w`) on the right, the player walks on towards the screen edge and stops in the very first or very last column.

Scrolling by one tile means moving the view by two characters. `scroll_rd` adds 2 to all twelve LMS addresses in the display list, and `scroll_lu` subtracts 2 from them; `scroll_x` is increased or decreased accordingly. The same two routines can also scroll by a whole row (`canvas_w` bytes), which is why they are named "right/down" and "left/up", but vertical scrolling is not used because the room is exactly one screen tall.

We chose "the player walks, the room follows" over keeping the player fixed in the middle of the screen. A fixed player is simpler, but it would never be able to reach the first and last ten tiles of the room, and those are where entrances and room exits will be. The margin of six tiles keeps some of the room visible ahead of the player in the direction he is walking.

## Walking up and down

The walkable strip of the current room is defined by two map rows in `src/main.asm`, `walk_row_top` and `walk_row_bottom`. For `university_outside` they are rows 9 and 10, the grass and the sidewalk. Row 8 is the ground floor of the building and row 11 is the road; both are off limits.

`player_up` and `player_down` move the sprite by `step_y` PMG lines (2 lines, that is 4 scanlines) and keep `player_y` between `walk_y_min` and `walk_y_max`. Vertical steps are much finer than horizontal ones because PMG can be moved by a single line simply by drawing the sprite one line higher or lower in memory, whereas horizontal movement is tied to the tile grid so that walking and scrolling always move by the same amount.

The lowest position, `walk_y_max`, puts the whole sprite on the bottom walkable row. The highest position, `walk_y_min`, deliberately lets the sprite overlap the row above the walkable strip: only the last `feet_lines` lines of the sprite (2 lines, the legs and the boots) have to stand on the top walkable row, while the head and the body may cover the wall behind him. This gives the impression that the player is standing on the ground in front of the building rather than floating under it, and it gives him more room to move up and down. A build-time check makes sure that the distance between the two limits is a whole number of `step_y` steps, so the player always lands exactly on both limits.

## Collision

Inside rooms will contain walls, tables, doors and other objects the player must not walk through. Collision is tile based and follows the idea from EdVenture episode 13: before every step the program looks at the tiles directly around the player, and a move is refused if the tile it leads to is solid.

Whether a tile is solid is not decided by its ID but by a small table of properties, `tile_flags` in `src/tiles.asm`. Every tile ID has one byte there, and bit 0 (`TILE_SOLID`) marks tiles the player cannot stand on. Today the empty tile is walkable and all building tiles (bricks, windows, the ground-floor glass) are solid. A table instead of a fixed rule such as "tile 1 is a wall" means that every new tile, whether a table, a cupboard or a door, simply gets its own flags when it is added, and later properties (for example "this tile is a door" or "this tile leads to another room") can use the remaining bits of the same byte. A build-time check makes sure the table has exactly one entry per tile.

Once per pass of `game_loop`, before the controls are read, `look_around` in `src/player.asm` reads five tiles from the map into variables: the tile the player stands on (`on_tile`) and the tiles above, below, to the left and to the right of it (`up_tile`, `down_tile`, `left_tile`, `right_tile`). "Where the player stands" is decided by his feet, the last `feet_lines` lines of the sprite, because the rest of the sprite may overlap the row above (see the previous section). The routine converts the PMG line of the feet into a map row and remembers how far down inside that row the feet are (`feet_off`). It then points `ZP_SRC` at the tile above the player, `map_area + (row - 1) * map_w + scroll_x + player_col`, and reads all five tiles from that single pointer with different Y offsets: 0 for the tile above, `map_w - 1`, `map_w` and `map_w + 1` for the row of the feet, and `2 * map_w` for the tile below. Because Y is one byte, this works for maps up to 127 tiles wide, which a build-time check enforces.

The movement routines use these values as follows. `player_left` and `player_right` refuse to move if `left_tile` or `right_tile` is solid; this blocks both walking on the screen and scrolling the map, because both move the player within the room. Vertical movement is finer than one tile, so `player_up` and `player_down` only consult the map when a step would move the feet into the neighbouring row. That happens only when the feet are at the very top of their row (`feet_off = 0`) and the player moves up, or at the very bottom (`feet_off = 8 - feet_lines`) and he moves down. Within a row the player moves freely. A build-time check ensures that the feet always fit inside one row, so these are the only two crossing points.

This differs from Ed's version in three ways, all following from how our player moves. Ed's player always moves a whole tile and stays in the middle of the screen, so his position is simply a map column and row; ours walks across the screen and moves vertically in 2-line steps, so the map position is computed from `scroll_x`, `player_col` and the feet. Ed reads the neighbouring tiles while redrawing his screen; we do not redraw the screen, so a separate routine reads them. And Ed treats tile ID 1 as the wall, while we use the flags table described above.

The row limits `walk_row_top` and `walk_row_bottom` remain as the outer bounds of the room. On `university_outside` the walkable rows contain only empty tiles, so collision never blocks anything there and the room behaves exactly as before; inside rooms will rely on solid tiles instead.

## Drawing the sprite

Horizontal movement only changes the four `HPOSP` registers, which `set_player_x` does in a few instructions.

Vertical movement redraws the sprite: `draw_player` clears the PMG memory of all four players with `clear_pmg` and then copies the 8 lines of each layer from `pmgdata` to the new `player_y`. Clearing the whole 512 bytes on every vertical step is the simplest correct way to remove the sprite from its old position. It takes roughly 3,200 cycles, which is well inside the time between the vertical blank and the moment ANTIC reaches the bottom of the screen where the player stands, so the sprite never flickers.

## Settings

| Name | File | Value | Meaning |
|---|---|---|---|
| `walk_row_top`, `walk_row_bottom` | `main.asm` | 9, 10 | Walkable map rows of the current room. |
| `scroll_margin` | `player.asm` | 6 | Distance (tiles) from the screen edge at which the room starts to scroll. |
| `step_y` | `player.asm` | 2 | PMG lines per vertical step. |
| `feet_lines` | `player.asm` | 2 | Sprite lines that must stand on the top walkable row. |
| `pmg_row0` | `player.asm` | 16 | PMG line of screen row 0. Calibration value: if the sprite appears a few lines off, adjust this. |
| `hpos_col0` | `player.asm` | 48 | Horizontal position of screen column 0. |
| delay in `game_loop` | `main.asm` | 1 | Frames per step; higher means slower movement. |

## Limitations and next steps

- Scrolling is coarse: the view jumps by one tile. Smooth scrolling would add the hardware fine-scroll register `HSCROL` and move the view by single colour clocks between the coarse steps.
- Collision checks only the four neighbours of the tile under the feet. An object that should block the player only partly (for example the edge of a table) has to be a whole solid tile.
- `on_tile` is read but not used yet; it is meant for doors and room exits.
- `walk_row_top`, `walk_row_bottom`, `map_w` and `map_h` are assembly-time constants of the current room. When several rooms are loaded at run time, they will have to become values stored with each room.
- There is no diagonal movement and no walking animation yet.
