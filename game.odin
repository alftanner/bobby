package main

import "core:time"
import "core:thread"
import "core:sync"
//import "core:slice"
import "core:math"
//import "core:math/ease"
import "core:container/small_array"
import "core:strconv"
import "core:strings"
import "core:image"
import _ "core:image/png"
import "core:bytes"
import "core:os"
import "core:mem"
import "core:fmt"

import swin "simple_window"

SKY_BLUE: image.RGBA_Pixel : {139, 216, 245, 255}
GAME_TITLE :: "Bobby Carrot Classic"

// since settings will be saved to the file, they probably should be packed
Settings :: struct #packed {
	fps, tps: uint,
	vsync: bool,
	show_stats: bool,
}
default_settings: Settings : {
	fps = 60,
	tps = 30,
	vsync = true,
	show_stats = true when ODIN_DEBUG else false,
}
settings: Settings = default_settings

TILES_W :: 12
TILES_H :: 12
TILE_SIZE :: 16
TPS_SECOND :: default_settings.tps
IDLING_TIME :: TPS_SECOND * 5 // how much time before starts idling
LAYING_DEAD_TIME :: TPS_SECOND / 3 when !ODIN_DEBUG else 0 // how much time after dying
BUFFER_W :: TILES_W * TILE_SIZE
BUFFER_H :: TILES_H * TILE_SIZE
DEFAULT_SCALE :: 3
WINDOW_W :: BUFFER_W * DEFAULT_SCALE
WINDOW_H :: BUFFER_H * DEFAULT_SCALE

Font :: struct {
	using texture: swin.Texture2D,
	table: map[rune][2]int,
	glyph_size: struct{w, h: int},
}
general_font: Font
hud_font: Font
atlas: swin.Texture2D

Direction :: enum {
	None,
	Right,
	Left,
	Down,
	Up,
}

Position_Queue :: small_array.Small_Array(256, [2]int) // max animations on the screen
Region_Cache :: small_array.Small_Array(64, swin.Rect) // redraw regions

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

	belt: bool,
	silver_key, golden_key, copper_key: bool,
}

Level :: struct {
	w, h: int,
	tiles: []Tiles,
	carrots: int,
	animation: Animation,
	can_end, ended: bool,
	current, next: int,
	start_tick: time.Time,
	end_time: time.Duration,
	steps: int,

	// for rendering
	changed: bool,
	changes: []bool,
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

Key_State :: enum {
	Pressed,
	Repeated,
	Held,
	Released,
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

	frame_inputs: struct {
		lock: sync.Mutex,
		keys: [swin.Key_Code]bit_set[Key_State]
	}
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
	Copper_Key,
	Copper_Lock,
	Yellow_Button,
	Yellow_Button_Pressed,
	End,
	Egg_Spot,
	Egg,
}

belt_tiles: bit_set[Tiles] = {
	.Belt_Left,
	.Belt_Right,
	.Belt_Up,
	.Belt_Down,
}
wall_tiles: bit_set[Tiles] = {
	.Wall_Left_Right,
	.Wall_Up_Down,
	.Wall_Right_Up,
	.Wall_Left_Down,
	.Wall_Right_Down,
	.Wall_Left_Up,
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
	Copper_Key,
	Copper_Lock,
	Yellow_Button,
	Yellow_Button_Pressed,
	End,
	Egg_Spot,
	Egg,
}

sprites: [Sprites]Sprite

HUD_Sprites :: enum {
	Carrot,
	Egg,
	Eyes,
	Silver_Key,
	Golden_Key,
	Copper_Key,
	Success,
}

hud_sprites: [HUD_Sprites]Sprite = {
	.Carrot     = {{128, 80, 14, 13},{}},
	.Egg        = {{142, 80, 9,  13},{}},
	.Eyes       = {{151, 80, 15, 13},{}},
	.Silver_Key = {{166, 80, 8,  13},{}},
	.Golden_Key = {{174, 80, 8,  13},{}},
	.Copper_Key = {{182, 80, 8,  13},{}},
	.Success    = {{128, 93, 54, 13},{}},
}

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
	{.Down, .Up, .Right}        = .Grass_Down_Up,
	{.Down, .Up, .Left}         = .Grass_Down_Up,
	{.Right, .Left, .Down}      = .Grass_Right_Left,
	{.Right, .Left, .Up}        = .Grass_Right_Left,
}

fence_sprites: map[bit_set[Direction]]Sprites = {
	{.Right, .Left}        = .Fence_Right_Left,
	{.Down}                = .Fence_Down,
	{.Right, .Down}        = .Fence_Right_Down,
	{.Left, .Down}         = .Fence_Left_Down,
	{.Right}               = .Fence_Right,
	{.Left}                = .Fence_Left,
	{.Right, .Left, .Down} = .Fence_Right_Left,
}

wall_switch: map[Tiles]Tiles = {
	.Wall_Left_Right = .Wall_Up_Down,
	.Wall_Up_Down = .Wall_Left_Right,
	.Wall_Right_Up = .Wall_Right_Down,
	.Wall_Left_Down = .Wall_Left_Up,
	.Wall_Right_Down = .Wall_Left_Down,
	.Wall_Left_Up = .Wall_Right_Up,
}

belt_switch: map[Tiles]Tiles = {
	.Belt_Left = .Belt_Right,
	.Belt_Right = .Belt_Left,
	.Belt_Up = .Belt_Down,
	.Belt_Down = .Belt_Up,
}

idling_animation := [?]Sprite {
	{{0,  96, 18, 25}, {-1, -9}},
	{{18, 96, 18, 25}, {-1, -9}},
	{{36, 96, 18, 25}, {-1, -9}},
}

walking_animation := [?]Sprite {
	{{54,  121, 18, 25}, {-1, -9}},
	{{72,  121, 18, 25}, {-1, -9}},
	{{90,  121, 18, 25}, {-1, -9}},
	{{108, 121, 18, 25}, {-1, -9}},
	{{126, 121, 18, 25}, {-1, -9}},
	{{0,   121, 18, 25}, {-1, -9}},
	{{18,  121, 18, 25}, {-1, -9}},
	{{36,  121, 18, 25}, {-1, -9}},
}
WALKING_ANIM_LEN :: len(walking_animation) when !ODIN_DEBUG else 6 // speed walking during debug

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
	{{162, 221, 18, 25}, {-1, -9}},
}

end_animation := [?]Sprite {
	{{64,  80, 16, 16},{}},
	{{80,  80, 16, 16},{}},
	{{96,  80, 16, 16},{}},
	{{112, 80, 16, 16},{}},
}

belt_animation := [?]Sprite {
	{{0,  64, 16, 16},{}},
	{{16, 64, 16, 16},{}},
	{{32, 64, 16, 16},{}},
	{{48, 64, 16, 16},{}},
}

save_2_ints :: #force_inline proc(p: ^i64, a, b: i32) {
	sync.atomic_store(p, transmute(i64)[2]i32{a, b})
}

get_2_ints :: #force_inline proc(p: ^i64) -> (i32, i32) {
	return expand_to_tuple(transmute([2]i32)sync.atomic_load(p))
}

limit_frame :: proc(frame_time: time.Duration, frame_limit: uint, accurate := true) {
	if frame_limit <= 0 do return

	ms_per_frame := time.Duration((1000.0 / f32(frame_limit)) * f32(time.Millisecond))
	to_sleep := ms_per_frame - frame_time

	if to_sleep <= 0 do return

	if accurate {
		time.accurate_sleep(to_sleep)
	} else {
		time.sleep(to_sleep)
	}
}

measure_or_draw_text :: proc(canvas: ^swin.Texture2D, font: Font, text: string, pos: [2]int, no_draw := false) -> (region: swin.Rect) {
	pos := pos
	region.x = pos.x
	region.y = pos.y

	for ch in text {
		if ch == '\n' {
			pos.x = region.x
			pos.y += font.glyph_size.h + 1
			continue
		}

		glyph_pos := font.table[ch] or_else font.table['?']
		if !no_draw {
			swin.draw_from_texture(canvas, font.texture, pos.x + 1, pos.y + 1, {glyph_pos.x, glyph_pos.y, font.glyph_size.w, font.glyph_size.h}, .None, {})
			swin.draw_from_texture(canvas, font.texture, pos.x, pos.y, {glyph_pos.x, glyph_pos.y, font.glyph_size.w, font.glyph_size.h})
		}

		pos.x += font.glyph_size.w + 1
		region.w = max(region.w, pos.x)
	}
	region.h = pos.y + font.glyph_size.h + 1

	return
}

draw_text :: proc(canvas: ^swin.Texture2D, font: Font, text: string, pos: [2]int) -> (region: swin.Rect) {
	return measure_or_draw_text(canvas, font, text, pos)
}

measure_text :: proc(font: Font, text: string) -> (w, h: int) {
	region := measure_or_draw_text(nil, font, text, {}, true)
	return region.w, region.h
}

draw_stats :: proc(canvas: ^swin.Texture2D) -> swin.Rect {
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
	text := fmt.bprintf(
		tbuf[:],
`{}FPS{} {}ms last
{}TPS {}ms last`,
		u32(math.round(fps.average)), " (VSYNC)" if settings.vsync else "", lastf.average,
		u32(math.round(tps.average)), lastu.average,
	)

	x := canvas.w - 2
	y := canvas.h - 2
	{
		w, h := measure_text(general_font, text)
		x -= w
		y -= h
	}
	return draw_text(canvas, general_font, text, {x, y})
}

interpolate_tile_position :: #force_inline proc(frame_pos, tick_time: f32, p: Player) -> [2]f32 {
	if p.walking.state {
		anim_frame_len := f32(p.walking.frame_len * WALKING_ANIM_LEN)
		frame_delta := frame_pos / tick_time
		delta := (f32(p.walking.timer) + frame_delta) / anim_frame_len
		// even if frame was too long after the tick, we don't want to overextend the position any further than it can normally be
		delta = min(delta, 1)

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

/*
TODO:
save time and steps
show game end screen
menu
*/

get_sprite_from_tile :: proc(pos: [2]int) -> Sprite {
	tile := get_level_tile(pos)
	sprite: Sprite = sprites[.Ground]

	#partial switch tile {
	case .Grass:
		d: bit_set[Direction]
		if get_level_tile({pos.x - 1, pos.y}) != .Grass do d += {.Left}
		if get_level_tile({pos.x + 1, pos.y}) != .Grass do d += {.Right}
		if get_level_tile({pos.x, pos.y - 1}) != .Grass do d += {.Up}
		if get_level_tile({pos.x, pos.y + 1}) != .Grass do d += {.Down}
		sprite = sprites[grass_sprites[d] or_else .Grass]
	case .Fence:
		d: bit_set[Direction]
		if get_level_tile({pos.x - 1, pos.y}) == .Fence do d += {.Left}
		if get_level_tile({pos.x + 1, pos.y}) == .Fence do d += {.Right}
		//if get_level_tile({pos.x, pos.y - 1}) == .Fence do d += {.Up}
		if get_level_tile({pos.x, pos.y + 1}) == .Fence do d += {.Down}
		sprite = sprites[fence_sprites[d] or_else .Fence_Down]
	case .End:
		sprite = get_end_sprite(world.level.animation.frame)
	case .Belt_Right, .Belt_Left, .Belt_Down, .Belt_Up:
		sprite = get_belt_sprite(world.level.animation.frame, tile)
	case .Start: sprite = sprites[.Start]
	case .Carrot: sprite = sprites[.Carrot]
	case .Carrot_Hole: sprite = sprites[.Carrot_Hole]
	case .Trap: sprite = sprites[.Trap]
	case .Trap_Activated: sprite = sprites[.Trap_Activated]
	case .Wall_Left_Right: sprite = sprites[.Wall_Left_Right]
	case .Wall_Up_Down: sprite = sprites[.Wall_Up_Down]
	case .Wall_Right_Up: sprite = sprites[.Wall_Right_Up]
	case .Wall_Right_Down: sprite = sprites[.Wall_Right_Down]
	case .Wall_Left_Up: sprite = sprites[.Wall_Left_Up]
	case .Wall_Left_Down: sprite = sprites[.Wall_Left_Down]
	case .Red_Button: sprite = sprites[.Red_Button]
	case .Red_Button_Pressed: sprite = sprites[.Red_Button_Pressed]
	case .Yellow_Button: sprite = sprites[.Yellow_Button]
	case .Yellow_Button_Pressed: sprite = sprites[.Yellow_Button_Pressed]
	case .Silver_Key: sprite = sprites[.Silver_Key]
	case .Silver_Lock: sprite = sprites[.Silver_Lock]
	case .Golden_Key: sprite = sprites[.Golden_Key]
	case .Golden_Lock: sprite = sprites[.Golden_Lock]
	case .Copper_Key: sprite = sprites[.Copper_Key]
	case .Copper_Lock: sprite = sprites[.Copper_Lock]
	}

	return sprite
}

draw_level_incrementally :: proc(t: ^swin.Texture2D, q: ^Position_Queue) {
	for changed, idx in &world.level.changes {
		x := idx%world.level.w
		y := idx/world.level.w
		tile := get_level_tile({x, y})

		if !changed && tile not_in belt_tiles && !(world.level.can_end && tile == .End) {
			continue
		}

		sprite := get_sprite_from_tile({x, y})
		swin.draw_from_texture(t, atlas, x * TILE_SIZE, y * TILE_SIZE, sprite)
		changed = false
		small_array.push_back(q, [2]int{x, y})
	}
}

draw_level :: proc(t: ^swin.Texture2D) {
	if len(t.pixels) > 0 {
		swin.texture_destroy(t)
	}

	t^ = swin.texture_make(world.level.w * TILE_SIZE, world.level.h * TILE_SIZE)
	for _, idx in world.level.tiles {
		x := idx%world.level.w
		y := idx/world.level.w

		sprite := get_sprite_from_tile({x, y})
		swin.draw_from_texture(t, atlas, x * TILE_SIZE, y * TILE_SIZE, sprite)
	}
}

region_intersection :: proc(r1, r2: swin.Rect) -> swin.Rect {
	left_x := max(r1.x, r2.x)
	right_x := min(r1.x + r1.w, r2.x + r2.w)
	top_y := max(r1.y, r2.y)
	bottom_y := min(r1.y + r1.h, r2.y + r2.h)

	if left_x < right_x && top_y < bottom_y {
		return {left_x, top_y, right_x - left_x, bottom_y - top_y}
	}
	return {}
}

render :: proc(window: ^swin.Window) {
	previous_tick: time.Tick
	tick_time: f32
	player := world.player
	menu := world.menu
	diff: [2]f32
	full_redraw, level_ended: bool
	level_texture: swin.Texture2D
	tiles_updated: Position_Queue
	canvas_cache: Region_Cache
	carrots, steps: int
	level_current, level_next: int
	timer, level_time: time.Duration
	offset: [2]f32

	canvas := swin.texture_make(TILES_W * TILE_SIZE, TILES_H * TILE_SIZE)
	background := swin.texture_make((TILES_W + 1) * TILE_SIZE, (TILES_H + 1) * TILE_SIZE)
	for y in 0..=TILES_H do for x in 0..=TILES_W {
		swin.draw_from_texture(&background, atlas, x * TILE_SIZE, y * TILE_SIZE, sprites[.Grass])
	}

	//clear_color := swin.color(expand_to_tuple(SKY_BLUE))

	for {
		start_tick := time.tick_now()

		client_w, client_h := get_2_ints(&global_state.client_size)
		/*
		tw := int(math.ceil(f32(client_w) / TILE_SIZE)) + 1
		th := int(math.ceil(f32(client_h) / TILE_SIZE)) + 1

		if tw * TILE_SIZE != background.w || th * TILE_SIZE != background.h {
			swin.texture_destroy(background)
			background = swin.texture_make(tw * TILE_SIZE, th * TILE_SIZE)
			for y in 0..=th do for x in 0..=tw {
				swin.draw_from_texture(&background, atlas, x * TILE_SIZE, y * TILE_SIZE, sprites[.Grass])
			}
		}
		*/

		if sync.atomic_load(&world.updated) {
			sync.guard(&world.lock)

			// save the world state
			menu = world.menu
			if world.level.changed {
				draw_level(&level_texture)
				world.level.changed = false
				full_redraw = true
			}
			draw_level_incrementally(&level_texture, &tiles_updated)
			diff = {f32(TILES_W - world.level.w), f32(TILES_H - world.level.h)}
			player = world.player
			carrots = world.level.carrots
			level_current = world.level.current
			level_next = world.level.next
			timer = time.since(world.level.start_tick)
			steps = world.level.steps
			level_time = world.level.end_time
			level_ended = world.level.ended
			previous_tick = global_state.previous_tick
			tick_time = f32(time.duration_milliseconds(sync.atomic_load(&global_state.tick_time)))

			sync.atomic_store(&world.updated, false)
		}

		if menu {
			TITLE_SCREEN :: Sprite{{0, 274, 128, 128},{}}
			swin.draw_from_texture(&canvas, background, 0, 0, {0, 0, canvas.w, canvas.h})
			off_x := (canvas.w - TITLE_SCREEN.w) / 2
			off_y := (canvas.h - TITLE_SCREEN.h) / 2
			swin.draw_from_texture(&canvas, atlas, off_x, off_y, TITLE_SCREEN)
		} else {
			frame_pos := f32(time.duration_milliseconds(time.tick_diff(previous_tick, time.tick_now())))
			player_pos := interpolate_tile_position(frame_pos, tick_time, player)
			draw_background: bool
			old_offset := offset
			offset = {}

			if diff.x > 0 {
				offset.x = diff.x / 2
				draw_background = true
			} else {
				off := (f32(TILES_W) / 2) - (f32(player_pos.x) + 0.5)
				if diff.x > off {
					offset.x = diff.x
				} else {
					offset.x = min(off, 0)
				}
			}

			if diff.y > 0 {
				offset.y = diff.y / 2
				draw_background = true
			} else {
				off := (f32(TILES_H) / 2) - (f32(player_pos.y) + 0.5)
				if diff.y > off {
					offset.y = diff.y
				} else {
					offset.y = min(off, 0)
				}
			}

			if old_offset != offset {
				full_redraw = true
			}

			bg_off_x := int(abs(offset.x - f32(int(offset.x))) * TILE_SIZE)
			bg_off_y := int(abs(offset.y - f32(int(offset.y))) * TILE_SIZE)
			bg_rect: swin.Rect = {bg_off_x, bg_off_y, background.w - bg_off_x, background.h - bg_off_y}
			bg_region: swin.Rect = {0, 0, bg_rect.w, bg_rect.h}

			lvl_rect: swin.Rect = {0, 0, level_texture.w, level_texture.h}
			lvl_region: swin.Rect = {int(offset.x * TILE_SIZE), int(offset.y * TILE_SIZE), lvl_rect.w, lvl_rect.h}

			if full_redraw {
				full_redraw = false
				small_array.clear(&canvas_cache)
				small_array.clear(&tiles_updated)
				if draw_background {
					swin.draw_from_texture(&canvas, background, bg_region.x, bg_region.y, bg_rect)
				}
				swin.draw_from_texture(&canvas, level_texture, lvl_region.x, lvl_region.y, lvl_rect)
			} else { // cached rendering
				for canvas_cache.len > 0 {
					cache_region := small_array.pop_back(&canvas_cache)
					region: swin.Rect
					region = region_intersection(bg_region, cache_region)
					if region.w > 0 && region.h > 0 {
						swin.draw_from_texture(&canvas, background, region.x, region.y, {region.x + bg_rect.x, region.y + bg_rect.y, region.w, region.h})
					}
					region = region_intersection(lvl_region, cache_region)
					if region.w > 0 && region.h > 0 {
						swin.draw_from_texture(&canvas, level_texture, region.x, region.y, {region.x - lvl_region.x, region.y - lvl_region.y, region.w, region.h})
					}
				}

				// draw updated tiles
				for tiles_updated.len > 0 {
					pos := small_array.pop_back(&tiles_updated)
					x, y := pos.x * TILE_SIZE, pos.y * TILE_SIZE
					swin.draw_from_texture(&canvas, level_texture, x + lvl_region.x, y + lvl_region.y, {x, y, TILE_SIZE, TILE_SIZE})
				}
			}

			// draw player
			pos := (player_pos + offset) * TILE_SIZE
			px := int(pos.x) + player.sprite.origin.x
			py := int(pos.y) + player.sprite.origin.y
			swin.draw_from_texture(&canvas, atlas, px, py, player.sprite)
			small_array.push_back(&canvas_cache, swin.Rect{px, py, player.sprite.w, player.sprite.h})

			if !level_ended { // HUD
				// left part
				{
					tbuf: [8]byte
					timer_str := fmt.bprintf(tbuf[:], "{:02i}:{:02i}", int(time.duration_minutes(timer)), int(time.duration_seconds(timer)) % 60)
					small_array.push_back(&canvas_cache, draw_text(&canvas, hud_font, timer_str, {2, 2}))
				}
				// level begin screen
				if time.duration_seconds(timer) < 2 {
					tbuf: [16]byte
					level_str := fmt.bprintf(tbuf[:], "Level {}", level_current + 1)
					w, h := measure_text(general_font, level_str)
					x := (canvas.w - w) / 2
					y := (canvas.h - h) / 2
					small_array.push_back(&canvas_cache, draw_text(&canvas, general_font, level_str, {x, y}))
				}
				// right part
				{
					x := canvas.w - 2
					y := 2

					carrot_sprite := hud_sprites[.Carrot]
					x -= carrot_sprite.w
					swin.draw_from_texture(&canvas, atlas, x, 2, carrot_sprite)
					small_array.push_back(&canvas_cache, swin.Rect{x, y, carrot_sprite.w, carrot_sprite.h})
					x -= 2

					tbuf: [8]byte
					carrots_str := strconv.itoa(tbuf[:], carrots)
					{
						w, _ := measure_text(hud_font, carrots_str)
						x -= w
					}
					small_array.push_back(&canvas_cache, draw_text(&canvas, hud_font, carrots_str, {x, y + 3}))
					y += carrot_sprite.h + 2
					x = canvas.w - 2

					if player.silver_key {
						sprite := hud_sprites[.Silver_Key]
						x -= sprite.w
						swin.draw_from_texture(&canvas, atlas, x, y, sprite)
						small_array.push_back(&canvas_cache, swin.Rect{x, y, sprite.w, sprite.h})
						x -= 2
					}
					if player.golden_key {
						sprite := hud_sprites[.Golden_Key]
						x -= sprite.w
						swin.draw_from_texture(&canvas, atlas, x, y, sprite)
						small_array.push_back(&canvas_cache, swin.Rect{x, y, sprite.w, sprite.h})
						x -= 2
					}
					if player.copper_key {
						sprite := hud_sprites[.Copper_Key]
						x -= sprite.w
						swin.draw_from_texture(&canvas, atlas, x, y, sprite)
						small_array.push_back(&canvas_cache, swin.Rect{x, y, sprite.w, sprite.h})
						x -= 2
					}
				}
			} else if !player.fading.state { // level end screen
				x, y, total_h: int
				success := hud_sprites[.Success]
				success_x := (canvas.w - success.w) / 2
				total_h += success.h + (general_font.glyph_size.h * 2)

				tbuf: [64]byte
				time_str := fmt.bprintf(tbuf[:32], "Time: {:02i}:{:02i}:{:02i}",
					int(time.duration_minutes(level_time)),
					int(time.duration_seconds(level_time)) % 60,
					int(time.duration_milliseconds(level_time)) % 60,
				)
				time_x, time_h: int
				{
					w, h := measure_text(general_font, time_str)
					time_x = (canvas.w - w) / 2
					time_h = h
				}
				total_h += time_h + general_font.glyph_size.h

				steps_str := fmt.bprintf(tbuf[32:48], "Steps: {}", steps)
				steps_x, steps_h: int
				{
					w, h := measure_text(general_font, steps_str)
					steps_x = (canvas.w - w) / 2
					steps_h = h
				}
				total_h += steps_h + (general_font.glyph_size.h * 2)

				hint_str := "Press Enter to continue" // TODO: should blink ever second
				hint_x, hint_h: int
				{
					w, h := measure_text(general_font, hint_str)
					hint_x = (canvas.w - w) / 2
					hint_h = h
				}
				total_h += hint_h

				x = (canvas.w - success.w) / 2
				y = (canvas.w - total_h) / 2
				swin.draw_from_texture(&canvas, atlas, x, y, success)
				small_array.push_back(&canvas_cache, swin.Rect{x, y, success.w, success.h})
				y += success.h + (general_font.glyph_size.h * 2)

				small_array.push_back(&canvas_cache, draw_text(&canvas, general_font, time_str, {time_x, y}))
				y += time_h + general_font.glyph_size.h

				small_array.push_back(&canvas_cache, draw_text(&canvas, general_font, steps_str, {steps_x, y}))
				y += steps_h + (general_font.glyph_size.h * 2)

				small_array.push_back(&canvas_cache, draw_text(&canvas, general_font, hint_str, {hint_x, y}))
			}
		}

		if settings.show_stats {
			small_array.push_back(&canvas_cache, draw_stats(&canvas))
		}

		sync.atomic_store(&global_state.frame_work, time.tick_since(start_tick))

		if settings.vsync {
			swin.wait_vblank()
		} else {
			limit_frame(time.tick_since(start_tick), settings.fps)
		}

		scale := 1
		for {
			scale += 1
			if BUFFER_W * scale > cast(int)client_w || BUFFER_H * scale > cast(int)client_h {
				scale -= 1
				break
			}
		}
		buf_w, buf_h := BUFFER_W * scale, BUFFER_H * scale
		off_x := (cast(int)client_w - buf_w) / 2
		off_y := (cast(int)client_h - buf_h) / 2
		swin.display_pixels(window, canvas, {off_x, off_y, buf_w, buf_h})

		sync.atomic_store(&global_state.frame_time, time.tick_since(start_tick))
	}
}

can_move :: proc(pos: [2]int, d: Direction) -> bool {
	pos := pos
	current_tile := get_level_tile(pos)

	#partial switch d {
	case .Right:
		if pos.x == world.level.w - 1 {
			return false
		}
		pos.x += 1
	case .Left:
		if pos.x == 0 {
			return false
		}
		pos.x -= 1
	case .Down:
		if pos.y == world.level.h - 1 {
			return false
		}
		pos.y += 1
	case .Up:
		if pos.y == 0 {
			return false
		}
		pos.y -= 1
	}
	tile := get_level_tile(pos)

	if tile == .Grass || tile == .Fence {
		return false
	}

	if tile == .Silver_Lock && !world.player.silver_key {
		return false
	}
	if tile == .Golden_Lock && !world.player.golden_key {
		return false
	}
	if tile == .Copper_Lock && !world.player.copper_key {
		return false
	}

	if tile == .Wall_Left_Right && d != .Up && d != .Down {
		return false
	}
	if tile == .Wall_Up_Down && d != .Left && d != .Right {
		return false
	}
	if tile == .Wall_Right_Up && d != .Right && d != .Up {
		return false
	}
	if tile == .Wall_Right_Down && d != .Right && d != .Down {
		return false
	}
	if tile == .Wall_Left_Up && d != .Left && d != .Up {
		return false
	}
	if tile == .Wall_Left_Down && d != .Left && d != .Down {
		return false
	}

	if current_tile == .Wall_Left_Right && (d == .Left || d == .Right) {
		return false
	}
	if current_tile == .Wall_Up_Down && (d == .Up || d == .Down) {
		return false
	}
	if current_tile == .Wall_Right_Up && (d == .Right || d == .Up) {
		return false
	}
	if current_tile == .Wall_Right_Down && (d == .Right || d == .Down) {
		return false
	}
	if current_tile == .Wall_Left_Up && (d == .Left || d == .Up) {
		return false
	}
	if current_tile == .Wall_Left_Down && (d == .Left || d == .Down) {
		return false
	}

	if tile == .Belt_Left && d == .Right {
		return false
	}
	if tile == .Belt_Right && d == .Left {
		return false
	}
	if tile == .Belt_Up && d == .Down {
		return false
	}
	if tile == .Belt_Down && d == .Up {
		return false
	}

	if world.player.belt {
		return true
	}

	if current_tile == .Belt_Left || current_tile == .Belt_Right || current_tile == .Belt_Down || current_tile == .Belt_Up {
		return false
	}

	return true
}

stop_idling :: proc() {
	world.player.idle.state = false
	world.player.idle.timer = 0
	world.player.idle.frame = 0
}

animation_start :: proc(a: ^Animation) {
	if !a.state {
		stop_idling()
		a.state = true
		a.timer = 0
		a.frame = 0
	}
}

start_moving :: proc(d: Direction) {
	world.player.direction = d
	animation_start(&world.player.walking)
	world.level.steps += 1
}

move_player :: #force_inline proc(d: Direction) {
	if !world.player.dying.state && !world.player.fading.state && !world.player.walking.state {
		#partial switch d {
		case .Right:
			if !can_move(world.player, .Right) do return
		case .Left:
			if !can_move(world.player, .Left) do return
		case .Down:
			if !can_move(world.player, .Down) do return
		case .Up:
			if !can_move(world.player, .Up) do return
		}
		start_moving(d)
	}
}

get_level_tile :: #force_inline proc(pos: [2]int) -> Tiles #no_bounds_check {
	if pos.y < 0 || pos.y >= world.level.h || pos.x < 0 || pos.x >= world.level.w {
		return .Grass
	}

	return world.level.tiles[(pos.y * world.level.w) + pos.x]
}

set_level_tile :: #force_inline proc(pos: [2]int, t: Tiles) {
	when ODIN_DEBUG {
		if pos.y < 0 || pos.y >= world.level.h || pos.x < 0 || pos.x >= world.level.w {
			fmt.println("BUG", pos, t)
			return
		}
	}
	idx := (pos.y * world.level.w) + pos.x
	world.level.tiles[idx] = t
	world.level.changed = true
	world.level.changes[idx] = true
}

press_red_button :: proc() {
	for tile, idx in world.level.tiles {
		x := idx%world.level.w
		y := idx/world.level.w
		switch {
		case tile == .Red_Button:
			set_level_tile({x, y}, .Red_Button_Pressed)
		case tile == .Red_Button_Pressed:
			set_level_tile({x, y}, .Red_Button)
		case tile in wall_tiles:
			new_tile := wall_switch[tile] or_else .Egg
			set_level_tile({x, y}, new_tile)
		}
	}
}

press_yellow_button :: proc() {
	for tile, idx in world.level.tiles {
		x := idx%world.level.w
		y := idx/world.level.w
		switch {
		case tile == .Yellow_Button:
			set_level_tile({x, y}, .Yellow_Button_Pressed)
		case tile == .Yellow_Button_Pressed:
			set_level_tile({x, y}, .Yellow_Button)
		case tile in belt_tiles:
			new_tile := belt_switch[tile] or_else .Egg
			set_level_tile({x, y}, new_tile)
		}
	}
}

finish_level :: proc(next: int) {
	world.level.ended = true
	world.level.end_time = time.since(world.level.start_tick)
	world.level.next = next
	animation_start(&world.player.fading)
}

move_player_to_tile :: proc(d: Direction) {
	original_pos := world.player.pos
	#partial switch d {
	case .Right: world.player.x += 1
	case .Left:  world.player.x -= 1
	case .Down:  world.player.y += 1
	case .Up:    world.player.y -= 1
	}
	original_tile := get_level_tile(original_pos)
	current_tile := get_level_tile(world.player)

	switch {
	case original_tile == .Trap:
		set_level_tile(original_pos, .Trap_Activated)
	case original_tile in belt_tiles:
		if current_tile not_in belt_tiles {
			// if moved from belt unto anything else
			world.player.belt = false
		}
	case original_tile in wall_tiles:
		new_tile := wall_switch[original_tile] or_else .Egg
		set_level_tile(original_pos, new_tile)
	}

	switch {
	case current_tile == .Carrot:
		set_level_tile(world.player, .Carrot_Hole)
		world.level.carrots -= 1
		if world.level.carrots == 0 {
			world.level.can_end = true
		}
	case current_tile == .Silver_Key:
		set_level_tile(world.player, .Ground)
		world.player.silver_key = true
	case current_tile == .Silver_Lock:
		set_level_tile(world.player, .Ground)
		world.player.silver_key = false
	case current_tile == .Golden_Key:
		set_level_tile(world.player, .Ground)
		world.player.golden_key = true
	case current_tile == .Golden_Lock:
		set_level_tile(world.player, .Ground)
		world.player.golden_key = false
	case current_tile == .Copper_Key:
		set_level_tile(world.player, .Ground)
		world.player.copper_key = true
	case current_tile == .Copper_Lock:
		set_level_tile(world.player, .Ground)
		world.player.copper_key = false
	case current_tile == .Trap_Activated:
		animation_start(&world.player.dying)
	case current_tile == .End:
		if world.level.carrots == 0 {
			finish_level(world.level.current + 1)
		}
	case current_tile in belt_tiles:
		world.player.belt = true
	case current_tile == .Red_Button:
		press_red_button()
	case current_tile == .Yellow_Button:
		press_yellow_button()
	}
}

load_level :: proc(index: int) {
	if len(world.level.tiles) != 0 {
		delete(world.level.tiles)
		delete(world.level.changes)
	}

	world.level = {
		animation = {
			frame_len = 2,
		},
	}

	if index >= len(levels){
		// TODO: end sequence
		world.menu = true
		return
	} else if index < 0 {
		world.menu = true
		return
	}

	world.level.current = index
	world.level.next = index
	world.level.w = len(levels[index][0])
	world.level.h = len(levels[index])
	world.level.tiles = make([]Tiles, world.level.w * world.level.h)
	world.level.changes = make([]bool, world.level.w * world.level.h)
	world.level.changed = true

	// reset player
	world.player = {
		walking = {
			frame_len = 2 when !ODIN_DEBUG else 1,
		},
		idle = {
			frame_len = 2,
		},
		dying = {
			frame_len = 3 when !ODIN_DEBUG else 1,
		},
		fading = {
			frame_len = 2 when !ODIN_DEBUG else 1,
		}
	}

	for row, y in levels[index] {
		x: int
		for char in row {
			tile := char_to_tile[char] or_else .Ground
			set_level_tile({x, y}, tile)
			#partial switch tile {
			case .Start:
				world.player.pos = {x, y}
			case .Carrot:
				world.level.carrots += 1
			}
			x += 1
		}
	}

	animation_start(&world.player.fading)
	world.level.start_tick = time.now()
	world.level.end_time = 0
}

key_handler_menu :: proc(key: swin.Key_Code, state: bit_set[Key_State]) {
	if .Pressed in state {
		#partial switch key {
		case .Enter:
			// TODO: load levels properly
			load_level(len(levels)-1)
			world.menu = false
		case .F1:
			load_level(0)
			world.menu = false
		}
	}
	if .Held in state {
		// TODO: volume slider?
	}
	if .Repeated in state {
		// TODO: text input?
	}
}

key_handler_game :: proc(key: swin.Key_Code, state: bit_set[Key_State], shift: bool) {
	if world.level.ended {
		#partial switch key {
		case .Escape:
			if .Pressed in state {
				world.menu = true
			}
		case .Enter:
			if .Pressed in state {
				load_level(world.level.next)
			}
		case .R:
			load_level(world.level.current)
		}
	} else {
		#partial switch key {
		case .Right: move_player(.Right)
		case .Left:  move_player(.Left)
		case .Down:  move_player(.Down)
		case .Up:    move_player(.Up)
		case .Escape:
			if .Pressed in state {
				world.menu = true
			}
		case .R:
			if .Pressed in state {
				fmt.println(state)
				animation_start(&world.player.dying)
			}
		case .F:
			if !world.player.fading.state {
				load_level(world.level.current + (1 if !shift else -1))
				//finish_level(world.level.current + (1 if !shift else -1))
			}
		}
	}
}

get_end_sprite :: proc(frame: uint) -> Sprite {
	sprite := sprites[.End]
	if world.level.can_end {
		sprite = end_animation[frame]
	}
	return sprite
}

get_belt_sprite :: proc(frame: uint, t: Tiles) -> Sprite {
	sprite := belt_animation[frame]
	#partial switch t {
	case .Belt_Right:
		sprite.x += 64
	case .Belt_Up:
		sprite.x += 128
	case .Belt_Down:
		sprite.y += 16
	}
	return sprite
}

get_walking_sprite :: proc(frame: uint) -> Sprite {
	sprite := walking_animation[frame]
	#partial switch world.player.direction {
	case .Left:
		sprite.y += 25
	case .Up:
		sprite.y += 50
	case .Right:
		sprite.y += 75
	}
	return sprite
}

update_world :: proc(t: ^thread.Thread) {
	for {
		start_tick := time.tick_now()

		{
			sync.guard(&world.lock)

			world.player.position.prev = world.player.position.pos
			{ // keyboard inputs
				// NOTE: this input processor squashes multiple key presses in-between frames into a single keypress
				sync.guard(&global_state.frame_inputs.lock)
				for state, key in &global_state.frame_inputs.keys {
					if state == {} do continue

					if world.menu {
						key_handler_menu(key, state)
					} else {
						shift := global_state.frame_inputs.keys[.LShift]
						key_handler_game(key, state, .Pressed in shift || .Held in shift)
					}

					if .Repeated in state do state -= {.Repeated}
					if .Released in state do state = {}
					if .Pressed in state do state = {.Held}
				}
			}

			if world.menu {
			} else {
				// animations
				switch {
				case world.player.fading.state:
					world.player.fading.frame = world.player.fading.timer / world.player.fading.frame_len

					if world.player.fading.frame >= len(fading_animation) {
						world.player.fading.state = false
						world.player.fading.timer = 0
						world.player.fading.frame = 0
					} else {
						if world.level.current == world.level.next {
							// reverse frames
							world.player.fading.frame = len(fading_animation) - 1 - world.player.fading.frame
						}
						world.player.sprite = fading_animation[world.player.fading.frame]
					}

					world.player.fading.timer += 1
				case world.player.dying.state:
					world.player.dying.frame = world.player.dying.timer / world.player.dying.frame_len

					if world.player.dying.frame >= len(dying_animation) {
						if world.player.dying.timer - (len(dying_animation) * world.player.dying.frame_len) >= LAYING_DEAD_TIME {
							world.player.dying.state = false
							world.player.dying.timer = 0
							world.player.dying.frame = 0
							load_level(world.level.current)
						}
					} else {
						world.player.sprite = dying_animation[world.player.dying.frame]
					}

					world.player.dying.timer += 1
				case world.player.walking.state:
					world.player.walking.frame = world.player.walking.timer / world.player.walking.frame_len

					if world.player.walking.frame + 1 >= WALKING_ANIM_LEN {
						world.player.walking.state = false
						world.player.walking.timer = 0
						world.player.walking.frame = 0
						move_player_to_tile(world.player.direction)
					} else {
						if world.player.belt {
							world.player.sprite = get_walking_sprite(0)
						} else {
							world.player.sprite = get_walking_sprite(world.player.walking.frame + 1)
						}
					}

					world.player.walking.timer += 1
				case world.player.idle.state:
					world.player.idle.frame = world.player.idle.timer / world.player.idle.frame_len

					world.player.idle.frame %= len(idling_animation)
					world.player.sprite = idling_animation[world.player.idle.frame]

					world.player.idle.timer += 1
				case !world.level.ended:
					world.player.sprite = get_walking_sprite(0)

					if world.player.idle.timer > IDLING_TIME {
						animation_start(&world.player.idle)
					}

					world.player.idle.timer += 1
				}

				world.level.animation.frame = world.level.animation.timer / world.level.animation.frame_len
				world.level.animation.frame %= len(end_animation) // all persistent animations have the same amount of frames
				world.level.animation.timer += 1

				// belts
				if world.player.belt {
					tile := get_level_tile(world.player)
					#partial switch tile {
					case .Belt_Left:  move_player(.Left)
					case .Belt_Right: move_player(.Right)
					case .Belt_Down:  move_player(.Down)
					case .Belt_Up:    move_player(.Up)
					}
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
		if !ev.focused {
			sync.guard(&global_state.frame_inputs.lock)
			for state in &global_state.frame_inputs.keys {
				// release all pressed keys
				if .Pressed in state || .Held in state || .Repeated in state {
					state = {.Released}
				}
			}
		}
	case swin.Draw_Event:
	case swin.Resize_Event:
		save_2_ints(&global_state.client_size, i32(window.client.w), i32(window.client.h))
	case swin.Move_Event:
	case swin.Character_Event:
	case swin.Keyboard_Event:
		switch ev.state {
		case .Repeated, .Released:
		case .Pressed:
			#partial switch ev.key {
			case .Q: window.must_close = true
			case .V: settings.vsync = !settings.vsync
			case .I: settings.show_stats = !settings.show_stats
			case .N: save_data("settings.save", &settings)
			case .B: settings = default_settings
			case .Num0: settings.fps = 0
			case .Num1: settings.fps = 10
			case .Num2: settings.fps = 200
			case .Num3: settings.fps = 30
			case .Num4: settings.fps = 144
			case .Num6: settings.fps = 60
			case .Num9: settings.fps = 1000
			}
		}

		{
			sync.guard(&global_state.frame_inputs.lock)
			state := global_state.frame_inputs.keys[ev.key]
			switch ev.state {
			case .Released: state += {.Released}
			case .Repeated: state += {.Repeated}
			case .Pressed: state += {.Pressed}
			}
			global_state.frame_inputs.keys[ev.key] = state
		}
	case swin.Mouse_Button_Event:
	case swin.Mouse_Move_Event:
		save_2_ints(&global_state.mouse_pos, i32(ev.x), i32(ev.y))
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
	general_font.texture = load_texture(#load("res/font.png"), image.RGBA_Pixel)
	general_font.glyph_size = {5, 7}
	general_font.table = make(map[rune][2]int)
	for ch in ` 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ?'".,:;~!@#$^&_|\/%*+-=<>()[]{}` {
		glyph_idx := len(general_font.table)
		gx := (glyph_idx % (general_font.w / general_font.glyph_size.w)) * general_font.glyph_size.w
		gy := (glyph_idx / (general_font.w / general_font.glyph_size.w)) * general_font.glyph_size.h
		general_font.table[ch] = {gx, gy}
	}

	atlas = load_texture(#load("res/atlas.png"), image.RGBA_Pixel)

	hud_font.texture = atlas
	hud_font.glyph_size = {5, 8}
	hud_font.table = make(map[rune][2]int)
	for ch in `0123456789:?` {
		OFFSET: [2]int : {128, 106}
		glyph_idx := len(hud_font.table)
		gx := OFFSET.x + (glyph_idx * hud_font.glyph_size.w)
		gy := OFFSET.y
		hud_font.table[ch] = {gx, gy}
	}

	MAX_X :: 12
	for s in Sprites {
		idx := int(s)
		x := idx%MAX_X
		y := idx/MAX_X
		sprites[s] = {{x*TILE_SIZE, y*TILE_SIZE, TILE_SIZE, TILE_SIZE},{}}
	}
}

free_resources :: proc() {
	swin.texture_destroy(&atlas)
	swin.texture_destroy(&general_font.texture)
	delete(general_font.table)
	// NOTE: hud_font uses the same texture as atlas so no need to free it
	delete(hud_font.table)
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

	//window.clear_color = SKY_BLUE.rgb
	window.event_handler = event_handler
	swin.set_resizable(&window, true)
	swin.set_min_size(&window, BUFFER_W, BUFFER_H)

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
