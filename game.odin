package main

import "core:time"
import "core:thread"
import "core:sync"
import "core:runtime"
import "core:math"
import "core:slice"
import "core:container/small_array"
import "core:strconv"
import "core:image"
import _ "core:image/png"
import "core:bytes"
import "core:os"
import "core:os/os2"
import "core:path/filepath"
import "core:mem"
import "core:fmt"
import "core:encoding/json"

import swin "simple_window"

MOUSE_SUPPORT :: true
SKY_BLUE: image.RGBA_Pixel : {139, 216, 245, 255}
GAME_TITLE :: "Bobby Carrot Remastered"

// since settings will be saved to the file, they probably should be packed
Settings :: struct #packed {
	fps: uint,
	vsync: bool,
	show_stats: bool,

	sound: bool,
	last_unlocked_level: int,

	scoreboard_time: [len(levels)]time.Duration,
	scoreboard_steps: [len(levels)]int,
}
default_settings: Settings : {
	fps = 60,
	vsync = true,
	show_stats = true when ODIN_DEBUG else false,
	sound = true,
	last_unlocked_level = 0,
}
settings: Settings = default_settings

TILES_W :: 16
TILES_H :: 12
TILE_SIZE :: 16
TPS :: 30
TPS_SECOND :: TPS
IDLING_TIME :: TPS_SECOND * 5 // how much time before starts idling
LAYING_DEAD_TIME :: TPS_SECOND / 3 when !ODIN_DEBUG else 0 // how much time after dying
INTRO_LENGTH :: TPS_SECOND * 3
FADE_LENGTH :: TPS_SECOND
BUFFER_W :: TILES_W * TILE_SIZE
BUFFER_H :: TILES_H * TILE_SIZE
DEFAULT_SCALE :: 3
WINDOW_W :: BUFFER_W * DEFAULT_SCALE
WINDOW_H :: BUFFER_H * DEFAULT_SCALE

Font :: struct {
	using texture: swin.Texture2D,
	table: map[rune][2]int,
	glyph_size: [2]int,
}
general_font: Font
hud_font: Font
atlas, splashes, logo: swin.Texture2D

Direction :: enum {
	None,
	Right,
	Left,
	Down,
	Up,
}

Sprite :: swin.Rect

Sprite_Offset :: struct {
	using sprite: Sprite,
	offset: [2]int,
}

Menu_Option :: struct {
	using rect: swin.Rect,
	function: proc(),
	name_buf: [32]byte,
	name_len: int,
	arrows: Maybe([2]bool),
}

// redraw regions
Region_Cache :: small_array.Small_Array(128, swin.Rect)
// max tiles changed in an update
Tile_Queue :: small_array.Small_Array(256, Sprite_Offset)
Menu_Options :: small_array.Small_Array(16, Menu_Option)

Animation :: struct {
	state: bool,
	timer: uint,
	frame: uint,
}

Player :: struct {
	using pos: [2]int,
	sprite: Sprite_Offset,
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
	current, next: int,

	animation: Animation,
	carrots: int,
	can_end, ended: bool,

	time: time.Duration,
	steps: int,

	// for rendering
	changed: bool,
	changes: []bool,
}

Scene :: enum {
	None,
	Intro,
	Main_Menu,
	Pause_Menu,
	Game,
	End,
}

World :: struct {
	updated: bool,
	lock: sync.Mutex,

	scene: Scene,
	next_scene: Scene,

	intro: Animation,
	fade: Animation,

	menu_options: Menu_Options,
	selected_option: int,
	selected_level: int,

	level: Level,
	player: Player,
}
world: World

Key_State :: enum {
	Pressed,
	Repeated,
	Held,
	Released,
}

Mouse_State :: enum {
	Clicked,
	Double_Clicked,
	Held,
	Released,
}

State :: struct {
	// TODO: i128 with atomic_load/store
	client_size: i64,
	mouse_pos: i32,

	// _work shows how much time was spent on actual work in that frame before sleep
	// _time shows total time of the frame, sleep included
	frame_work, frame_time: time.Duration,
	tick_work, tick_time: time.Duration,
	previous_tick: time.Tick,

	keyboard: struct {
		lock: sync.Mutex,
		keys: [swin.Key_Code]bit_set[Key_State],
	},

	mouse: struct {
		lock: sync.Mutex,
		buttons: [swin.Mouse_Button]bit_set[Mouse_State],
	},

	mouse_move: struct {
		lock: sync.Mutex,
		moved: bool,
		pos: [2]i16,
	},
}
global_state: State

window: swin.Window

RIGHT_ARROW :: Sprite{{183, 115}, {5, 9}}
INTRO_SPLASH :: Sprite{{0, 0}, {128, 128}}
END_SPLASH :: Sprite{{0, 128}, {128, 128}}

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
	.Carrot     = {{128, 80}, {14, 13}},
	.Egg        = {{142, 80}, {9,  13}},
	.Eyes       = {{151, 80}, {15, 13}},
	.Silver_Key = {{166, 80}, {8,  13}},
	.Golden_Key = {{174, 80}, {8,  13}},
	.Copper_Key = {{182, 80}, {8,  13}},
	.Success    = {{128, 93}, {54, 13}},
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

walking_animation := [?]Sprite_Offset {
	{{{54,  121}, {18, 25}}, {-1, -9}},
	{{{72,  121}, {18, 25}}, {-1, -9}},
	{{{90,  121}, {18, 25}}, {-1, -9}},
	{{{108, 121}, {18, 25}}, {-1, -9}},
	{{{126, 121}, {18, 25}}, {-1, -9}},
	{{{0,   121}, {18, 25}}, {-1, -9}},
	{{{18,  121}, {18, 25}}, {-1, -9}},
	{{{36,  121}, {18, 25}}, {-1, -9}},
}
WALKING_ANIM_FRAME_LEN :: 2 when !ODIN_DEBUG else 1 // speed walking during debug
WALKING_ANIM_LEN :: len(walking_animation) when !ODIN_DEBUG else 6

idle_animation := [?]Sprite_Offset {
	{{{0,  96}, {18, 25}}, {-1, -9}},
	{{{18, 96}, {18, 25}}, {-1, -9}},
	{{{36, 96}, {18, 25}}, {-1, -9}},
}
IDLE_ANIM_FRAME_LEN :: 2

dying_animation := [?]Sprite_Offset {
	{{{0,   247}, {22, 27}}, {-3, -11}},
	{{{22,  247}, {22, 27}}, {-3, -11}},
	{{{44,  247}, {22, 27}}, {-3, -11}},
	{{{66,  247}, {22, 27}}, {-3, -11}},
	{{{88,  247}, {22, 27}}, {-3, -11}},
	{{{110, 247}, {22, 27}}, {-3, -11}},
	{{{132, 247}, {22, 27}}, {-3, -11}},
	{{{154, 247}, {22, 27}}, {-3, -11}},
}
DYING_ANIM_FRAME_LEN :: 3 when !ODIN_DEBUG else 1

fading_animation := [?]Sprite_Offset {
	{{{0,   221}, {18, 25}}, {-1, -9}},
	{{{18,  221}, {18, 25}}, {-1, -9}},
	{{{36,  221}, {18, 25}}, {-1, -9}},
	{{{54,  221}, {18, 25}}, {-1, -9}},
	{{{72,  221}, {18, 25}}, {-1, -9}},
	{{{90,  221}, {18, 25}}, {-1, -9}},
	{{{108, 221}, {18, 25}}, {-1, -9}},
	{{{126, 221}, {18, 25}}, {-1, -9}},
	{{{144, 221}, {18, 25}}, {-1, -9}},
}
FADING_ANIM_FRAME_LEN :: 2 when !ODIN_DEBUG else 1

end_animation := [?]Sprite {
	{{64,  80}, {16, 16}},
	{{80,  80}, {16, 16}},
	{{96,  80}, {16, 16}},
	{{112, 80}, {16, 16}},
}
belt_animation := [?]Sprite {
	{{0,  64}, {16, 16}},
	{{16, 64}, {16, 16}},
	{{32, 64}, {16, 16}},
	{{48, 64}, {16, 16}},
}
LEVEL_ANIM_FRAME_LEN :: 2

save_to_i64 :: #force_inline proc(p: ^i64, a: [2]i32) {
	sync.atomic_store(p, transmute(i64)a)
}

get_from_i64 :: #force_inline proc(p: ^i64) -> [2]i32 {
	return transmute([2]i32)sync.atomic_load(p)
}

save_to_i32 :: #force_inline proc(p: ^i32, a: [2]i16) {
	sync.atomic_store(p, transmute(i32)a)
}

get_from_i32 :: #force_inline proc(p: ^i32) -> [2]i16 {
	return transmute([2]i16)sync.atomic_load(p)
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

measure_or_draw_text :: proc(
	canvas: ^swin.Texture2D,
	font: Font,
	text: string,
	pos: [2]int,
	color: image.RGB_Pixel,
	shadow_color: image.RGB_Pixel,
	no_draw := false,
) -> (region: swin.Rect) {
	pos := pos
	region.x = pos.x
	region.y = pos.y

	for ch in text {
		if ch == '\n' {
			pos.x = region.x
			pos.y += font.glyph_size[1] + 1
			continue
		}

		glyph_pos := font.table[ch] or_else font.table['?']
		if !no_draw {
			swin.draw_from_texture(canvas, font.texture, pos + 1, {glyph_pos, font.glyph_size}, .None, shadow_color)
			swin.draw_from_texture(canvas, font.texture, pos, {glyph_pos, font.glyph_size}, .None, color)
		}

		pos.x += font.glyph_size[0] + 1
		region.size[0] = max(region.size[0], pos.x - region.x)
	}
	region.size[1] = pos.y - region.y + font.glyph_size[1] + 1

	return
}

draw_text :: proc(
	canvas: ^swin.Texture2D,
	font: Font,
	text: string,
	pos: [2]int,
	color: image.RGB_Pixel = {255, 255, 255},
	shadow_color: image.RGB_Pixel = {0, 0, 0},
) -> (region: swin.Rect) {
	return measure_or_draw_text(canvas, font, text, pos, color, shadow_color)
}

measure_text :: proc(font: Font, text: string) -> [2]int {
	region := measure_or_draw_text(nil, font, text, {}, {}, {}, true)
	return region.size
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

	pos: [2]int = {canvas.size[0] - 2, canvas.size[1] - 2}
	pos -= measure_text(general_font, text)
	return draw_text(canvas, general_font, text, pos)
}

draw_fade :: proc(t: ^swin.Texture2D, fade: Animation, frame_delta: f32) {
	SECTION_LENGTH :: FADE_LENGTH / 2

	section := fade.timer / SECTION_LENGTH
	time_in_section := fade.timer % SECTION_LENGTH

	delta := (f32(time_in_section) + frame_delta) / SECTION_LENGTH

	alpha: u8
	switch section {
	case 0: // fade-out 0-255
		alpha = u8(delta * 255)
	case 1: // fade-in 255-0
		alpha = 255 - u8(delta * 255)
	case:
		alpha = 0
	}

	swin.draw_rect(t, {{}, t.size}, {0, 0, 0, alpha})
}

draw_intro :: proc(t: ^swin.Texture2D, intro: Animation, frame_delta: f32) {
	slice.fill(t.pixels, swin.Color{})
	SECTION_LENGTH :: INTRO_LENGTH / 3

	section := intro.timer / SECTION_LENGTH
	time_in_section := intro.timer % SECTION_LENGTH

	delta := (f32(time_in_section) + frame_delta) / SECTION_LENGTH

	alpha: u8
	switch section {
	case 0: // fade-in 255-0
		alpha = 255 - u8(delta * 255)
	case:
		alpha = 0
	}

	off := (t.size - INTRO_SPLASH.size) / 2
	swin.draw_from_texture(t, splashes, off, INTRO_SPLASH)
	swin.draw_rect(t, {off, INTRO_SPLASH.size}, {0, 0, 0, alpha})
}

draw_end :: proc(t: ^swin.Texture2D) {
	slice.fill(t.pixels, swin.Color{})

	off := (t.size - END_SPLASH.size) / 2
	swin.draw_from_texture(t, splashes, off, END_SPLASH)
}

interpolate_tile_position :: #force_inline proc(p: Player, frame_delta: f32) -> [2]f32 {
	if p.walking.state {
		ANIM_TIME :: f32(WALKING_ANIM_FRAME_LEN * WALKING_ANIM_LEN)
		delta := (f32(p.walking.timer) + frame_delta) / ANIM_TIME
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

/*
interpolate_smooth_position :: #force_inline proc(p: Player, frame_delta: f32) -> [2]f32 {
	diff := p.pos - p.prev
	x_delta := frame_delta * f32(diff.x)
	y_delta := frame_delta * f32(diff.y)
	x := f32(p.prev.x) + x_delta
	y := f32(p.prev.y) + y_delta
	return {x, y}
}
*/

/*
TODO:
add credits
add egg campaign
add scoreboard
add manual?
*/

get_sprite_from_tile :: proc(pos: [2]int) -> Sprite {
	tile := get_level_tile(pos)
	sprite: Sprite = sprites[.Ground]

	switch tile {
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
	case .Egg_Spot: sprite = sprites[.Egg_Spot]
	case .Egg: sprite = sprites[.Egg]
	case .Ground: sprite = sprites[.Ground]
	}

	return sprite
}

collect_level_updates :: proc(q: ^Tile_Queue) {
	for changed, idx in &world.level.changes {
		pos: [2]int = {idx%world.level.w, idx/world.level.w}
		tile := get_level_tile(pos)

		if !changed && tile not_in belt_tiles && !(world.level.can_end && tile == .End) {
			continue
		}

		changed = false
		sprite := get_sprite_from_tile(pos)
		small_array.push_back(q, Sprite_Offset{sprite, pos})
	}
}

draw_level :: proc(t: ^swin.Texture2D) {
	if len(t.pixels) > 0 {
		swin.texture_destroy(t)
	}

	t^ = swin.texture_make(world.level.w * TILE_SIZE, world.level.h * TILE_SIZE)
	for _, idx in world.level.tiles {
		pos: [2]int = {idx%world.level.w, idx/world.level.w}
		sprite := get_sprite_from_tile(pos)
		swin.draw_from_texture(t, atlas, pos * TILE_SIZE, sprite)
	}
}

is_inside_rect :: #force_inline proc(p: [2]int, r: swin.Rect) -> bool {
	return p.x >= r.x && p.x < r.x + r.size[0] && p.y >= r.y && p.y < r.y + r.size[1]
}

rect_intersection :: proc(r1, r2: swin.Rect) -> swin.Rect {
	pos: [2]int = {max(r1.x, r2.x), max(r1.y, r2.y)}
	right_x := min(r1.x + r1.size[0], r2.x + r2.size[0])
	bottom_y := min(r1.y + r1.size[1], r2.y + r2.size[1])

	if pos.x < right_x && pos.y < bottom_y {
		return {pos, {right_x - pos.x, bottom_y - pos.y}}
	}
	return {}
}

draw_menu :: proc(t: ^swin.Texture2D, q: ^Region_Cache, options: []Menu_Option, selected: int) {
	DISABLED :: image.RGB_Pixel{75, 75, 75}
	NORMAL :: image.RGB_Pixel{145, 145, 145}
	SELECTED :: image.RGB_Pixel{255, 255, 255}

	for option, idx in options {
		region := option.rect
		name_buf := option.name_buf
		name := string(name_buf[:option.name_len])

		color := NORMAL
		if idx == selected {
			color = SELECTED
		}

		x := option.x
		if option.arrows != nil {
			color := color
			if !option.arrows.?[0] {
				color = DISABLED
			}
			swin.draw_from_texture(t, atlas, {x, option.y - 1}, RIGHT_ARROW, .Horizontal, color)
			x += RIGHT_ARROW.size[0] + 2
			region.size[0] += (RIGHT_ARROW.size[0] + 2) * 2
			region.y -= 1
			region.size[1] += 2
		}

		draw_text(t, general_font, name, {x, option.y}, color)

		if option.arrows != nil {
			color := color
			if !option.arrows.?[1] {
				color = DISABLED
			}
			x += option.size[0] + 2
			swin.draw_from_texture(t, atlas, {x, option.y - 1}, RIGHT_ARROW, .None, color)
		}

		small_array.push_back(q, region)
	}
}

render :: proc(window: ^swin.Window) {
	scene: Scene
	intro, fade: Animation
	menu_options: Menu_Options
	selected_option: int
	player: Player

	carrots, steps: int
	level_ended: bool
	level_current: int
	level_time: time.Duration

	previous_tick: time.Tick
	tick_time: f32
	diff, offset: [2]f32

	level_texture: swin.Texture2D
	tiles_updated: Tile_Queue
	canvas_cache: Region_Cache

	background := swin.texture_make(BUFFER_W + TILE_SIZE, BUFFER_H + TILE_SIZE)
	for y in 0..=TILES_H do for x in 0..=TILES_W {
		pos: [2]int = {x, y}
		swin.draw_from_texture(&background, atlas, pos * TILE_SIZE, sprites[.Grass])
	}
	canvas := swin.texture_make(BUFFER_W, BUFFER_H)
	menu_texture := swin.texture_make(BUFFER_W, BUFFER_H)

	for {
		start_tick := time.tick_now()

		world_redraw, menu_redraw: bool
		if sync.atomic_load(&world.updated) {
			sync.guard(&world.lock)
			defer sync.atomic_store(&world.updated, false)

			// save the world state
			if world.level.changed {
				world.level.changed = false
				small_array.clear(&tiles_updated)
				draw_level(&level_texture)
				world_redraw = true
			}
			collect_level_updates(&tiles_updated)
			diff = {f32(TILES_W - world.level.w), f32(TILES_H - world.level.h)}
			player = world.player
			intro = world.intro
			fade = world.fade

			if scene != world.scene {
				if world.scene == .Game {
					world_redraw = true
				} else if world.scene == .Main_Menu || world.scene == .Pause_Menu {
					menu_redraw = true
				}
			}
			scene = world.scene

			menu_options = world.menu_options
			selected_option = world.selected_option

			carrots = world.level.carrots
			steps = world.level.steps
			level_current = world.level.current
			level_time = world.level.time
			level_ended = world.level.ended

			previous_tick = global_state.previous_tick
			tick_time = f32(time.duration_milliseconds(sync.atomic_load(&global_state.tick_time)))
		}

		frame_delta := f32(time.duration_milliseconds(time.tick_diff(previous_tick, time.tick_now()))) / tick_time

		if (scene == .Main_Menu || scene == .Pause_Menu) && !menu_redraw {
			for cache_region in small_array.pop_back_safe(&canvas_cache) {
				swin.draw_from_texture(&canvas, menu_texture, {cache_region.x, cache_region.y}, cache_region)
			}

			draw_menu(&canvas, &canvas_cache, small_array.slice(&menu_options), selected_option)
		}

		// If switching to pause menu - redraw the world for an extra frame.
		// NOTE: This will cause a jitter if the player is moving too fast, but it's not that bad.
		if scene == .Game || (scene == .Pause_Menu && menu_redraw) {
			player_pos := interpolate_tile_position(player, frame_delta)
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
				world_redraw = true
			}

			bg_offset: [2]int
			bg_offset.x = int(abs(offset.x - f32(int(offset.x))) * TILE_SIZE)
			bg_offset.y = int(abs(offset.y - f32(int(offset.y))) * TILE_SIZE)
			bg_rect: swin.Rect = {bg_offset, {background.size[0] - bg_offset.x, background.size[1] - bg_offset.y}}
			bg_region: swin.Rect = {{}, bg_rect.size}

			lvl_rect: swin.Rect = {{}, level_texture.size}
			lvl_region: swin.Rect = {{int(offset.x * TILE_SIZE), int(offset.y * TILE_SIZE)}, lvl_rect.size}

			{ // draw updated tiles to texture
				for tile in small_array.slice(&tiles_updated) {
					swin.draw_from_texture(&level_texture, atlas, tile.offset * TILE_SIZE, tile)
				}
			}

			if world_redraw {
				small_array.clear(&canvas_cache)
				small_array.clear(&tiles_updated)
				if draw_background {
					swin.draw_from_texture(&canvas, background, bg_region.pos, bg_rect)
				}
				swin.draw_from_texture(&canvas, level_texture, lvl_region.pos, lvl_rect)
			} else { // cached rendering
				for canvas_cache.len > 0 {
					cache_region := small_array.pop_back(&canvas_cache)
					region: swin.Rect
					region = rect_intersection(bg_region, cache_region)
					if region.size[0] > 0 && region.size[1] > 0 {
						swin.draw_from_texture(&canvas, background, region.pos, {region.pos + bg_rect.pos, region.size})
					}
					region = rect_intersection(lvl_region, cache_region)
					if region.size[0] > 0 && region.size[1] > 0 {
						swin.draw_from_texture(&canvas, level_texture, region.pos, {region.pos - lvl_region.pos, region.size})
					}
				}

				// draw updated tiles to canvas
				for tiles_updated.len > 0 {
					tile := small_array.pop_back(&tiles_updated)
					pos := tile.offset * TILE_SIZE
					swin.draw_from_texture(&canvas, level_texture, pos + lvl_region.pos, {pos, {TILE_SIZE, TILE_SIZE}})
				}
			}

			if !level_ended || (level_ended && player.fading.state) {
				// draw player
				pos := (player_pos + offset) * TILE_SIZE
				px := int(pos.x) + player.sprite.offset.x
				py := int(pos.y) + player.sprite.offset.y
				swin.draw_from_texture(&canvas, atlas, {px, py}, player.sprite)
				small_array.push_back(&canvas_cache, swin.Rect{{px, py}, player.sprite.size})
			}

			// HUD
			if !level_ended {
				// left part
				{
					tbuf: [8]byte
					time_str := fmt.bprintf(tbuf[:], "{:02i}:{:02i}", int(time.duration_minutes(level_time)), int(time.duration_seconds(level_time)) % 60)
					small_array.push_back(&canvas_cache, draw_text(&canvas, hud_font, time_str, {2, 2}))
				}
				// level begin screen
				if time.duration_seconds(level_time) < 2 {
					tbuf: [16]byte
					level_str := fmt.bprintf(tbuf[:], "Level {}", level_current + 1)
					size := measure_text(general_font, level_str)
					pos := (canvas.size - size) / 2
					small_array.push_back(&canvas_cache, draw_text(&canvas, general_font, level_str, pos))
				}
				// right part
				{
					pos: [2]int = {canvas.size[0] - 2, 2}

					carrot_sprite := hud_sprites[.Carrot]
					pos.x -= carrot_sprite.size[0]
					swin.draw_from_texture(&canvas, atlas, pos, carrot_sprite)
					small_array.push_back(&canvas_cache, swin.Rect{pos, carrot_sprite.size})
					pos.x -= 2

					tbuf: [8]byte
					carrots_str := strconv.itoa(tbuf[:], carrots)
					{
						size := measure_text(hud_font, carrots_str)
						pos.x -= size[0]
					}
					small_array.push_back(&canvas_cache, draw_text(&canvas, hud_font, carrots_str, {pos.x, pos.y + 3}))
					pos.y += carrot_sprite.size[1] + 2
					pos.x = canvas.size[0] - 2

					if player.silver_key {
						sprite := hud_sprites[.Silver_Key]
						pos.x -= sprite.size[0]
						swin.draw_from_texture(&canvas, atlas, pos, sprite)
						small_array.push_back(&canvas_cache, swin.Rect{pos, sprite.size})
						pos.x -= 2
					}
					if player.golden_key {
						sprite := hud_sprites[.Golden_Key]
						pos.x -= sprite.size[0]
						swin.draw_from_texture(&canvas, atlas, pos, sprite)
						small_array.push_back(&canvas_cache, swin.Rect{pos, sprite.size})
						pos.x -= 2
					}
					if player.copper_key {
						sprite := hud_sprites[.Copper_Key]
						pos.x -= sprite.size[0]
						swin.draw_from_texture(&canvas, atlas, pos, sprite)
						small_array.push_back(&canvas_cache, swin.Rect{pos, sprite.size})
						pos.x -= 2
					}
				}
			}

			// level end screen
			if level_ended && !player.fading.state {
				total_h: int
				success := hud_sprites[.Success]
				success_x := (canvas.size[0] - success.size[0]) / 2
				total_h += success.size[1] + (general_font.glyph_size[1] * 2)

				tbuf: [64]byte
				time_str := fmt.bprintf(tbuf[:32], "Time: {:02i}:{:02i}:{:02i}",
					int(time.duration_minutes(level_time)),
					int(time.duration_seconds(level_time)) % 60,
					int(time.duration_milliseconds(level_time)) % 60,
				)
				time_x, time_h: int
				{
					size := measure_text(general_font, time_str)
					time_x = (canvas.size[0] - size[0]) / 2
					time_h = size[1]
				}
				total_h += time_h + general_font.glyph_size[1]

				steps_str := fmt.bprintf(tbuf[32:48], "Steps: {}", steps)
				steps_x, steps_h: int
				{
					size := measure_text(general_font, steps_str)
					steps_x = (canvas.size[0] - size[0]) / 2
					steps_h = size[1]
				}
				total_h += steps_h + (general_font.glyph_size[1] * 2)

				hint_str := "Press Enter to continue"
				hint_x, hint_h: int
				{
					size := measure_text(general_font, hint_str)
					hint_x = (canvas.size[0] - size[0]) / 2
					hint_h = size[1]
				}
				total_h += hint_h

				pos: [2]int
				pos.x = (canvas.size[0] - success.size[0]) / 2
				pos.y = (canvas.size[1] - total_h) / 2
				swin.draw_from_texture(&canvas, atlas, pos, success)
				small_array.push_back(&canvas_cache, swin.Rect{pos, success.size})
				pos.y += success.size[1] + (general_font.glyph_size[1] * 2)

				small_array.push_back(&canvas_cache, draw_text(&canvas, general_font, time_str, {time_x, pos.y}))
				pos.y += time_h + general_font.glyph_size[1]

				small_array.push_back(&canvas_cache, draw_text(&canvas, general_font, steps_str, {steps_x, pos.y}))
				pos.y += steps_h + (general_font.glyph_size[1] * 2)

				small_array.push_back(&canvas_cache, draw_text(&canvas, general_font, hint_str, {hint_x, pos.y}))
			}
		}

		if menu_redraw {
			small_array.clear(&canvas_cache)

			swin.draw_from_texture(&menu_texture, canvas if scene == .Pause_Menu else background, {}, {{}, menu_texture.size})
			swin.draw_rect(&menu_texture, {{}, menu_texture.size}, {0, 0, 0, 0xaa})

			swin.draw_from_texture(&canvas, menu_texture, {}, {{}, menu_texture.size})
			draw_menu(&canvas, &canvas_cache, small_array.slice(&menu_options), selected_option)
		}

		if scene == .Intro {
			draw_intro(&canvas, intro, frame_delta)
		}

		if scene == .End {
			draw_end(&canvas)
		}

		if fade.state {
			draw_fade(&canvas, fade, frame_delta)
			small_array.push_back(&canvas_cache, swin.Rect{{}, canvas.size})
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

		client_size := get_from_i64(&global_state.client_size)
		scale := get_buffer_scale(client_size[0], client_size[1])
		buf_w, buf_h := BUFFER_W * scale, BUFFER_H * scale
		off_x := (cast(int)client_size[0] - buf_w) / 2
		off_y := (cast(int)client_size[1] - buf_h) / 2
		swin.display_pixels(window, canvas, {{off_x, off_y}, {buf_w, buf_h}})

		sync.atomic_store(&global_state.frame_time, time.tick_since(start_tick))
	}
}

get_buffer_scale :: proc(client_w, client_h: i32) -> int {
	scale := 1
	for {
		scale += 1
		if BUFFER_W * scale > cast(int)client_w || BUFFER_H * scale > cast(int)client_h {
			scale -= 1
			break
		}
	}

	return scale
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

player_animation_start :: proc(a: ^Animation) {
	if !a.state {
		stop_idling()
		a.state = true
		a.timer = 0
		a.frame = 0
	}
}

start_moving :: proc(d: Direction) {
	world.player.direction = d
	player_animation_start(&world.player.walking)
	if !world.player.belt {
		world.level.steps += 1
	}
}

move_player :: #force_inline proc(d: Direction) {
	if world.level.ended || world.player.dying.state || world.player.fading.state || world.player.walking.state {
		return
	}

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
	world.level.changes[idx] = true
}

press_red_button :: proc() {
	for tile, idx in world.level.tiles {
		pos: [2]int = {idx%world.level.w, idx/world.level.w}
		switch {
		case tile == .Red_Button:
			set_level_tile(pos, .Red_Button_Pressed)
		case tile == .Red_Button_Pressed:
			set_level_tile(pos, .Red_Button)
		case tile in wall_tiles:
			new_tile := wall_switch[tile] or_else .Egg
			set_level_tile(pos, new_tile)
		}
	}
}

press_yellow_button :: proc() {
	for tile, idx in world.level.tiles {
		pos: [2]int = {idx%world.level.w, idx/world.level.w}
		switch {
		case tile == .Yellow_Button:
			set_level_tile(pos, .Yellow_Button_Pressed)
		case tile == .Yellow_Button_Pressed:
			set_level_tile(pos, .Yellow_Button)
		case tile in belt_tiles:
			new_tile := belt_switch[tile] or_else .Egg
			set_level_tile(pos, new_tile)
		}
	}
}

finish_level :: proc(next: int) {
	if world.level.steps < settings.scoreboard_steps[world.level.current] || settings.scoreboard_steps[world.level.current] == 0 {
		settings.scoreboard_steps[world.level.current] = world.level.steps
	}

	if world.level.time < settings.scoreboard_time[world.level.current] || settings.scoreboard_time[world.level.current] == 0 {
		settings.scoreboard_time[world.level.current] = world.level.time
	}

	world.level.ended = true
	world.level.next = next
	if world.level.next > settings.last_unlocked_level {
		settings.last_unlocked_level = world.level.next
		if settings.last_unlocked_level >= len(levels) {
			settings.last_unlocked_level -= 1
		}
	}
	player_animation_start(&world.player.fading)
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
		player_animation_start(&world.player.dying)
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

switch_scene :: proc(s: Scene) {
	world.next_scene = s
	world.fade.state = true
	world.fade.timer = 0
	world.fade.frame = 0
}

main_menu_continue :: proc() {
	world.level.next = settings.last_unlocked_level
	switch_scene(.Game)
}

main_menu_new_game :: proc() {
	world.selected_level = 0
	settings.last_unlocked_level = 0
	world.level.next = 0
	switch_scene(.Game)
}

main_menu_select_level :: proc() {
	world.level.next = world.selected_level
	switch_scene(.Game)
}

main_menu_scoreboard_time :: proc() {
	// TODO
}

main_menu_scoreboard_steps :: proc() {
	// TODO
}

menu_sound :: proc() {
	settings.sound = !settings.sound
	switch world.scene {
	case .Pause_Menu:
		show_pause_menu(clear = false)
	case .Main_Menu:
		show_main_menu(clear = false)
	case .None, .Intro, .Game, .End:
	}
}

main_menu_credits :: proc() {
	// TODO
}

main_menu_quit :: proc() {
	window.must_close = true
}

pause_menu_continue :: proc() {
	world.scene = .Game
}

pause_menu_restart :: proc() {
	switch_scene(.Game)
	player_animation_start(&world.player.dying)
}

pause_menu_exit :: proc() {
	world.level.next = -1
	switch_scene(.Game)
}

menu_option_label_printf :: proc(option: ^Menu_Option, format: string, args: ..any) {
	name := fmt.bprintf(option.name_buf[:], format, ..args)
	option.name_len = len(name)
	option.size = measure_text(general_font, name)
}

show_main_menu :: proc(clear := true) {
	if clear do world.selected_option = 0
	world.scene = .Main_Menu
	small_array.clear(&world.menu_options)

	total_h: int
	if settings.last_unlocked_level > 0 {
		option: Menu_Option = {function = main_menu_continue}
		menu_option_label_printf(&option, "Continue")
		option.x = (BUFFER_W - option.size[0]) / 2
		option.y = total_h
		total_h += option.size[1]
		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	{
		option: Menu_Option = {function = main_menu_new_game}
		menu_option_label_printf(&option, "New game")
		option.x = (BUFFER_W - option.size[0]) / 2
		option.y = total_h
		total_h += option.size[1]
		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	{
		option: Menu_Option = {function = main_menu_select_level}
		menu_option_label_printf(&option, "Select level: {}", world.selected_level + 1)
		total_w := option.size[0] + (RIGHT_ARROW.size[0] + 2) * 2
		option.x = (BUFFER_W - total_w) / 2
		option.y = total_h
		total_h += option.size[1]

		arrows: [2]bool
		if settings.last_unlocked_level != 0 {
			if world.selected_level > 0 {
				arrows[0] = true
			}
			if world.selected_level < settings.last_unlocked_level {
				arrows[1] = true
			}
		}
		option.arrows = arrows

		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	{
		option: Menu_Option = {function = main_menu_scoreboard_time}
		menu_option_label_printf(&option, "Scoreboard (time)")
		option.x = (BUFFER_W - option.size[0]) / 2
		option.y = total_h
		total_h += option.size[1]
		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	{
		option: Menu_Option = {function = main_menu_scoreboard_steps}
		menu_option_label_printf(&option, "Scoreboard (steps)")
		option.x = (BUFFER_W - option.size[0]) / 2
		option.y = total_h
		total_h += option.size[1]
		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	{
		option: Menu_Option = {function = menu_sound}
		menu_option_label_printf(&option, "Sound: {}", settings.sound)
		option.x = (BUFFER_W - option.size[0]) / 2
		option.y = total_h
		total_h += option.size[1]
		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	// TODO: Campaign switch

	// Manual?

	{
		option: Menu_Option = {function = main_menu_credits}
		menu_option_label_printf(&option, "Credits")
		option.x = (BUFFER_W - option.size[0]) / 2
		option.y = total_h
		total_h += option.size[1]
		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	{
		option: Menu_Option = {function = main_menu_quit}
		menu_option_label_printf(&option, "Quit")
		option.x = (BUFFER_W - option.size[0]) / 2
		option.y = total_h
		total_h += option.size[1]
		small_array.push_back(&world.menu_options, option)
	}

	y := (BUFFER_H - total_h) / 2
	options_slice := small_array.slice(&world.menu_options)
	for option in &options_slice {
		option.y += y
	}
}

show_pause_menu :: proc(clear := true) {
	if clear do world.selected_option = 0
	world.scene = .Pause_Menu
	small_array.clear(&world.menu_options)

	total_h: int
	{
		option: Menu_Option = {function = pause_menu_continue}
		menu_option_label_printf(&option, "Continue")
		option.x = (BUFFER_W - option.size[0]) / 2
		option.y = total_h
		total_h += option.size[1]
		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	{
		option: Menu_Option = {function = pause_menu_restart}
		menu_option_label_printf(&option, "Restart level")
		option.x = (BUFFER_W - option.size[0]) / 2
		option.y = total_h
		total_h += option.size[1]
		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	// Help?

	{
		option: Menu_Option = {function = menu_sound}
		menu_option_label_printf(&option, "Sound: {}", settings.sound)
		option.x = (BUFFER_W - option.size[0]) / 2
		option.y = total_h
		total_h += option.size[1]
		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	{
		option: Menu_Option = {function = pause_menu_exit}
		menu_option_label_printf(&option, "Exit level")
		option.x = (BUFFER_W - option.size[0]) / 2
		option.y = total_h
		total_h += option.size[1]
		small_array.push_back(&world.menu_options, option)
	}

	y := (BUFFER_H - total_h) / 2
	options_slice := small_array.slice(&world.menu_options)
	for option in &options_slice {
		option.y += y
	}
}

load_level :: proc() {
	world.scene = .Game
	next := world.level.next

	if len(world.level.tiles) != 0 {
		delete(world.level.tiles)
		delete(world.level.changes)
	}

	world.player = {}
	world.level = {}

	if next >= len(levels){
		world.scene = .End
		return
	} else if next < 0 {
		show_main_menu()
		return
	}

	world.level.current = next
	world.level.next = next
	world.level.w = len(levels[world.level.current][0])
	world.level.h = len(levels[world.level.current])
	world.level.tiles = make([]Tiles, world.level.w * world.level.h)
	world.level.changes = make([]bool, world.level.w * world.level.h)
	world.level.changed = true

	for row, y in levels[world.level.current] {
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

	player_animation_start(&world.player.fading)
}

common_menu_key_handler :: proc(key: swin.Key_Code, state: bit_set[Key_State]) -> (handled: bool) {
	if world.fade.state do return true

	#partial switch key {
	case .Enter:
		handled = true
		if .Pressed in state {
			small_array.get_ptr(&world.menu_options, world.selected_option).function()
		}
	case .Down:
		handled = true
		if state & {.Pressed, .Repeated} > {} {
			world.selected_option += 1
			if world.selected_option >= world.menu_options.len {
				world.selected_option = 0
			}
		}
	case .Up:
		handled = true
		if state & {.Pressed, .Repeated} > {} {
			world.selected_option -= 1
			if world.selected_option < 0 {
				world.selected_option = world.menu_options.len - 1
			}
		}
	}

	return
}

pause_menu_key_handler :: proc(key: swin.Key_Code, state: bit_set[Key_State]) {
	if common_menu_key_handler(key, state) do return

	#partial switch key {
	case .Escape:
		if .Pressed in state {
			pause_menu_continue()
		}
	}
}

main_menu_key_handler :: proc(key: swin.Key_Code, state: bit_set[Key_State]) {
	if common_menu_key_handler(key, state) do return

	#partial switch key {
	case .Right:
		option := small_array.get_ptr(&world.menu_options, world.selected_option)
		if option.function == main_menu_select_level {
			if state & {.Pressed, .Repeated} > {} {
				world.selected_level += 1
				if world.selected_level > settings.last_unlocked_level {
					world.selected_level -= 1
				}
				show_main_menu(clear = false)
			}
		}
	case .Left:
		option := small_array.get_ptr(&world.menu_options, world.selected_option)
		if option.function == main_menu_select_level {
			if state & {.Pressed, .Repeated} > {} {
				world.selected_level -= 1
				if world.selected_level < 0 {
					world.selected_level = 0
				}
				show_main_menu(clear = false)
			}
		}
	}
}

intro_key_handler :: proc(key: swin.Key_Code, state: bit_set[Key_State]) {
	if .Pressed in state {
		show_main_menu()
	}
}

end_key_handler :: proc(key: swin.Key_Code, state: bit_set[Key_State]) {
	if .Pressed in state {
		// TODO: switch to credits
		switch_scene(.Main_Menu)
	}
}

game_key_handler :: proc(key: swin.Key_Code, state: bit_set[Key_State]) {
	shift := .Held in global_state.keyboard.keys[.LShift]

	#partial switch key {
	case .Right: move_player(.Right)
	case .Left:  move_player(.Left)
	case .Down:  move_player(.Down)
	case .Up:    move_player(.Up)
	case .R:
		if .Pressed in state {
			world.level.next = world.level.current
			if world.level.ended {
				load_level()
			} else {
				player_animation_start(&world.player.dying)
			}
		}
	case .F:
		if !world.player.fading.state {
			finish_level(world.level.current + (1 if !shift else -1))
		}
	case .S:
		if !world.player.fading.state {
			world.level.next += (1 if !shift else -1)
			load_level()
		}
	case .Escape:
		if .Pressed in state {
			show_pause_menu()
		}
	case .Enter:
		if .Pressed in state {
			if world.level.ended && !world.player.fading.state {
				switch_scene(.Game)
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

get_walking_sprite :: proc(frame: uint) -> Sprite_Offset {
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

menu_option_at :: proc(pos: [2]i16) -> Maybe(int) {
	offset: [2]int
	scale: int

	{
		client_size := get_from_i64(&global_state.client_size)
		scale = get_buffer_scale(client_size[0], client_size[1])
		buf_w, buf_h := BUFFER_W * scale, BUFFER_H * scale
		offset.x = (cast(int)client_size[0] - buf_w) / 2
		offset.y = (cast(int)client_size[1] - buf_h) / 2
	}

	options_slice := small_array.slice(&world.menu_options)
	for option, idx in options_slice {
		hitbox := option.rect

		// make hitbox a big bigger on Y axis
		hitbox.y -= 2
		hitbox.size[1] += 4

		// adjust for window size
		hitbox.pos *= scale
		hitbox.size *= scale
		hitbox.pos += offset

		if is_inside_rect({int(pos.x), int(pos.y)}, transmute(swin.Rect)hitbox) {
			return idx
		}
	}

	return nil
}

update_world :: proc(t: ^thread.Thread) {
	world.scene = .Intro
	world.intro.state = true

	for {
		start_tick := time.tick_now()

		{
			sync.guard(&world.lock)
			defer sync.atomic_store(&world.updated, true)

			{ // keyboard inputs
				sync.guard(&global_state.keyboard.lock)
				for state, key in &global_state.keyboard.keys {
					if state == {} do continue

					switch world.scene {
					case .None:
					case .Intro:
						intro_key_handler(key, state)
					case .Main_Menu:
						main_menu_key_handler(key, state)
					case .Pause_Menu:
						pause_menu_key_handler(key, state)
					case .Game:
						game_key_handler(key, state)
					case .End:
						end_key_handler(key, state)
					}

					if .Repeated in state do state -= {.Repeated}
					if .Pressed in state do state -= {.Pressed}
					if .Released in state do state = {}
				}
			}

			when MOUSE_SUPPORT {
				{ // mouse buttons
					sync.guard(&global_state.mouse.lock)
					for state, button in &global_state.mouse.buttons {
						if state == {} do continue

						if world.scene == .Main_Menu || world.scene == .Pause_Menu {
							if button == .Left && .Clicked in state {
								mouse_pos := get_from_i32(&global_state.mouse_pos)

								if idx := menu_option_at(mouse_pos); idx != nil {
									world.selected_option = idx.?
									common_menu_key_handler(.Enter, {.Pressed})
								}
							}
						}

						if .Double_Clicked in state do state -= {.Double_Clicked}
						if .Clicked in state do state -= {.Clicked}
						if .Released in state do state = {}
					}
				}

				// mouse movement
				if sync.atomic_load(&global_state.mouse_move.moved) {
					sync.guard(&global_state.mouse_move.lock)
					defer sync.atomic_store(&global_state.mouse_move.moved, false)
					pos := global_state.mouse_move.pos

					if idx := menu_option_at(pos); idx != nil {
						world.selected_option = idx.?
					}
				}
			}

			if world.scene == .Intro {
				if world.intro.state {
					if world.intro.timer >= INTRO_LENGTH {
						world.intro.state = false
						switch_scene(.Main_Menu)
					}

					world.intro.timer += 1
				}
			}

			if world.scene == .Game {
				// animations
				switch {
				case world.player.fading.state:
					world.player.fading.frame = world.player.fading.timer / FADING_ANIM_FRAME_LEN

					if world.player.fading.frame >= len(fading_animation) {
						world.player.fading.state = false
						world.player.fading.timer = 0
						world.player.fading.frame = 0
					} else {
						if world.level.current == world.level.next {
							// reverse frames when spawning
							world.player.fading.frame = len(fading_animation) - 1 - world.player.fading.frame
						}
						world.player.sprite = fading_animation[world.player.fading.frame]
					}

					world.player.fading.timer += 1
				case world.player.dying.state:
					world.player.dying.frame = world.player.dying.timer / DYING_ANIM_FRAME_LEN

					if world.player.dying.frame >= len(dying_animation) {
						if world.player.dying.timer - (len(dying_animation) * DYING_ANIM_FRAME_LEN) >= LAYING_DEAD_TIME {
							world.player.dying.state = false
							world.player.dying.timer = 0
							world.player.dying.frame = 0
							load_level()
						}
					} else {
						world.player.sprite = dying_animation[world.player.dying.frame]
					}

					world.player.dying.timer += 1
				case world.player.walking.state:
					world.player.walking.frame = world.player.walking.timer / WALKING_ANIM_FRAME_LEN

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
					world.player.idle.frame = world.player.idle.timer / IDLE_ANIM_FRAME_LEN

					world.player.idle.frame %= len(idle_animation)
					world.player.sprite = idle_animation[world.player.idle.frame]

					world.player.idle.timer += 1
				case !world.level.ended:
					world.player.sprite = get_walking_sprite(0)

					if world.player.idle.timer > IDLING_TIME {
						player_animation_start(&world.player.idle)
					}

					world.player.idle.timer += 1
				}

				world.level.animation.frame = world.level.animation.timer / LEVEL_ANIM_FRAME_LEN
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

				// track level time
				if !world.level.ended {
					world.level.time += sync.atomic_load(&global_state.tick_time)
				}
			}

			if world.fade.state {
				// we are using frame as a counter to only do the action once
				if world.fade.timer >= FADE_LENGTH / 2 && world.fade.frame == 0 {
					world.scene = world.next_scene
					world.fade.frame = 1
					if world.scene == .Main_Menu {
						show_main_menu()
					}
					if world.scene == .Game {
						load_level()
					}
				}

				if world.fade.timer >= FADE_LENGTH {
					world.fade.state = false
				}
				world.fade.timer += 1
			}

			global_state.previous_tick = time.tick_now()
		}

		sync.atomic_store(&global_state.tick_work, time.tick_since(start_tick))

		limit_frame(time.tick_since(start_tick), TPS, false) // NOTE: not using accurate timer for 30 TPS, should I?

		sync.atomic_store(&global_state.tick_time, time.tick_since(start_tick))
	}
}

event_handler :: proc(window: ^swin.Window, event: swin.Event) {
	switch ev in event {
	case swin.Close_Event:
	case swin.Focus_Event:
		if !ev.focused {
			sync.guard(&global_state.keyboard.lock)
			for state in &global_state.keyboard.keys {
				// release all pressed keys
				if .Held in state {
					state = {.Released}
				}
			}
		}
	case swin.Draw_Event:
	case swin.Resize_Event:
		save_to_i64(&global_state.client_size, {i32(window.client.size[0]), i32(window.client.size[1])})
	case swin.Move_Event:
	case swin.Character_Event:
	case swin.Keyboard_Event:
		{
			sync.guard(&global_state.keyboard.lock)
			state := global_state.keyboard.keys[ev.key]
			switch ev.state {
			case .Released: state += {.Released}
			case .Repeated: state += {.Repeated}
			case .Pressed: state += {.Pressed, .Held}
			}
			global_state.keyboard.keys[ev.key] = state
		}

		switch ev.state {
		case .Repeated, .Released:
		case .Pressed:
			// TODO: remove these before release
			#partial switch ev.key {
			case .V: settings.vsync = !settings.vsync
			case .I: settings.show_stats = !settings.show_stats
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
	case swin.Mouse_Button_Event:
		when MOUSE_SUPPORT {
			sync.guard(&global_state.mouse.lock)
			state := global_state.mouse.buttons[ev.button]

			if ev.clicked {
				state += {.Clicked, .Held}
			} else {
				state += {.Released}
			}

			if ev.double_clicked {
				state += {.Double_Clicked}
			}

			global_state.mouse.buttons[ev.button] = state
		}
	case swin.Mouse_Move_Event:
		when MOUSE_SUPPORT {
			save_to_i32(&global_state.mouse_pos, ev.pos)

			sync.guard(&global_state.mouse_move.lock)
			defer sync.atomic_store(&global_state.mouse_move.moved, true)

			global_state.mouse_move.pos = ev.pos
		}
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
		t.pixels[i] = swin.color(p)
	}
	return
}

load_resources :: proc() {
	general_font.texture = load_texture(#load("res/font.png"), image.RGBA_Pixel)
	general_font.glyph_size = {5, 7}
	general_font.table = make(map[rune][2]int)
	for ch in ` 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ?'".,:;~!@#$^&_|\/%*+-=<>()[]{}` {
		glyph_idx := len(general_font.table)
		gx := (glyph_idx % (general_font.size[0] / general_font.glyph_size[0])) * general_font.glyph_size[0]
		gy := (glyph_idx / (general_font.size[0] / general_font.glyph_size[0])) * general_font.glyph_size[1]
		general_font.table[ch] = {gx, gy}
	}

	atlas = load_texture(#load("res/atlas.png"), image.RGBA_Pixel)

	hud_font.texture = atlas
	hud_font.glyph_size = {5, 8}
	hud_font.table = make(map[rune][2]int)
	for ch in `0123456789:?` {
		OFFSET: [2]int : {128, 106}
		glyph_idx := len(hud_font.table)
		gx := OFFSET.x + (glyph_idx * hud_font.glyph_size[0])
		gy := OFFSET.y
		hud_font.table[ch] = {gx, gy}
	}

	MAX_X :: 12
	for s in Sprites {
		idx := int(s)
		pos: [2]int = {idx%MAX_X, idx/MAX_X}
		sprites[s] = {pos * TILE_SIZE, {TILE_SIZE, TILE_SIZE}}
	}

	splashes = load_texture(#load("res/splashes.png"), image.RGBA_Pixel)
	logo = load_texture(#load("res/logo.png"), image.RGBA_Pixel)
}

_main :: proc(allocator: runtime.Allocator) {
	{
		context.allocator = allocator
		load_resources()
	}

	config_dir, err := os2.user_config_dir(allocator)
	assert(err == nil && config_dir != "", "Could not find user config directory")

	game_config_dir := filepath.join({config_dir, "bobby"}, allocator)

	if !os.exists(game_config_dir) {
		os2.mkdir(game_config_dir, os2.File_Mode_Dir)
	}

	settings_location := filepath.join({game_config_dir, "settings.save"}, allocator)

	if os.exists(settings_location) {
		bytes, _ := os.read_entire_file(settings_location)
		defer delete(bytes)

		json.unmarshal(bytes, &settings)
	}

	// Open window
	assert(swin.create(&window, WINDOW_W, WINDOW_H, GAME_TITLE, {} when MOUSE_SUPPORT else {.Hide_Cursor}), "Failed to create window")
	defer swin.destroy(&window)

	{ // center the window
		wr := swin.get_working_area()
		pos := wr.pos + ((wr.size / 2) - (window.size / 2))
		swin.move(&window, pos)
	}

	//window.clear_color = SKY_BLUE.rgb
	window.event_handler = event_handler
	swin.set_resizable(&window, true)
	swin.set_min_size(&window, {BUFFER_W, BUFFER_H})

	save_to_i64(&global_state.client_size, {i32(window.client.size[0]), i32(window.client.size[1])})

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

	// NOTE: this will only trigger on a proper quit, not on a task termination
	{
		data, err := json.marshal(settings, {pretty = true}, allocator)
		assert(err == nil, fmt.tprint("Unable to save the game:", err))

		ok := os.write_entire_file(settings_location, data)
		assert(ok, fmt.tprint("Unable to save the game"))
	}
}
