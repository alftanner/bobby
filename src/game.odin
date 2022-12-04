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

import spl "spl"

GAME_TITLE :: "Bobby Carrot Remastered"
TIMER_FAIL :: "Failed to create a timer. I would use sleep() instead, but @mmozeiko said that sleeping is bad."

Score :: struct {
	time: time.Duration,
	steps: int,
}

Settings :: struct {
	fps: uint,
	vsync: bool,
	show_stats: bool,

	last_unlocked_levels: [Campaign]int,
	campaign: Campaign,

	carrots_scoreboard: [len(carrot_levels)]Score,
	eggs_scoreboard: [len(egg_levels)]Score,

	selected_levels: [Campaign]int,
	language: Language,
}
default_settings: Settings : {
	fps = 30,
	vsync = true,
	show_stats = true,
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
FADE_LENGTH :: TPS_SECOND / 2
CREDITS_LENGTH :: TPS_SECOND * 3
END_LENGTH :: TPS_SECOND * 3
BUFFER_W :: TILES_W * TILE_SIZE
BUFFER_H :: TILES_H * TILE_SIZE
DEFAULT_SCALE :: 3
WINDOW_W :: BUFFER_W * DEFAULT_SCALE
WINDOW_H :: BUFFER_H * DEFAULT_SCALE

Font :: struct {
	using texture: spl.Texture2D,
	table: map[rune][2]int,
	glyph_size: [2]int,
}
general_font: Font
hud_font: Font
atlas, splashes, logo: spl.Texture2D

Direction :: enum {
	None,
	Right,
	Left,
	Down,
	Up,
}

Sprite :: spl.Rect

Sprite_Offset :: struct {
	using sprite: Sprite,
	offset: [2]int,
}

Text_Label :: struct {
	using rect: spl.Rect,
	text_buf: [64]byte,
	text_len: int,
}

Menu_Option :: struct {
	using label: Text_Label,

	func: proc(),
	arrows: Maybe([2]struct {
		enabled: bool,
		func: proc(),
	}),
}

// max redraw regions
Region_Cache :: small_array.Small_Array(512, spl.Rect)
// max tiles changed in an update
Tile_Queue :: small_array.Small_Array(256, int)

Menu_Options :: small_array.Small_Array(16, Menu_Option)
Scoreboard :: small_array.Small_Array(128, Text_Label)

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
	size: [2]int,
	tiles: []Tiles,
	current, next: int,

	animation: Animation,
	carrots, eggs: int,
	can_end, ended: bool,

	score: Score,

	// for rendering
	changed: bool,
}

Scene :: enum {
	None,
	Intro,
	Main_Menu,
	Pause_Menu,
	Game,
	End,
	Credits,
	Scoreboard,
}

World :: struct {
	updated: bool,
	lock: sync.Mutex,

	scene: Scene,
	next_scene: Scene,

	fade, intro, end, credits: Animation,

	menu_options: Menu_Options,
	selected_option: int,
	keep_selected_option: bool,

	scoreboard: Scoreboard,
	scoreboard_page: int,

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

Keyboard_State :: struct {
	lock: sync.Mutex,
	keys: [spl.Key_Code]bit_set[Key_State],
}

State :: struct {
	// TODO: i128 with atomic_load/store
	client_size: i64,

	// _work shows how much time was spent on actual work in that frame before sleep
	// _time shows total time of the frame, sleep included
	frame_work, frame_time: time.Duration,
	tick_work, tick_time: time.Duration,
	previous_tick: time.Tick,

	keyboard: Keyboard_State,
}
global_state: State

window: spl.Window

SPACE_BETWEEN_ARROW_AND_TEXT :: 3
RIGHT_ARROW :: Sprite{{183, 115}, {5, 9}}
UP_ARROW :: Sprite{{183, 125}, {9, 5}}
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
/*
save_to_i32 :: #force_inline proc(p: ^i32, a: [2]i16) {
	sync.atomic_store(p, transmute(i32)a)
}

get_from_i32 :: #force_inline proc(p: ^i32) -> [2]i16 {
	return transmute([2]i16)sync.atomic_load(p)
}

limit_frame :: proc(frame_time: time.Duration, frame_limit: uint) {
	if frame_limit <= 0 do return

	ms_per_frame := time.Duration((1000.0 / f32(frame_limit)) * f32(time.Millisecond))
	to_sleep := ms_per_frame - frame_time

	if to_sleep <= 0 do return

	time.sleep(to_sleep)
}
*/

assertion_failure_proc :: proc(prefix, message: string, loc: runtime.Source_Code_Location) -> ! {
	error := fmt.tprintf("{}({}:{}) {}", loc.file_path, loc.line, loc.column, prefix)
	if len(message) > 0 {
		error = fmt.tprintf("{}: {}", error, message)
	}

	fmt.eprintln(error)

	spl.show_message_box(.Error, "Error!", fmt.tprintf("{}: {}", prefix, message))

	runtime.trap()
}

logger_proc :: proc(data: rawptr, level: runtime.Logger_Level, text: string, options: runtime.Logger_Options, location := #caller_location) {
	if level == .Fatal {
		fmt.eprintf("[{}] {}\n", level, text)
		spl.show_message_box(.Error, "Error!", text)
		runtime.trap()
	} else if level == .Info {
		fmt.eprintf("{}\n", text)
	} else {
		fmt.eprintf("[{}] {}\n", level, text)
	}
}

cycles_lap_time :: proc(prev: ^u64) -> u64 {
	cycles: u64
	cycle_count := time.read_cycle_counter()
	if prev^ != 0 {
		cycles = cycle_count - prev^
	}
	prev^ = cycle_count
	return cycles
}

measure_or_draw_text :: proc(
	canvas: ^spl.Texture2D,
	font: Font,
	text: string,
	pos: [2]int,
	color: image.RGB_Pixel,
	shadow_color: image.RGB_Pixel,
	no_draw := false,
) -> (region: spl.Rect) {
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
			spl.draw_from_texture(canvas, font.texture, pos + 1, {glyph_pos, font.glyph_size}, .None, shadow_color)
			spl.draw_from_texture(canvas, font.texture, pos, {glyph_pos, font.glyph_size}, .None, color)
		}

		pos.x += font.glyph_size[0] + 1
		region.size[0] = max(region.size[0], pos.x - region.x)
	}
	region.size[1] = pos.y - region.y + font.glyph_size[1] + 1

	return
}

draw_text :: #force_inline proc(
	canvas: ^spl.Texture2D,
	font: Font,
	text: string,
	pos: [2]int,
	color: image.RGB_Pixel = {255, 255, 255},
	shadow_color: image.RGB_Pixel = {0, 0, 0},
) -> (region: spl.Rect) {
	return measure_or_draw_text(canvas, font, text, pos, color, shadow_color)
}

measure_text :: #force_inline proc(font: Font, text: string) -> [2]int {
	region := measure_or_draw_text(nil, font, text, {}, {}, {}, true)
	return region.size
}

draw_stats :: proc(canvas: ^spl.Texture2D) -> spl.Rect {
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

get_fade_alpha :: proc(fade: Animation, frame_delta: f32) -> u8 {
	if !fade.state do return 0

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

	return alpha
}

get_intro_alpha :: proc(intro: Animation, frame_delta: f32) -> u8 {
	SECTION_LENGTH :: FADE_LENGTH

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

	return alpha
}

draw_credits :: proc(t: ^spl.Texture2D, language: Language) {
	slice.fill(t.pixels, spl.BLACK)

	str := language_strings[language][.Credits_Original]
	str2 := language_strings[language][.Credits_Remastered]

	str_size := measure_text(general_font, str)
	str2_size := measure_text(general_font, str2)
	size_h := str_size[1] + general_font.glyph_size[1] + logo.size[1] + general_font.glyph_size[1] + str2_size[1]
	off_y := (t.size[1] - size_h) / 2

	draw_text(t, general_font, str, {(t.size[0] - str_size[0]) / 2, off_y})
	off_y += str_size[1] + general_font.glyph_size[1]
	spl.draw_from_texture(t, logo, {(t.size[0] - logo.size[0]) / 2, off_y}, {{}, logo.size})
	off_y += logo.size[1] + general_font.glyph_size[1]
	draw_text(t, general_font, str2, {(t.size[0] - str2_size[0]) / 2, off_y})
}

interpolate_tile_position :: #force_inline proc(p: Player, frame_delta: f32) -> [2]f32 {
	if p.walking.state {
		ANIM_TIME :: f32(WALKING_ANIM_FRAME_LEN * WALKING_ANIM_LEN) - 1
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

get_sprite_from_pos :: proc(pos: [2]int, level: Level) -> Sprite {
	tile := get_tile_from_pos(pos, level)
	sprite: Sprite = sprites[.Ground]

	switch tile {
	case .Grass:
		d: bit_set[Direction]
		if get_tile_from_pos({pos.x - 1, pos.y}, level) != .Grass do d += {.Left}
		if get_tile_from_pos({pos.x + 1, pos.y}, level) != .Grass do d += {.Right}
		if get_tile_from_pos({pos.x, pos.y - 1}, level) != .Grass do d += {.Up}
		if get_tile_from_pos({pos.x, pos.y + 1}, level) != .Grass do d += {.Down}
		sprite = sprites[grass_sprites[d] or_else .Grass]
	case .Fence:
		d: bit_set[Direction]
		if get_tile_from_pos({pos.x - 1, pos.y}, level) == .Fence do d += {.Left}
		if get_tile_from_pos({pos.x + 1, pos.y}, level) == .Fence do d += {.Right}
		//if get_tile_from_pos({pos.x, pos.y - 1}, level) == .Fence do d += {.Up}
		if get_tile_from_pos({pos.x, pos.y + 1}, level) == .Fence do d += {.Down}
		sprite = sprites[fence_sprites[d] or_else .Fence_Down]
	case .End:
		sprite = sprites[.End]
		if level.can_end {
			sprite = end_animation[level.animation.frame]
		}
	case .Belt_Right, .Belt_Left, .Belt_Down, .Belt_Up:
		sprite = belt_animation[level.animation.frame]
		#partial switch tile {
		case .Belt_Right:
			sprite.x += 64
		case .Belt_Up:
			sprite.x += 128
		case .Belt_Down:
			sprite.y += 16
		}
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
/*
is_inside_rect :: #force_inline proc(p: [2]int, r: spl.Rect) -> bool {
	return p.x >= r.x && p.x < r.x + r.size[0] && p.y >= r.y && p.y < r.y + r.size[1]
}

rect_intersection :: proc(r1, r2: spl.Rect) -> spl.Rect {
	pos: [2]int = {max(r1.x, r2.x), max(r1.y, r2.y)}
	right_x := min(r1.x + r1.size[0], r2.x + r2.size[0])
	bottom_y := min(r1.y + r1.size[1], r2.y + r2.size[1])

	if pos.x < right_x && pos.y < bottom_y {
		return {pos, {right_x - pos.x, bottom_y - pos.y}}
	}
	return {}
}
*/
draw_scoreboard :: proc(t: ^spl.Texture2D, q: ^Region_Cache, labels: []Text_Label, page: int) {
	if len(labels) == 0 do return

	DISABLED :: image.RGB_Pixel{75, 75, 75}
	//NORMAL :: image.RGB_Pixel{145, 145, 145}
	SELECTED :: image.RGB_Pixel{255, 255, 255}

	pages := ((len(labels) - 1) / 10) + 1
	label_idx := page * 10

	page_labels := labels[label_idx:min(label_idx + 10, len(labels))]

	// 10 lables per page + 9 lines between them
	page_h := general_font.glyph_size[1] * 19
	y := (BUFFER_H - page_h) / 2

	up_arrow, down_arrow: spl.Rect
	up_arrow.size = UP_ARROW.size
	down_arrow.size = UP_ARROW.size

	up_arrow.x = (BUFFER_W - UP_ARROW.size[0]) / 2
	down_arrow.x = up_arrow.x

	up_arrow.y = (y - UP_ARROW.size[1]) / 2
	down_arrow.y = BUFFER_H - up_arrow.y

	for label in page_labels {
		region := label.rect
		region.y = y
		text_buf := label.text_buf
		text := string(text_buf[:label.text_len])

		draw_text(t, general_font, text, region.pos, SELECTED)
		small_array.push_back(q, region)

		y += region.size[1] + general_font.glyph_size[1]
	}

	{
		color := SELECTED
		if page == 0 {
			color = DISABLED
		}
		spl.draw_from_texture(t, atlas, up_arrow.pos, UP_ARROW, .None, color)
		small_array.push_back(q, up_arrow)
	}
	{
		color := SELECTED
		if page == pages - 1 {
			color = DISABLED
		}
		spl.draw_from_texture(t, atlas, down_arrow.pos, UP_ARROW, .Vertical, color)
		small_array.push_back(q, down_arrow)
	}
}

draw_menu :: proc(t: ^spl.Texture2D, q: ^Region_Cache, options: []Menu_Option, selected: int) {
	DISABLED :: image.RGB_Pixel{75, 75, 75}
	NORMAL :: image.RGB_Pixel{145, 145, 145}
	SELECTED :: image.RGB_Pixel{255, 255, 255}

	for option, idx in options {
		region := option.rect
		text_buf := option.text_buf
		text := string(text_buf[:option.text_len])

		color := NORMAL
		if idx == selected {
			color = SELECTED
		}

		x := option.x
		if option.arrows != nil {
			color := color
			if !option.arrows.?[0].enabled {
				color = DISABLED
			}
			spl.draw_from_texture(t, atlas, {x, option.y - 1}, RIGHT_ARROW, .Horizontal, color)
			x += RIGHT_ARROW.size[0] + SPACE_BETWEEN_ARROW_AND_TEXT
			region.size[0] += (RIGHT_ARROW.size[0] + SPACE_BETWEEN_ARROW_AND_TEXT) * 2
			region.y -= 1
			region.size[1] += 2
		}

		draw_text(t, general_font, text, {x, option.y}, color)

		if option.arrows != nil {
			color := color
			if !option.arrows.?[1].enabled {
				color = DISABLED
			}
			x += option.size[0] + SPACE_BETWEEN_ARROW_AND_TEXT
			spl.draw_from_texture(t, atlas, {x, option.y - 1}, RIGHT_ARROW, .None, color)
		}

		small_array.push_back(q, region)
	}
}

render :: proc(t: ^thread.Thread) {
	context.assertion_failure_proc = assertion_failure_proc
	context.logger.procedure = logger_proc

	timer: spl.Timer
	if !settings.vsync {
		ok := spl.create_timer(&timer, settings.fps)
		when ODIN_OS == .Windows {
			assert(ok, fmt.tprintf("{} Anyways, here is the error code: {}", TIMER_FAIL, spl._windows_get_last_error()))
		} else {
			assert(ok, TIMER_FAIL)
		}
	}

	scene: Scene
	intro, fade: Animation
	scoreboard: Scoreboard
	campaign: Campaign
	menu_options: Menu_Options
	selected_option, scoreboard_page: int
	selected_levels: [Campaign]int
	language: Language
	player: Player

	level: Level

	previous_tick: time.Tick
	tick_time: f32
	diff, offset: [2]f32

	canvas, scene_texture: spl.Texture2D
	canvas_cache, canvas_cache_slow: Region_Cache

	backgrounds: [Campaign]spl.Texture2D
	tiles_updated: Tile_Queue

	canvas = spl.texture_make(BUFFER_W, BUFFER_H)
	scene_texture = spl.texture_make(BUFFER_W, BUFFER_H)
	for bg, c in &backgrounds {
		bg = spl.texture_make(BUFFER_W + TILE_SIZE, BUFFER_H + TILE_SIZE)
		sprite := sprites[.Grass if c == .Carrot_Harvest else .Ground]
		for y in 0..=TILES_H do for x in 0..=TILES_W {
			pos: [2]int = {x, y}
			spl.draw_from_texture(&bg, atlas, pos * TILE_SIZE, sprite)
		}
	}

	intro_alpha: u8
	for {
		start_tick := time.tick_now()

		canvas_redraw, scene_redraw, cache_slow_redraw: bool
		old_fade_state := fade.state
		if sync.atomic_load(&world.updated) {
			sync.guard(&world.lock)
			defer sync.atomic_store(&world.updated, false)

			if world.level.changed {
				world.level.changed = false
				scene_redraw = true

				if len(level.tiles) > 0 {
					delete(level.tiles)
				}
				level.size = world.level.size
				level.tiles = make([]Tiles, level.size[0] * level.size[1])

				diff = {f32(TILES_W - level.size[0]), f32(TILES_H - level.size[1])}
			}
			{ // copy and collect updates
				level.current = world.level.current
				level.next = world.level.next
				level.animation = world.level.animation
				level.carrots = world.level.carrots
				level.eggs = world.level.eggs
				level.can_end = world.level.can_end
				level.ended = world.level.ended
				level.score = world.level.score

				for tile, idx in world.level.tiles {
					old_tile := level.tiles[idx]
					level.tiles[idx] = tile

					if old_tile != tile || tile in belt_tiles || (tile == .End && level.can_end) {
						small_array.push_back(&tiles_updated, idx)
					}
				}
			}

			player = world.player
			intro = world.intro

			if scene != world.scene {
				scene_redraw = true
			}
			scene = world.scene

			fade = world.fade
			menu_options = world.menu_options

			scoreboard = world.scoreboard
			if scoreboard_page != world.scoreboard_page || selected_option != world.selected_option ||
			selected_levels != settings.selected_levels || language != settings.language {
				cache_slow_redraw = true
			}
			if campaign != settings.campaign {
				scene_redraw = true
			}
			scoreboard_page = world.scoreboard_page
			selected_option = world.selected_option
			selected_levels = settings.selected_levels
			campaign = settings.campaign
			language = settings.language

			previous_tick = global_state.previous_tick
			tick_time = f32(time.duration_milliseconds(sync.atomic_load(&global_state.tick_time)))
		}

		if old_fade_state || fade.state {
			cache_slow_redraw = true
		}

		// for smooth drawing
		frame_delta := f32(time.duration_milliseconds(time.tick_diff(previous_tick, time.tick_now()))) / tick_time
		player_pos := interpolate_tile_position(player, frame_delta)

		draw_world_background: bool
		#partial switch scene {
		case .Game: // calculate offset
			old_offset := offset
			offset = {}

			if diff.x > 0 {
				offset.x = diff.x / 2
				draw_world_background = true
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
				draw_world_background = true
			} else {
				off := (f32(TILES_H) / 2) - (f32(player_pos.y) + 0.5)
				if diff.y > off {
					offset.y = diff.y
				} else {
					offset.y = min(off, 0)
				}
			}

			// redraw scene if camera moved
			if old_offset != offset {
				scene_redraw = true
			}

			if !scene_redraw {
				lvl_offset: [2]int
				lvl_offset.x = int(offset.x * TILE_SIZE)
				lvl_offset.y = int(offset.y * TILE_SIZE)

				// draw updated tiles to scene texture
				for tile_idx in small_array.pop_back_safe(&tiles_updated) {
					pos: [2]int = {tile_idx%level.size[0], tile_idx/level.size[0]}
					sprite := get_sprite_from_pos(pos, level)

					region: spl.Rect
					region.pos = (pos * TILE_SIZE) + lvl_offset
					region.size = {TILE_SIZE, TILE_SIZE}

					spl.draw_from_texture(&scene_texture, atlas, region.pos, sprite)
					small_array.push_back(&canvas_cache, region)
				}
			} else {
				small_array.clear(&tiles_updated)
			}
		case .Intro: // do not redraw the intro after alpha became 0
			old_intro_alpha := intro_alpha
			intro_alpha = get_intro_alpha(intro, frame_delta)
			if old_intro_alpha != 0 || intro_alpha != 0 {
				scene_redraw = true
			}
		}

		if scene_redraw {
			switch scene {
			case .Game:
				lvl_offset: [2]int
				lvl_offset.x = int(offset.x * TILE_SIZE)
				lvl_offset.y = int(offset.y * TILE_SIZE)

				if draw_world_background { // TODO: only draw needed parts, not the entire thing
					bg_rect: spl.Rect
					bg_rect.pos.x = int(abs(offset.x - f32(int(offset.x))) * TILE_SIZE)
					bg_rect.pos.y = int(abs(offset.y - f32(int(offset.y))) * TILE_SIZE)
					bg_rect.size = backgrounds[.Carrot_Harvest].size - bg_rect.pos
					spl.draw_from_texture(&scene_texture, backgrounds[.Carrot_Harvest], {}, bg_rect)
				}
				for _, idx in level.tiles {
					pos: [2]int = {idx%level.size[0], idx/level.size[0]}
					sprite := get_sprite_from_pos(pos, level)
					spl.draw_from_texture(&scene_texture, atlas, (pos * TILE_SIZE) + lvl_offset, sprite)
				}
			case .Pause_Menu, .Main_Menu, .Scoreboard:
				texture := backgrounds[campaign]
				if scene == .Pause_Menu {
					texture = canvas
				}
				spl.draw_from_texture(&scene_texture, texture, {}, {{}, scene_texture.size})
				spl.draw_rect(&scene_texture, {{}, scene_texture.size}, {0, 0, 0, 0xaa})
			case .Intro:
				slice.fill(scene_texture.pixels, spl.BLACK)

				off := (scene_texture.size - INTRO_SPLASH.size) / 2
				spl.draw_from_texture(&scene_texture, splashes, off, INTRO_SPLASH)
				spl.draw_rect(&scene_texture, {off, INTRO_SPLASH.size}, {0, 0, 0, intro_alpha})
			case .End:
				slice.fill(scene_texture.pixels, spl.BLACK)

				off := (scene_texture.size - END_SPLASH.size) / 2
				spl.draw_from_texture(&scene_texture, splashes, off, END_SPLASH)
			case .Credits:
				draw_credits(&scene_texture, language)
			case .None:
				slice.fill(scene_texture.pixels, spl.BLACK)
			}

			canvas_redraw = true
		}

		if canvas_redraw {
			small_array.clear(&canvas_cache)
			small_array.clear(&canvas_cache_slow)
			spl.draw_from_texture(&canvas, scene_texture, {}, {{}, scene_texture.size})
		} else { // cached rendering
			for cache_region in small_array.pop_back_safe(&canvas_cache) {
				spl.draw_from_texture(&canvas, scene_texture, cache_region.pos, cache_region)
			}
		}

		if canvas_redraw || cache_slow_redraw {
			for cache_region in small_array.pop_back_safe(&canvas_cache_slow) {
				spl.draw_from_texture(&canvas, scene_texture, cache_region.pos, cache_region)
			}

			// slow cached drawing
			#partial switch scene {
			case .Main_Menu, .Pause_Menu:
				draw_menu(&canvas, &canvas_cache_slow, small_array.slice(&menu_options), selected_option)
			case .Scoreboard:
				draw_scoreboard(&canvas, &canvas_cache_slow, small_array.slice(&scoreboard), scoreboard_page)
			}
		}

		// do scene specific drawing that gets into fast cache, such as player/HUD/etc
		if scene == .Game {
			// draw player
			if !level.ended || (level.ended && player.fading.state) {
				pos := (player_pos + offset) * TILE_SIZE
				px := int(pos.x) + player.sprite.offset.x
				py := int(pos.y) + player.sprite.offset.y
				spl.draw_from_texture(&canvas, atlas, {px, py}, player.sprite)
				small_array.push_back(&canvas_cache, spl.Rect{{px, py}, player.sprite.size})
			}

			// HUD
			if !level.ended {
				// left part
				{
					tbuf: [8]byte
					time_str := fmt.bprintf(tbuf[:], "{:02i}:{:02i}", int(time.duration_minutes(level.score.time)), int(time.duration_seconds(level.score.time)) % 60)
					small_array.push_back(&canvas_cache, draw_text(&canvas, hud_font, time_str, {2, 2}))
				}
				// level begin screen
				if time.duration_seconds(level.score.time) < 2 {
					tbuf: [16]byte
					level_str := fmt.bprintf(tbuf[:], "{} {}", language_strings[settings.language][.Level], level.current + 1)
					size := measure_text(general_font, level_str)
					pos := (canvas.size - size) / 2
					small_array.push_back(&canvas_cache, draw_text(&canvas, general_font, level_str, pos))
				}
				// right part
				{
					pos: [2]int = {canvas.size[0] - 2, 2}

					if level.carrots > 0 {
						sprite := hud_sprites[.Carrot]
						pos.x -= sprite.size[0]
						spl.draw_from_texture(&canvas, atlas, pos, sprite)
						small_array.push_back(&canvas_cache, spl.Rect{pos, sprite.size})
						pos.x -= 2

						tbuf: [8]byte
						str := strconv.itoa(tbuf[:], level.carrots)
						{
							size := measure_text(hud_font, str)
							pos.x -= size[0]
						}
						small_array.push_back(&canvas_cache, draw_text(&canvas, hud_font, str, {pos.x, pos.y + 3}))
						pos.y += sprite.size[1] + 2
						pos.x = canvas.size[0] - 2
					}

					if level.eggs > 0 {
						sprite := hud_sprites[.Egg]
						pos.x -= sprite.size[0]
						spl.draw_from_texture(&canvas, atlas, pos, sprite)
						small_array.push_back(&canvas_cache, spl.Rect{pos, sprite.size})
						pos.x -= 2

						tbuf: [8]byte
						str := strconv.itoa(tbuf[:], level.eggs)
						{
							size := measure_text(hud_font, str)
							pos.x -= size[0]
						}
						small_array.push_back(&canvas_cache, draw_text(&canvas, hud_font, str, {pos.x, pos.y + 3}))
						pos.y += sprite.size[1] + 2
						pos.x = canvas.size[0] - 2
					}

					if player.silver_key {
						sprite := hud_sprites[.Silver_Key]
						pos.x -= sprite.size[0]
						spl.draw_from_texture(&canvas, atlas, pos, sprite)
						small_array.push_back(&canvas_cache, spl.Rect{pos, sprite.size})
						pos.x -= 2
					}
					if player.golden_key {
						sprite := hud_sprites[.Golden_Key]
						pos.x -= sprite.size[0]
						spl.draw_from_texture(&canvas, atlas, pos, sprite)
						small_array.push_back(&canvas_cache, spl.Rect{pos, sprite.size})
						pos.x -= 2
					}
					if player.copper_key {
						sprite := hud_sprites[.Copper_Key]
						pos.x -= sprite.size[0]
						spl.draw_from_texture(&canvas, atlas, pos, sprite)
						small_array.push_back(&canvas_cache, spl.Rect{pos, sprite.size})
						pos.x -= 2
					}
				}
			}

			// level end screen
			if level.ended && !player.fading.state {
				total_h: int
				success := hud_sprites[.Success]
				success_x := (canvas.size[0] - success.size[0]) / 2
				total_h += success.size[1] + (general_font.glyph_size[1] * 2)

				tbuf: [64]byte
				time_str := fmt.bprintf(tbuf[:32], "{}: {:02i}:{:02i}:{:02i}",
					language_strings[settings.language][.Time],
					int(time.duration_minutes(level.score.time)),
					int(time.duration_seconds(level.score.time)) % 60,
					int(time.duration_milliseconds(level.score.time)) % 60,
				)
				time_x, time_h: int
				{
					size := measure_text(general_font, time_str)
					time_x = (canvas.size[0] - size[0]) / 2
					time_h = size[1]
				}
				total_h += time_h + general_font.glyph_size[1]

				steps_str := fmt.bprintf(tbuf[32:], "{}: {}", language_strings[settings.language][.Steps], level.score.steps)
				steps_x, steps_h: int
				{
					size := measure_text(general_font, steps_str)
					steps_x = (canvas.size[0] - size[0]) / 2
					steps_h = size[1]
				}
				total_h += steps_h + (general_font.glyph_size[1] * 2)

				hint_str := language_strings[settings.language][.Press_Enter]
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
				spl.draw_from_texture(&canvas, atlas, pos, success)
				small_array.push_back(&canvas_cache, spl.Rect{pos, success.size})
				pos.y += success.size[1] + (general_font.glyph_size[1] * 2)

				small_array.push_back(&canvas_cache, draw_text(&canvas, general_font, time_str, {time_x, pos.y}))
				pos.y += time_h + general_font.glyph_size[1]

				small_array.push_back(&canvas_cache, draw_text(&canvas, general_font, steps_str, {steps_x, pos.y}))
				pos.y += steps_h + (general_font.glyph_size[1] * 2)

				small_array.push_back(&canvas_cache, draw_text(&canvas, general_font, hint_str, {hint_x, pos.y}))
			}
		}

		fade_alpha := get_fade_alpha(fade, frame_delta)
		if fade_alpha != 0 {
			spl.draw_rect(&canvas, {{}, canvas.size}, {0, 0, 0, fade_alpha})
			small_array.clear(&canvas_cache_slow)
			small_array.clear(&canvas_cache)
			small_array.push_back(&canvas_cache, spl.Rect{{}, canvas.size})
		}

		if settings.show_stats {
			small_array.push_back(&canvas_cache, draw_stats(&canvas))
		}

		sync.atomic_store(&global_state.frame_work, time.tick_since(start_tick))

		if settings.vsync {
			spl.wait_vblank()
		} else {
			spl.wait_timer(&timer)
		}

		client_size := get_from_i64(&global_state.client_size)
		scale := get_buffer_scale(client_size[0], client_size[1])
		buf_w, buf_h := BUFFER_W * scale, BUFFER_H * scale
		off_x := (cast(int)client_size[0] - buf_w) / 2
		off_y := (cast(int)client_size[1] - buf_h) / 2
		spl.display_pixels(&window, canvas, {{off_x, off_y}, {buf_w, buf_h}})

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
	current_tile := get_tile_from_pos(pos, world.level)

	#partial switch d {
	case .Right:
		if pos.x == world.level.size[0] - 1 {
			return false
		}
		pos.x += 1
	case .Left:
		if pos.x == 0 {
			return false
		}
		pos.x -= 1
	case .Down:
		if pos.y == world.level.size[1] - 1 {
			return false
		}
		pos.y += 1
	case .Up:
		if pos.y == 0 {
			return false
		}
		pos.y -= 1
	}
	tile := get_tile_from_pos(pos, world.level)

	if tile == .Grass || tile == .Fence || tile == .Egg {
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
		world.level.score.steps += 1
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

get_tile_from_pos :: #force_inline proc(pos: [2]int, level: Level) -> Tiles #no_bounds_check {
	if pos.x < 0 || pos.x >= level.size[0] || pos.y < 0 || pos.y >= level.size[1] {
		return .Grass
	}

	idx := (pos.y * level.size[0]) + pos.x
	return level.tiles[idx]
}

set_level_tile :: #force_inline proc(pos: [2]int, t: Tiles) {
	idx := (pos.y * world.level.size[0]) + pos.x
	world.level.tiles[idx] = t
}

press_red_button :: proc() {
	for tile, idx in world.level.tiles {
		pos: [2]int = {idx%world.level.size[0], idx/world.level.size[0]}
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
		pos: [2]int = {idx%world.level.size[0], idx/world.level.size[0]}
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
	scoreboard: []Score
	switch settings.campaign {
	case .Carrot_Harvest:
		scoreboard = settings.carrots_scoreboard[:]
	case .Easter_Eggs:
		scoreboard = settings.eggs_scoreboard[:]
	}

	if world.level.score.time < scoreboard[world.level.current].time || scoreboard[world.level.current].time == 0 {
		scoreboard[world.level.current].time = world.level.score.time
	}

	if world.level.score.steps < scoreboard[world.level.current].steps || scoreboard[world.level.current].steps == 0 {
		scoreboard[world.level.current].steps = world.level.score.steps
	}

	world.level.ended = true
	world.level.next = next
	last_unlocked_level := &settings.last_unlocked_levels[settings.campaign]
	if world.level.next > last_unlocked_level^ {
		last_unlocked_level^ = world.level.next
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
	original_tile := get_tile_from_pos(original_pos, world.level)
	current_tile := get_tile_from_pos(world.player, world.level)

	switch {
	case original_tile == .Trap:
		set_level_tile(original_pos, .Trap_Activated)
	case original_tile == .Egg_Spot:
		set_level_tile(original_pos, .Egg)
		world.level.eggs -= 1
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
	case current_tile in belt_tiles:
		world.player.belt = true
	case current_tile == .Red_Button:
		press_red_button()
	case current_tile == .Yellow_Button:
		press_yellow_button()
	}

	if world.level.carrots == 0 && world.level.eggs == 0 {
		world.level.can_end = true
	}

	if current_tile == .End && world.level.can_end {
		finish_level(world.level.current + 1)
	}
}

switch_scene :: proc(s: Scene) {
	if !world.fade.state {
		world.next_scene = s
		world.fade.state = true
		world.fade.timer = 0
		world.fade.frame = 0
	}
}

main_menu_continue :: proc() {
	world.level.next = settings.last_unlocked_levels[settings.campaign]
	switch_scene(.Game)
}

main_menu_new_game :: proc() {
	settings.selected_levels[settings.campaign] = 0
	settings.last_unlocked_levels[settings.campaign] = 0
	world.level.next = 0
	switch_scene(.Game)
}

main_menu_select_level :: proc() {
	world.level.next = settings.selected_levels[settings.campaign]
	switch_scene(.Game)
}

main_menu_scoreboard :: proc() {
	show_scoreboard()
}

show_credits :: proc() {
	if !world.credits.state {
		if world.scene == .End {
			world.credits.state = true
			world.credits.timer = 0
			world.credits.frame = 0
		}
		world.scene = .Credits
	}
}

show_end :: proc() {
	if !world.end.state {
		world.scene = .End
		world.end.state = true
		world.end.timer = 0
		world.end.frame = 0
	}
}

main_menu_credits :: proc() {
	switch_scene(.Credits)
}

main_menu_quit :: proc() {
	window.must_close = true
}

pause_menu_continue :: proc() {
	world.scene = .Game
}

select_level_prev :: proc() {
	settings.selected_levels[settings.campaign] -= 1
	world.keep_selected_option = true
	show_main_menu()
}

select_level_next :: proc() {
	settings.selected_levels[settings.campaign] += 1
	world.keep_selected_option = true
	show_main_menu()
}

select_campaign_prev :: proc() {
	settings.campaign -= Campaign(1)
	world.keep_selected_option = true
	show_main_menu()
}

select_campaign_next :: proc() {
	settings.campaign += Campaign(1)
	world.keep_selected_option = true
	show_main_menu()
}

select_language_prev :: proc() {
	settings.language -= Language(1)
	world.keep_selected_option = true
	show_main_menu()
}

select_language_next :: proc() {
	settings.language += Language(1)
	world.keep_selected_option = true
	show_main_menu()
}

restart_level :: proc() {
	if world.player.fading.state do return

	world.level.next = world.level.current
	if world.level.ended {
		load_level()
	} else {
		world.scene = .Game
		player_animation_start(&world.player.dying)
	}
}

pause_menu_exit :: proc() {
	world.level.next = -1
	switch_scene(.Game)
}

label_printf :: proc(label: ^Text_Label, format: string, args: ..any) {
	text := fmt.bprintf(label.text_buf[:], format, ..args)
	label.text_len = len(text)
	label.size = measure_text(general_font, text)
}

show_intro :: proc() {
	world.scene = .Intro
	world.intro.state = true
}

show_scoreboard :: proc() {
	world.scene = .Scoreboard
	small_array.clear(&world.scoreboard)

	scoreboard: []Score
	switch settings.campaign {
	case .Carrot_Harvest:
		scoreboard = settings.carrots_scoreboard[:]
	case .Easter_Eggs:
		scoreboard = settings.eggs_scoreboard[:]
	}

	world.scoreboard_page = 0
	for score, lvl in scoreboard {
		lvl_idx := lvl + 1
		label: Text_Label
		label_printf(&label, "{:02i}| {:02i}:{:02i}:{:02i}; {:02i} {}", lvl_idx,
			int(time.duration_minutes(score.time)),
			int(time.duration_seconds(score.time)) % 60,
			int(time.duration_milliseconds(score.time)) % 60,
			score.steps,
			language_strings[settings.language][.Scoreboard_Steps],
		)
		label.pos.x = (BUFFER_W - label.size[0]) / 2
		small_array.push_back(&world.scoreboard, label)
	}
}

show_main_menu :: proc() {
	world.scene = .Main_Menu
	old_len := world.menu_options.len
	small_array.clear(&world.menu_options)

	total_h: int

	last_unlocked_level := settings.last_unlocked_levels[settings.campaign]
	levels_len := len(all_levels[settings.campaign])
	if last_unlocked_level > 0 && last_unlocked_level < levels_len {
		option: Menu_Option = {func = main_menu_continue}
		label_printf(&option, language_strings[settings.language][.Continue])
		option.x = (BUFFER_W - option.size[0]) / 2
		option.y = total_h
		total_h += option.size[1]
		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	{
		option: Menu_Option = {func = main_menu_select_level}
		selected_level := settings.selected_levels[settings.campaign]
		label_printf(&option, "{}: {}", language_strings[settings.language][.Select_Level], selected_level + 1)
		total_w := option.size[0] + (RIGHT_ARROW.size[0] + SPACE_BETWEEN_ARROW_AND_TEXT) * 2
		option.x = (BUFFER_W - total_w) / 2
		option.y = total_h
		total_h += option.size[1]

		arrows: [2]struct {
			enabled: bool,
			func: proc(),
		}
		arrows[0].func = select_level_prev
		arrows[1].func = select_level_next

		if last_unlocked_level != 0 {
			if selected_level > 0 {
				arrows[0].enabled = true
			}
			if selected_level < last_unlocked_level && selected_level + 1 < levels_len {
				arrows[1].enabled = true
			}
		}
		option.arrows = arrows

		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	{
		option: Menu_Option = {func = main_menu_new_game}
		label_printf(&option, language_strings[settings.language][.New_Game])
		option.x = (BUFFER_W - option.size[0]) / 2
		option.y = total_h
		total_h += option.size[1]
		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	{
		option: Menu_Option
		label_printf(&option, "{}: {}", language_strings[settings.language][.Campaign], campaign_to_string[settings.language][settings.campaign])
		total_w := option.size[0] + (RIGHT_ARROW.size[0] + SPACE_BETWEEN_ARROW_AND_TEXT) * 2
		option.x = (BUFFER_W - total_w) / 2
		option.y = total_h
		total_h += option.size[1]

		arrows: [2]struct {
			enabled: bool,
			func: proc(),
		}
		arrows[0].func = select_campaign_prev
		arrows[1].func = select_campaign_next

		if int(settings.campaign) > 0 {
			arrows[0].enabled = true
		}
		if int(settings.campaign) < len(Campaign) - 1 {
			arrows[1].enabled = true
		}
		option.arrows = arrows

		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	{
		option: Menu_Option = {func = main_menu_scoreboard}
		label_printf(&option, language_strings[settings.language][.Scoreboard])
		option.x = (BUFFER_W - option.size[0]) / 2
		option.y = total_h
		total_h += option.size[1]
		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	when SUPPORT_LANGUAGES {
		{
			option: Menu_Option
			label_printf(&option, "{}: {}", language_strings[settings.language][.Language], language_to_string[settings.language])
			total_w := option.size[0] + (RIGHT_ARROW.size[0] + SPACE_BETWEEN_ARROW_AND_TEXT) * 2
			option.x = (BUFFER_W - total_w) / 2
			option.y = total_h
			total_h += option.size[1]

			arrows: [2]struct {
				enabled: bool,
				func: proc(),
			}
			arrows[0].func = select_language_prev
			arrows[1].func = select_language_next

			if int(settings.language) > 0 {
				arrows[0].enabled = true
			}
			if int(settings.language) < len(Language) - 1 {
				arrows[1].enabled = true
			}
			option.arrows = arrows

			small_array.push_back(&world.menu_options, option)
		}

		total_h += general_font.glyph_size[1]
	}

	// Manual?

	{
		option: Menu_Option = {func = main_menu_credits}
		label_printf(&option, language_strings[settings.language][.Credits])
		option.x = (BUFFER_W - option.size[0]) / 2
		option.y = total_h
		total_h += option.size[1]
		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	{
		option: Menu_Option = {func = main_menu_quit}
		label_printf(&option, language_strings[settings.language][.Quit])
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

	if !world.keep_selected_option {
		world.selected_option = 0
	} else { // hack if Continue button is not present in both campaigns
		world.selected_option -= old_len - world.menu_options.len
	}
	world.keep_selected_option = false
}

show_pause_menu :: proc(clear := true) {
	world.scene = .Pause_Menu
	small_array.clear(&world.menu_options)

	total_h: int
	{
		option: Menu_Option = {func = pause_menu_continue}
		label_printf(&option, language_strings[settings.language][.Continue])
		option.x = (BUFFER_W - option.size[0]) / 2
		option.y = total_h
		total_h += option.size[1]
		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	{
		option: Menu_Option = {func = restart_level}
		label_printf(&option, language_strings[settings.language][.Restart_Level])
		option.x = (BUFFER_W - option.size[0]) / 2
		option.y = total_h
		total_h += option.size[1]
		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	// Help?

	{
		option: Menu_Option = {func = pause_menu_exit}
		label_printf(&option, language_strings[settings.language][.Exit_Level])
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

	if !world.keep_selected_option do world.selected_option = 0
	world.keep_selected_option = false
}

load_level :: proc() {
	world.scene = .Game
	next := world.level.next

	if len(world.level.tiles) != 0 {
		delete(world.level.tiles)
	}

	world.player = {}
	world.level = {}

	if next < 0 {
		show_main_menu()
		return
	}

	lvl: []string

	levels := all_levels[settings.campaign]
	if next >= len(levels) {
		show_end()
		return
	}
	world.level.size[0] = len(levels[next][0])
	world.level.size[1] = len(levels[next])
	lvl = levels[next]

	world.level.current = next
	world.level.next = next
	world.level.tiles = make([]Tiles, world.level.size[0] * world.level.size[1])
	world.level.changed = true

	for row, y in lvl {
		x: int
		for char in row {
			tile := char_to_tile[char] or_else .Ground
			set_level_tile({x, y}, tile)
			#partial switch tile {
			case .Start:
				world.player.pos = {x, y}
			case .Carrot:
				world.level.carrots += 1
			case .Egg_Spot:
				world.level.eggs += 1
			}
			x += 1
		}
	}

	player_animation_start(&world.player.fading)
}

common_menu_key_handler :: proc(key: spl.Key_Code, state: bit_set[Key_State]) -> (handled: bool) {
	option := small_array.get_ptr(&world.menu_options, world.selected_option)
	arrows, has_arrows := option.arrows.?

	#partial switch key {
	case .Enter:
		handled = true
		if .Pressed in state {
			if option.func != nil {
				option.func()
			}
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
	case .Left:
		if state & {.Pressed, .Repeated} > {} {
			if has_arrows && arrows[0].enabled {
				arrows[0].func()
			}
		}
	case .Right:
		if state & {.Pressed, .Repeated} > {} {
			if has_arrows && arrows[1].enabled {
				arrows[1].func()
			}
		}
	}

	return
}

pause_menu_key_handler :: proc(key: spl.Key_Code, state: bit_set[Key_State]) {
	if common_menu_key_handler(key, state) do return

	#partial switch key {
	case .Escape:
		if .Pressed in state {
			pause_menu_continue()
		}
	}
}

main_menu_key_handler :: proc(key: spl.Key_Code, state: bit_set[Key_State]) {
	if common_menu_key_handler(key, state) do return
}

intro_key_handler :: proc(key: spl.Key_Code, state: bit_set[Key_State]) {
	if .Pressed in state {
		world.intro.state = false
		switch_scene(.Main_Menu)
	}
}

end_key_handler :: proc(key: spl.Key_Code, state: bit_set[Key_State]) {
	if .Pressed in state {
		world.end.state = false
		switch_scene(.Credits)
	}
}

credits_key_handler :: proc(key: spl.Key_Code, state: bit_set[Key_State]) {
	if .Pressed in state {
		if !world.credits.state {
			world.keep_selected_option = true
		}
		world.credits.state = false
		switch_scene(.Main_Menu)
	}
}

scoreboard_key_handler :: proc(key: spl.Key_Code, state: bit_set[Key_State]) {
	pages := ((world.scoreboard.len - 1) / 10) + 1

	if .Pressed in state {
		#partial switch key {
		case .Up:
			world.scoreboard_page -= 1
			if world.scoreboard_page < 0 {
				world.scoreboard_page += 1
			}
		case .Down:
			world.scoreboard_page += 1
			if world.scoreboard_page >= pages {
				world.scoreboard_page -= 1
			}
		case .Escape:
			world.keep_selected_option = true
			show_main_menu()
		}
	}
}

game_key_handler :: proc(key: spl.Key_Code, state: bit_set[Key_State]) {
	shift := .Held in global_state.keyboard.keys[.LShift]

	#partial switch key {
	case .Right: move_player(.Right)
	case .Left:  move_player(.Left)
	case .Down:  move_player(.Down)
	case .Up:    move_player(.Up)
	case .R:
		if .Pressed in state {
			restart_level()
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
			if !world.player.fading.state {
				show_pause_menu()
			}
		}
	case .Enter:
		if .Pressed in state {
			if world.level.ended && !world.player.fading.state {
				switch_scene(.Game)
			}
		}
	}
}

update_game :: proc() {
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
		tile := get_tile_from_pos(world.player, world.level)
		#partial switch tile {
		case .Belt_Left:  move_player(.Left)
		case .Belt_Right: move_player(.Right)
		case .Belt_Down:  move_player(.Down)
		case .Belt_Up:    move_player(.Up)
		}
	}

	// track level time
	if !world.level.ended {
		world.level.score.time += sync.atomic_load(&global_state.tick_time)
	}
}

update_world :: proc(t: ^thread.Thread) {
	context.assertion_failure_proc = assertion_failure_proc
	context.logger.procedure = logger_proc

	timer: spl.Timer
	{
		ok := spl.create_timer(&timer, TPS)
		when ODIN_OS == .Windows {
			assert(ok, fmt.tprintf("{}\nAnyways, here is the error code: {}", TIMER_FAIL, spl._windows_get_last_error()))
		} else {
			assert(ok, TIMER_FAIL)
		}
	}

	when ODIN_DEBUG {
		show_main_menu()
	} else {
		show_intro()
	}

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
					case .Credits:
						credits_key_handler(key, state)
					case .Scoreboard:
						scoreboard_key_handler(key, state)
					}

					if .Repeated in state do state -= {.Repeated}
					if .Pressed in state do state -= {.Pressed}
					if .Released in state do state = {}
				}
			}

			switch world.scene {
			case .Game:
				update_game()
			case .Intro:
				if world.intro.state {
					if world.intro.timer >= INTRO_LENGTH {
						world.intro.state = false
						switch_scene(.Main_Menu)
					}

					world.intro.timer += 1
				}
			case .Credits:
				if world.credits.state {
					if world.credits.timer >= CREDITS_LENGTH {
						world.credits.state = false
						switch_scene(.Main_Menu)
					}
					world.credits.timer += 1
				}
			case .End:
				if world.end.state {
					if world.end.timer >= END_LENGTH {
						world.end.state = false
						switch_scene(.Credits)
					}
					world.end.timer += 1
				}
			case .Main_Menu, .Pause_Menu, .Scoreboard, .None:
			}

			if world.fade.state {
				if world.fade.timer >= FADE_LENGTH {
					world.fade.state = false
				}

				old_section := world.fade.timer / (FADE_LENGTH / 2)
				world.fade.timer += 1
				section := world.fade.timer / (FADE_LENGTH / 2)

				if section != old_section && old_section == 0 {
					switch world.next_scene {
					case .Game: load_level()
					case .Main_Menu: show_main_menu()
					case .Credits: show_credits()
					case .Pause_Menu: show_pause_menu()
					case .End: show_end()
					case .Scoreboard: show_scoreboard()
					case .Intro: show_intro()
					case .None: world.scene = world.next_scene
					}
				}
			}

			global_state.previous_tick = time.tick_now()
		}

		sync.atomic_store(&global_state.tick_work, time.tick_since(start_tick))

		spl.wait_timer(&timer)

		sync.atomic_store(&global_state.tick_time, time.tick_since(start_tick))
	}
}

load_texture :: proc(data: []byte) -> (t: spl.Texture2D) {
	img, err := image.load(data)
	assert(err == nil, fmt.tprint(err))
	defer image.destroy(img)

	t = spl.texture_make(img.width, img.height)

	pixels := mem.slice_data_cast([]image.RGBA_Pixel, bytes.buffer_to_bytes(&img.pixels))
	for p, i in pixels {
		t.pixels[i] = spl.color(p)
	}
	return
}

load_resources :: proc() {
	general_font.texture = load_texture(#load("../res/font.png"))
	general_font.glyph_size = {5, 7}
	general_font.table = make(map[rune][2]int)
	for ch in ` 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ?'".,:;~!@#$^&_|\/%*+-=<>()[]{}` {
		glyph_idx := len(general_font.table)
		gx := (glyph_idx % (general_font.size[0] / general_font.glyph_size[0])) * general_font.glyph_size[0]
		gy := (glyph_idx / (general_font.size[0] / general_font.glyph_size[0])) * general_font.glyph_size[1]
		general_font.table[ch] = {gx, gy}
	}
	when SUPPORT_LANGUAGES {
		for ch in `бБвВгГґҐдДєЄжЖзЗиИїЇйЙкКлЛмнпПтуУфФцЦчЧшШщЩьЬюЮяЯ` {
			glyph_idx := len(general_font.table)
			gx := (glyph_idx % (general_font.size[0] / general_font.glyph_size[0])) * general_font.glyph_size[0]
			gy := (glyph_idx / (general_font.size[0] / general_font.glyph_size[0])) * general_font.glyph_size[1]
			general_font.table[ch] = {gx, gy}
		}
		// Cyrillic from Latin equivalents
		general_font.table['а'] = general_font.table['a']
		general_font.table['А'] = general_font.table['A']
		general_font.table['е'] = general_font.table['e']
		general_font.table['Е'] = general_font.table['E']
		general_font.table['і'] = general_font.table['i']
		general_font.table['І'] = general_font.table['I']
		general_font.table['о'] = general_font.table['o']
		general_font.table['О'] = general_font.table['O']
		general_font.table['с'] = general_font.table['c']
		general_font.table['С'] = general_font.table['C']
		general_font.table['р'] = general_font.table['p']
		general_font.table['Р'] = general_font.table['P']
		general_font.table['х'] = general_font.table['x']
		general_font.table['Х'] = general_font.table['X']

		// partial equivalents
		general_font.table['М'] = general_font.table['M']
		general_font.table['Н'] = general_font.table['H']
		general_font.table['Т'] = general_font.table['T']
	}

	atlas = load_texture(#load("../res/atlas.png"))

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

	ATLAS_TILES_W :: 12
	for s in Sprites {
		idx := int(s)
		pos: [2]int = {idx%ATLAS_TILES_W, idx/ATLAS_TILES_W}
		sprites[s] = {pos * TILE_SIZE, {TILE_SIZE, TILE_SIZE}}
	}

	splashes = load_texture(#load("../res/splashes.png"))
	logo = load_texture(#load("../res/logo.png"))
}

_main :: proc(allocator: runtime.Allocator) {
	context.assertion_failure_proc = assertion_failure_proc
	context.logger.procedure = logger_proc

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

	pos: [2]int
	size: [2]int = {WINDOW_W, WINDOW_H}
	{ // center the window
		wr := spl.get_working_area()
		pos = wr.pos + ((wr.size / 2) - (size / 2))
	}

	// Open window
	assert(spl.create(&window, pos, size, GAME_TITLE, {.Hide_Cursor}), "Failed to create window")
	defer spl.destroy(&window)

	spl.set_resizable(&window, true)
	spl.set_min_size(&window, {BUFFER_W, BUFFER_H})

	save_to_i64(&global_state.client_size, {i32(window.client.size[0]), i32(window.client.size[1])})

	scheduler_precise: bool
	if !spl.has_precise_timer() {
		scheduler_precise = true
		spl.make_scheduler_precise()
	}

	defer if scheduler_precise {
		spl.restore_scheduler()
	}

	update_thread := thread.create_and_start(fn = update_world, priority = .High)
	defer {
		thread.terminate(update_thread, 0)
		thread.destroy(update_thread)
	}

	render_thread := thread.create_and_start(fn = render, priority = .High)
	defer {
		thread.terminate(render_thread, 0)
		thread.destroy(render_thread)
	}

	for !window.must_close {
		switch ev in spl.next_event(&window) {
		case spl.Close_Event:
		case spl.Focus_Event:
			if !ev.focused {
				sync.guard(&global_state.keyboard.lock)
				for state in &global_state.keyboard.keys {
					// release all pressed keys
					if .Held in state {
						state = {.Released}
					}
				}
			}
		case spl.Draw_Event:
		case spl.Resize_Event:
			save_to_i64(&global_state.client_size, {i32(window.client.size[0]), i32(window.client.size[1])})
		case spl.Move_Event:
		case spl.Character_Event:
		case spl.Keyboard_Event:
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
				case .I: settings.show_stats = !settings.show_stats
				case .B: settings = default_settings
				}
			}
		case spl.Mouse_Button_Event:
		case spl.Mouse_Move_Event:
		case spl.Mouse_Wheel_Event:
		}
	}

	// NOTE: this will only trigger on a proper quit, not on task termination
	{
		data, err := json.marshal(settings, {pretty = true}, allocator)
		assert(err == nil, fmt.tprint("Unable to save the game:", err))

		ok := os.write_entire_file(settings_location, data)
		assert(ok, fmt.tprint("Unable to save the game"))
	}
}

/*
TODO:
complete egg campaign
add manual?
*/
