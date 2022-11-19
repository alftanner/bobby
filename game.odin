package main

import "core:time"
import "core:thread"
import "core:sync"
import "core:slice"
import "core:math"
import "core:math/ease"
import "core:image"
import _ "core:image/png"
import "core:bytes"
import "core:os"
import "core:mem"
import "core:runtime"
import "core:fmt"

import swin "simple_window"

SKY_BLUE: image.RGBA_Pixel : {139, 216, 245, 255}
GAME_TITLE :: "Bobby Carrot Classic"

GLYPH_W, GLYPH_H :: 5, 7
Font :: struct {
	using texture: swin.Texture2D,
	table: map[rune]int,
}
font: Font
atlas: swin.Texture2D

Direction :: enum {
	None,
	Right,
	Left,
	Down,
	Up,
}

// since settings will be saved to the file, they probably should be packed
Settings :: struct #packed {
	fps, tps: uint,
	vsync: bool,
	show_stats, show_hitboxes: bool,
}
default_settings: Settings : {
	fps = 60,
	tps = 30,
	vsync = true,
	show_stats = true,
	show_hitboxes = true,
}
settings: Settings = default_settings

TILES_W :: 16
TILES_H :: 12
TILE_SIZE :: 16
TPS_SECOND :: default_settings.tps
IDLING_TIME :: TPS_SECOND * 5 // how much time before starts idling
LAYING_DEAD_TIME :: TPS_SECOND when !ODIN_DEBUG else 0 // how much time after dying
BUFFER_W :: TILES_W * TILE_SIZE
BUFFER_H :: TILES_H * TILE_SIZE
WINDOW_W :: BUFFER_W * 2
WINDOW_H :: BUFFER_H * 2

Sprite :: struct {
	using rect: swin.Rect,
	origin: [2]int,
}

Pos :: struct {
	using pos: [2]int,
	prev: [2]int,
}

Animation :: struct {
	state: bool,
	timer: uint,
	frame: uint,
	frame_len: uint,
}

Player :: struct {
	using position: Pos,
	sprite: Sprite,
	direction: Direction,

	walking: Animation,
	idle: Animation,
	dying: Animation,
	fading: Animation,
}

Level :: struct {
	index: int,
	w, h: int,
	tiles: []Tiles,
	carrots: int,
	end: Animation,
}

World :: struct {
	updated: bool,
	lock: sync.Mutex,

	player: Player,
	menu: bool,

	level: Level,
}
world: World = {
	menu = true,
}

State :: struct {
	// TODO: i128 with atomic_load/store
	client_size: i64, // stores 2 i32 values
	mouse_pos: i64,

	// _work shows how much time was spent on actual work in that frame before sleep
	// _time shows total time of the frame, sleep included
	frame_work, frame_time: time.Duration,
	tick_work, tick_time: time.Duration,
	previous_tick: time.Tick,

	key_data: [swin.Key_Code]u8, // 0 - not pressed, 1 - pressed, 2 - released
	key_data_lock: sync.Mutex,
}
global_state: State

window: swin.Window

Tiles :: enum {
	Grass,
	Fence,
	Ground,
	Carrot,
	Carrot_Hole,
	Start,
	Red_Button,
	Red_Button_Pressed,
	Wall_Left_Up,
	Wall_Right_Up,
	Wall_Right_Down,
	Wall_Left_Down,
	Wall_Up_Down,
	Wall_Left_Right,
	Trap,
	Trap_Activated,
	Belt_Left,
	Belt_Right,
	Belt_Up,
	Belt_Down,
	Silver_Key,
	Silver_Lock,
	Golden_Key,
	Golden_Lock,
	Bronze_Key,
	Bronze_Lock,
	Yellow_Button,
	Yellow_Button_Pressed,
	End,
	Egg_Spot,
	Egg,
}

Sprites :: enum {
	Grass,
	Grass_Right,
	Grass_Left,
	Grass_Down,
	Grass_Up,
	Grass_Right_Down,
	Grass_Left_Down,
	Grass_Left_Up,
	Grass_Right_Up,
	Grass_Down_Up_Right_Left,
	Grass_Down_Up,
	Grass_Right_Left,
	Fence_Right_Left,
	Fence_Down,
	Fence_Right_Down,
	Fence_Left_Down,
	Fence_Right,
	Fence_Left,
	Ground,
	Carrot,
	Carrot_Hole,
	Start,
	Red_Button,
	Red_Button_Pressed,
	Wall_Left_Up,
	Wall_Right_Up,
	Wall_Right_Down,
	Wall_Left_Down,
	Wall_Up_Down,
	Wall_Left_Right,
	Trap,
	Trap_Activated,
	Belt_Left,
	Belt_Right,
	Belt_Up,
	Belt_Down,
	Silver_Key,
	Silver_Lock,
	Golden_Key,
	Golden_Lock,
	Bronze_Key,
	Bronze_Lock,
	Yellow_Button,
	Yellow_Button_Pressed,
	End,
	Egg_Spot,
	Egg,
}

sprites: [Sprites]Sprite

grass_sprites: map[bit_set[Direction]]Sprites = {
	{.Right}                    = .Grass_Right,
	{.Left}                     = .Grass_Left,
	{.Down}                     = .Grass_Down,
	{.Up}                       = .Grass_Up,
	{.Right, .Down}             = .Grass_Right_Down,
	{.Left, .Down}              = .Grass_Left_Down,
	{.Left, .Up}                = .Grass_Left_Up,
	{.Right, .Up}               = .Grass_Right_Up,
	{.Down, .Up, .Right, .Left} = .Grass_Down_Up_Right_Left,
	{.Down, .Up}                = .Grass_Down_Up,
	{.Right, .Left}             = .Grass_Right_Left,
}

idling_animation := [?]Sprite {
	{{0,  96, 18, 25}, {-1, -9}},
	{{18, 96, 18, 25}, {-1, -9}},
	{{36, 96, 18, 25}, {-1, -9}},
}

walking_animation := [?]Sprite {
	{{54,  121, 18, 25}, {-1, -9}},
	{{0,   121, 18, 25}, {-1, -9}},
	{{18,  121, 18, 25}, {-1, -9}},
	{{36,  121, 18, 25}, {-1, -9}},
	{{54,  121, 18, 25}, {-1, -9}},
	{{72,  121, 18, 25}, {-1, -9}},
	{{90,  121, 18, 25}, {-1, -9}},
	{{108, 121, 18, 25}, {-1, -9}},
	{{126, 121, 18, 25}, {-1, -9}},
}

dying_animation := [?]Sprite {
	{{0,   247, 22, 27}, {-3, -11}},
	{{22,  247, 22, 27}, {-3, -11}},
	{{44,  247, 22, 27}, {-3, -11}},
	{{66,  247, 22, 27}, {-3, -11}},
	{{88,  247, 22, 27}, {-3, -11}},
	{{110, 247, 22, 27}, {-3, -11}},
	{{132, 247, 22, 27}, {-3, -11}},
	{{154, 247, 22, 27}, {-3, -11}},
}

fading_animation := [?]Sprite {
	{{0,   221, 18, 25}, {-1, -9}},
	{{18,  221, 18, 25}, {-1, -9}},
	{{36,  221, 18, 25}, {-1, -9}},
	{{54,  221, 18, 25}, {-1, -9}},
	{{72,  221, 18, 25}, {-1, -9}},
	{{90,  221, 18, 25}, {-1, -9}},
	{{108, 221, 18, 25}, {-1, -9}},
	{{126, 221, 18, 25}, {-1, -9}},
	{{144, 221, 18, 25}, {-1, -9}},
}

end_animation := [?]Sprite {
	{{64,  80, 16, 16},{}},
	{{80,  80, 16, 16},{}},
	{{96,  80, 16, 16},{}},
	{{112, 80, 16, 16},{}},
}

char_to_tile: map[rune]Tiles = {
	'.' = .Grass,
	' ' = .Ground,
	's' = .Start,
	'e' = .End,
	'c' = .Carrot,
	'-' = .Fence,
	't' = .Trap,
}

levels: [][]string = {
	{
		".........",
		"...   ...",
		".   e   .",
		". ----- .",
		". -ccc- .",
		". -ccc- .",
		". -ccc- .",
		". -- -- .",
		".       .",
		".   s   .",
		"...   ...",
		".........",
	},
	{
		"...........",
		"....   ....",
		".... e ....",
		".         .",
		". ---t--- .",
		". -ccccc- .",
		". -c c c- .",
		". -ccccc- .",
		". ---t--- .",
		".         .",
		"....   ....",
		".... s ....",
		"....   ....",
		"...........",
	},
	{
		".........",
		".... ....",
		"... e ...",
		".       .",
		".... ....",
		"..cctcc..",
		"..cctcc..",
		"..cctcc..",
		".... ....",
		".... ....",
		"...   ...",
		"... s ...",
		"...   ...",
		".........",
	},
}

save_2_ints :: #force_inline proc(p: ^i64, a, b: i32) {
	sync.atomic_store(p, transmute(i64)[2]i32{a, b})
}

get_2_ints :: #force_inline proc(p: ^i64) -> (i32, i32) {
	return expand_to_tuple(transmute([2]i32)sync.atomic_load(p))
}

limit_frame :: proc(frame_time: time.Duration, frame_limit: uint, accurate := true) {
	if frame_limit <= 0 do return

	ms_per_frame := time.Duration((1000.0 / f64(frame_limit)) * f64(time.Millisecond))
	to_sleep := ms_per_frame - frame_time

	if to_sleep <= 0 do return

	if accurate {
		time.accurate_sleep(to_sleep)
	} else {
		time.sleep(to_sleep)
	}
}

pixel_mod :: proc(dst: image.RGBA_Pixel, mod: image.RGB_Pixel) -> (pixel: image.RGBA_Pixel) {
	pixel.r = u8(cast(f32)dst.r * (cast(f32)mod.r / 255))
	pixel.g = u8(cast(f32)dst.g * (cast(f32)mod.g / 255))
	pixel.b = u8(cast(f32)dst.b * (cast(f32)mod.b / 255))
	pixel.a = dst.a
	return
}

draw_text :: proc(canvas: ^swin.Texture2D, text: string, px, py: ^int) {
	ox := px^

	for ch in text {
		if ch == '\n' {
			px^ = ox
			py^ += GLYPH_H + 1
			continue
		}

		glyph_idx := font.table[ch] or_else font.table['?']
		gx := (glyph_idx % (font.w / GLYPH_W)) * GLYPH_W
		gy := (glyph_idx / (font.w / GLYPH_W)) * GLYPH_H

		swin.draw_from_texture(canvas, font.texture, px^, py^, {gx, gy, GLYPH_W, GLYPH_H})

		px^ += GLYPH_W + 1
	}
}

draw_stats :: proc(canvas: ^swin.Texture2D) {
	@thread_local time_waited: time.Duration
	@thread_local lastu, lastf, fps, tps: Average_Calculator

	avg_add(&lastu, time.duration_milliseconds(sync.atomic_load(&global_state.tick_work)))
	avg_add(&lastf, time.duration_milliseconds(sync.atomic_load(&global_state.frame_work)))
	avg_add(&tps, 1000/time.duration_milliseconds(sync.atomic_load(&global_state.tick_time)))
	avg_add(&fps, 1000/time.duration_milliseconds(sync.atomic_load(&global_state.frame_time)))

	// DEBUG: see every frame time individually
	//fmt.println(1000/time.duration_milliseconds(sync.atomic_load(&global_state.frame_time)))

	@thread_local tick: time.Tick
	time_waited += time.tick_lap_time(&tick)
	if time_waited >= 50 * time.Millisecond {
		avg_calculate(&lastu)
		avg_calculate(&lastf)
		avg_calculate(&tps)
		avg_calculate(&fps)
		time_waited = 0
	}

	tbuf: [256]byte
	x, y: int = 1, 1
	text := fmt.bprintf(
		tbuf[:],
`{}FPS{} {}ms last
{}TPS {}ms last`,
		u32(math.round(fps.average)), " (VSYNC)" if settings.vsync else "", lastf.average,
		u32(math.round(tps.average)), lastu.average,
	)

	draw_text(canvas, text, &x, &y)
}

interpolate_tile_position :: #force_inline proc(frame_pos, tick_time: time.Duration, p: Player) -> [2]f32 {
	if p.walking.state {
		frame_len := 1/f32(world.player.walking.frame_len * (len(walking_animation) - 1))
		pos := f32(p.walking.timer) * frame_len
		frame_delta := f32(frame_pos) * (frame_len/f32(tick_time))
		delta := pos + frame_delta

		#partial switch p.direction {
		case .Right: return {f32(p.x) + delta, f32(p.y)}
		case .Left:  return {f32(p.x) - delta, f32(p.y)}
		case .Down:  return {f32(p.x), f32(p.y) + delta}
		case .Up:    return {f32(p.x), f32(p.y) - delta}
		}
	}

	return {f32(p.x), f32(p.y)}
}

interpolate_smooth_position :: #force_inline proc(frame_pos, tick_time: time.Duration, p: Player) -> [2]f32 {
	diff := p.pos - p.prev
	x_delta := f32(frame_pos) * (f32(diff.x)/f32(tick_time))
	y_delta := f32(frame_pos) * (f32(diff.y)/f32(tick_time))
	x := f32(p.prev.x) + x_delta
	y := f32(p.prev.y) + y_delta
	return {x, y}
}

render :: proc(window: ^swin.Window) {
	previous_tick: time.Tick
	tick_time: time.Duration
	draw_player := world.player
	menu := world.menu
	level := world.level

	canvas := swin.texture_make(BUFFER_W, BUFFER_H)
	background := swin.texture_make(BUFFER_W, BUFFER_H)
	for y in 0..<TILES_H do for x in 0..<TILES_W {
		swin.draw_from_texture(&background, atlas, x * TILE_SIZE, y * TILE_SIZE, sprites[.Grass])
	}

	clear_color := swin.color(expand_to_tuple(SKY_BLUE))

	for {
		start_tick := time.tick_now()

		client_w, client_h := get_2_ints(&global_state.client_size)
		tw := int(math.ceil(f32(client_w) / TILE_SIZE))
		th := int(math.ceil(f32(client_h) / TILE_SIZE))

		if tw * TILE_SIZE != background.w || th * TILE_SIZE != background.h {
			swin.texture_destroy(background)
			background = swin.texture_make(tw * TILE_SIZE, th*TILE_SIZE)
			for y in 0..<th do for x in 0..<tw {
				swin.draw_from_texture(&background, atlas, x*TILE_SIZE, y*TILE_SIZE, sprites[.Grass])
			}
		}

		if sync.atomic_load(&world.updated) {
			sync.guard(&world.lock)

			// save the world state
			menu = world.menu
			level = world.level
			draw_player = world.player
			previous_tick = global_state.previous_tick
			tick_time = sync.atomic_load(&global_state.tick_time)

			sync.atomic_store(&world.updated, false)
		}

		if menu {
			TITLE_SCREEN :: Sprite{rect = {0, 274, 128, 128}}
			swin.draw_from_texture(&canvas, background, 0, 0, {0, 0, canvas.w, canvas.h})
			off_x := (canvas.w - TITLE_SCREEN.w) / 2
			off_y := (canvas.h - TITLE_SCREEN.h) / 2
			swin.draw_from_texture(&canvas, atlas, off_x, off_y, TITLE_SCREEN)
		} else {
			slice.fill(canvas.pixels, clear_color)

			player_pos := interpolate_tile_position(time.tick_diff(previous_tick, time.tick_now()), tick_time, draw_player)
			offset_into_level, offset_around_level: [2]f32

			if level.w < TILES_W {
				offset_around_level.x = f32(TILES_W - level.w)/2
			} else {
				offset_into_level.x = f32(player_pos.x) - f32(TILES_W)/2
				offset_right := f32(level.w) - TILES_W - offset_into_level.x
				if offset_right < 0 {
					offset_into_level.x += offset_right
				} else {
					offset_into_level.x = max(offset_into_level.x, 0)
				}
			}
			if level.h < TILES_H {
				offset_around_level.y = f32(TILES_H - level.h)/2
			} else {
				offset_into_level.y = f32(player_pos.y) - f32(TILES_H)/2
				offset_bottom := f32(level.h) - TILES_H - offset_into_level.y
				if offset_bottom < 0 {
					offset_into_level.y += offset_bottom
				} else {
					offset_into_level.y = max(offset_into_level.y, 0)
				}
			}

			if offset_around_level.x > 0 || offset_around_level.y > 0 {
				x := -int((offset_around_level.x + offset_into_level.x) * TILE_SIZE)
				y := -int((offset_around_level.y + offset_into_level.y) * TILE_SIZE)
				swin.draw_from_texture(&canvas, background, x, y, {0, 0, background.w, background.h})
			}

			for tile, idx in level.tiles {
				sprite: Sprite = sprites[.Ground]
				#partial switch tile {
				case .Grass: sprite = sprites[.Grass] // TODO: grass generation
				case .Fence: sprite = sprites[.Fence_Right] // TODO: fence generation
				case .End:
					if world.level.end.state {
						sprite = end_animation[world.level.end.frame]
					} else {
						sprite = sprites[.End]
					}
				case .Start: sprite = sprites[.Start]
				case .Carrot: sprite = sprites[.Carrot]
				case .Carrot_Hole: sprite = sprites[.Carrot_Hole]
				case .Trap: sprite = sprites[.Trap]
				case .Trap_Activated: sprite = sprites[.Trap_Activated]
				}

				x := idx%level.w
				y := idx/level.w

				px := offset_around_level.x - offset_into_level.x + f32(x)
				py := offset_around_level.y - offset_into_level.y + f32(y)
				swin.draw_from_texture(&canvas, atlas, int(px * TILE_SIZE), int(py * TILE_SIZE), sprite)
			}

			px := int((player_pos.x + offset_around_level.x - offset_into_level.x) * TILE_SIZE) + draw_player.sprite.origin.x
			py := int((player_pos.y + offset_around_level.y - offset_into_level.y) * TILE_SIZE) + draw_player.sprite.origin.y
			swin.draw_from_texture(&canvas, atlas, px, py, draw_player.sprite)
		}

		if settings.show_stats {
			draw_stats(&canvas)
		}

		sync.atomic_store(&global_state.frame_work, time.tick_since(start_tick))

		if settings.vsync {
			swin.wait_vblank()
		} else {
			limit_frame(time.tick_since(start_tick), settings.fps)
		}
		swin.display_pixels(window, canvas, {0, 0, int(client_w), int(client_h)})

		sync.atomic_store(&global_state.frame_time, time.tick_since(start_tick))
	}
}

can_move_to :: proc(x, y: int) -> bool {
	tile := get_level_tile({x, y})
	if tile == .Grass || tile == .Fence {
		return false
	}
	return true
}

move_player :: #force_inline proc(d: Direction) {
	if !world.player.dying.state && !world.player.fading.state && !world.player.walking.state {
		#partial switch d {
		case .Right:
			if world.player.x == world.level.w - 1 do return
			if !can_move_to(world.player.x + 1, world.player.y) do return
		case .Left:
			if world.player.x == 0 do return
			if !can_move_to(world.player.x - 1, world.player.y) do return
		case .Down:
			if world.player.y == world.level.h - 1 do return
			if !can_move_to(world.player.x, world.player.y + 1) do return
		case .Up:
			if world.player.y == 0 do return
			if !can_move_to(world.player.x, world.player.y - 1) do return
		}
		world.player.direction = d
		world.player.walking.state = true
	}
}

get_level_tile :: #force_inline proc(pos: [2]int) -> Tiles {
	return world.level.tiles[(pos.y * world.level.w) + pos.x]
}

set_level_tile :: #force_inline proc(pos: [2]int, t: Tiles) {
	world.level.tiles[(pos.y * world.level.w) + pos.x] = t
}

move_player_to_tile :: proc(d: Direction) {
	original_pos := world.player.pos
	#partial switch d {
	case .Right:
		world.player.x += 1
	case .Left:
		world.player.x -= 1
	case .Down:
		world.player.y += 1
	case .Up:
		world.player.y -= 1
	}
	original_tile := get_level_tile(original_pos)
	current_tile := get_level_tile(world.player)

	#partial switch original_tile {
	case .Trap:
		set_level_tile(original_pos, .Trap_Activated)
	}

	#partial switch current_tile {
	case .Carrot:
		set_level_tile(world.player, .Carrot_Hole)
		world.level.carrots -= 1
		if world.level.carrots == 0 {
			world.level.end.state = true
		}
	case .Trap_Activated:
		world.player.dying.state = true
	case .End:
		if world.level.carrots == 0 {
			world.player.fading.state = true
		}
	}
}

load_level :: proc(index: int) {
	if len(world.level.tiles) != 0 {
		delete(world.level.tiles)
	}

	world.level = {
		end = {
			frame_len = 2,
		},
	}

	if index >= len(levels) {
		// TODO: end sequence
		world.menu = true
		return
	}

	world.level.index = index
	world.level.w = len(levels[index][0])
	world.level.h = len(levels[index])
	world.level.tiles = make([]Tiles, world.level.w * world.level.h)

	// reset player
	world.player = {
		walking = {
			frame_len = 2,
		},
		idle = {
			frame_len = 2,
		},
		dying = {
			frame_len = 3 when !ODIN_DEBUG else 1,
		},
		fading = {
			frame_len = 2,
		}
	}

	for row, y in levels[index] do for char, x in row {
		tile := char_to_tile[char] or_else .Ground
		set_level_tile({x, y}, tile)
		#partial switch tile {
		case .Start:
			world.player.pos = {x, y}
		case .Carrot:
			world.level.carrots += 1
		}
	}
}

keyboard_handler :: proc(key: swin.Key_Code, released: bool) {
	if world.menu{
		#partial switch key {
		case .Enter:
			if world.menu && released {
				// TODO: load levels properly
				load_level(world.level.index)
				world.menu = false
			}
		}
	} else {
		if released {
			#partial switch key {
			case .Escape:
				if !world.menu {
					world.menu = true
				}
			case .Num1: load_level(0)
			case .Num2: load_level(1)
			case .Num3: load_level(2)
			case .R: world.player.dying.state = true
			}
		}

		#partial switch key {
		case .Right: move_player(.Right)
		case .Left:  move_player(.Left)
		case .Down:  move_player(.Down)
		case .Up:    move_player(.Up)
		}
	}
}

player_set_walking_frame :: proc(frame: uint) {
	world.player.sprite = walking_animation[frame]
	#partial switch world.player.direction {
	case .Left:
		world.player.sprite.y += 25
	case .Up:
		world.player.sprite.y += 50
	case .Right:
		world.player.sprite.y += 75
	}
}

update_world :: proc(t: ^thread.Thread) {
	for {
		start_tick := time.tick_now()

		{
			sync.guard(&world.lock)

			world.player.position.prev = world.player.position.pos
			{ // keyboard inputs
				// NOTE: this input processor squashes multiple key presses in-between frames into a single keypress
				sync.guard(&global_state.key_data_lock)
				for data, key in &global_state.key_data {
					if data == 0 do continue

					keyboard_handler(key, data == 2)
					if data == 2 do data = 0
				}
			}

			if world.menu {
			} else {
				switch {
				case world.player.walking.state:
					world.player.idle.state = false
					world.player.idle.timer = 0
					world.player.idle.frame = 0

					world.player.walking.timer += 1

					if world.player.walking.timer % world.player.walking.frame_len == 0 {
						world.player.walking.frame += 1
					}

					WALKING_ANIMATION_LEN :: len(walking_animation) - 1 when !ODIN_DEBUG else 3 // speed walking during debug

					if world.player.walking.frame >= WALKING_ANIMATION_LEN {
						world.player.walking.state = false
						world.player.walking.timer = 0
						world.player.walking.frame = 0
						move_player_to_tile(world.player.direction)
					} else {
						player_set_walking_frame(world.player.walking.frame + 1)
					}
				case world.player.dying.state:
					world.player.dying.timer += 1

					if world.player.dying.timer % world.player.dying.frame_len == 0 {
						world.player.dying.frame += 1
					}
					if world.player.dying.frame >= len(dying_animation) {
						if world.player.dying.timer - (len(dying_animation) * world.player.dying.frame_len) >= LAYING_DEAD_TIME {
							world.player.dying.state = false
							world.player.dying.timer = 0
							world.player.dying.frame = 0
							load_level(world.level.index)
						}
					} else {
						world.player.sprite = dying_animation[world.player.dying.frame]
					}
				case world.player.fading.state:
					world.player.fading.timer += 1

					if world.player.fading.timer % world.player.fading.frame_len == 0 {
						world.player.fading.frame += 1
					}
					if world.player.fading.frame >= len(fading_animation) {
						world.player.fading.state = false
						world.player.fading.timer = 0
						world.player.fading.frame = 0
						load_level(world.level.index + 1)
					} else {
						world.player.sprite = fading_animation[world.player.fading.frame]
					}
				case world.player.idle.state:
					world.player.idle.timer += 1
					if world.player.idle.timer % world.player.idle.frame_len == 0 {
						world.player.idle.frame += 1
						world.player.idle.frame %= len(idling_animation)
					}
					world.player.sprite = idling_animation[world.player.idle.frame]
				case:
					player_set_walking_frame(0)
					world.player.idle.timer += 1
					if world.player.idle.timer > IDLING_TIME {
						world.player.idle.timer = 0
						world.player.idle.state = true
					}
				}
			}

			if world.level.end.state {
				world.level.end.timer += 1
				if world.level.end.timer % world.level.end.frame_len == 0 {
					world.level.end.frame += 1
					world.level.end.frame %= len(end_animation)
				}
			}

			global_state.previous_tick = time.tick_now()
			sync.atomic_store(&world.updated, true)
		}

		sync.atomic_store(&global_state.tick_work, time.tick_since(start_tick))

		limit_frame(time.tick_since(start_tick), settings.tps, false) // NOTE: not using accurate timer for 30 TPS, should I?

		sync.atomic_store(&global_state.tick_time, time.tick_since(start_tick))
	}
}

event_handler :: proc(window: ^swin.Window, event: swin.Event) {
	switch ev in event {
	case swin.Close_Event:
		if swin.show_message_box(.OkCancel, GAME_TITLE, "Do you really want to quit?", window) == .Cancel {
			window.must_close = false
		}
	case swin.Focus_Event:
		if ev.focused {
			settings.tps = default_settings.tps
		} else {
			settings.tps = 3
			sync.guard(&global_state.key_data_lock)
			for key in &global_state.key_data {
				// release all pressed keys
				if key == 1 do key = 2
			}
		}
	case swin.Draw_Event:
	case swin.Resize_Event:
		save_2_ints(&global_state.client_size, i32(window.client.w), i32(window.client.h))
	case swin.Move_Event:
	case swin.Character_Event:
	case swin.Keyboard_Event:
		switch ev.state {
		case .Repeat, .Released:
		case .Pressed:
			#partial switch ev.key {
			case .Q: window.must_close = true
			case .V: settings.vsync = !settings.vsync
			case .F: settings.show_stats = !settings.show_stats
			case .H: settings.show_hitboxes = !settings.show_hitboxes
			case .N: save_data("settings.save", &settings)
			case .B: settings = default_settings
			case .Num0: settings.fps = 0
			case .Num1: settings.fps = 10
			case .Num2: settings.fps = 200
			case .Num3: settings.fps = 30
			case .Num4: settings.fps = 144
			case .Num6: settings.fps = 60
			}
		}

		if ev.state == .Released || ev.state == .Pressed {
			sync.guard(&global_state.key_data_lock)
			global_state.key_data[ev.key] = 1 if ev.state == .Pressed else 2
		}
	case swin.Mouse_Button_Event:
	case swin.Mouse_Move_Event:
		save_2_ints(&global_state.mouse_pos, ev.x, ev.y)
	case swin.Mouse_Wheel_Event:
	}
}

load_texture :: proc(data: []byte, $layout: typeid) -> (t: swin.Texture2D) {
	img, err := image.load(data)
	assert(err == nil, fmt.tprint(err))
	defer image.destroy(img)

	t = swin.texture_make(img.width, img.height)

	pixels := mem.slice_data_cast([]layout, bytes.buffer_to_bytes(&img.pixels))
	for p, i in pixels {
		t.pixels[i] = swin.color(expand_to_tuple(p))
	}
	return
}

load_resources :: proc() {
	atlas = load_texture(#load("res/atlas.png"), image.RGBA_Pixel)
	font.texture = load_texture(#load("res/font.png"), image.RGBA_Pixel)

	font.table = make(map[rune]int)
	for ch in ` 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ?'".,:;~!@#$^&_|\/%*+-=<>()[]{}` {
		font.table[ch] = len(font.table)
	}

	MAX_X :: 12
	for s in Sprites {
		idx := int(s)
		x := idx%MAX_X
		y := idx/MAX_X
		sprites[s] = {rect = {x*TILE_SIZE, y*TILE_SIZE, TILE_SIZE, TILE_SIZE}}
	}
}

free_resources :: proc() {
	swin.texture_destroy(atlas)
	swin.texture_destroy(font.texture)
	delete(font.table)
}

_main :: proc() {
	load_resources()
	defer free_resources()

	if os.exists("settings.save") {
		load_data("settings.save", &settings)
	}

	// Open window
	fmt.println(WINDOW_W, WINDOW_H)
	ok := swin.create(&window, WINDOW_W, WINDOW_H, GAME_TITLE)
	assert(ok, "Failed to create window")
	defer swin.destroy(&window)

	{ // center the window
		wr := swin.get_working_area()
		swin.move(&window, wr.x + (wr.w/2 - window.w/2), wr.y + (wr.h/2 - window.h/2))
	}

	window.clear_color = SKY_BLUE.rgb
	window.event_handler = event_handler
	//swin.set_resizable(&window, true)
	swin.set_min_size(&window, WINDOW_W, WINDOW_H)

	save_2_ints(&global_state.client_size, i32(window.client.w), i32(window.client.h))

	update_thread := thread.create_and_start(fn = update_world, priority = .High)
	defer {
		thread.terminate(update_thread, 0)
		thread.destroy(update_thread)
	}

	render_thread := thread.create_and_start_with_poly_data(data = &window, fn = render, priority = .High)
	defer {
		thread.terminate(render_thread, 0)
		thread.destroy(render_thread)
	}

	for !window.must_close {
		swin.next_event(&window)
	}
}
