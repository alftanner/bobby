package main

import "core:time"
import "core:thread"
import "core:sync"
import "core:runtime"
import "core:container/small_array"
import "core:image"
import _ "core:image/png"
import "core:bytes"
import "core:os"
import "core:os/os2"
import "core:path/filepath"
import "core:mem"
import "core:math"
import "core:math/linalg"
import "core:fmt"
import "core:encoding/json"

import spl "spl"

GAME_TITLE :: "Bobby Carrot Remastered"
TIMER_FAIL :: "Failed to create a timer. I would use sleep() instead, but @mmozeiko said that sleeping is bad."

Rect :: struct {
	using pos: [2]int,
	size: [2]int,
}

Renderer :: enum {
	GL,
	Software,
}

Score :: struct {
	time: f32, // in milliseconds
	steps: int,
}

Settings :: struct {
	fps: uint,
	vsync: bool,
	show_stats: bool,
	renderer: Renderer,

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
CANVAS_SIZE :: [2]int{BUFFER_W, BUFFER_H}
DEFAULT_SCALE :: 3
WINDOW_W :: BUFFER_W * DEFAULT_SCALE
WINDOW_H :: BUFFER_H * DEFAULT_SCALE

Textures :: enum {
	General_Font,
	Atlas,
	Splashes,
	Logo,
	Grass,
	Ground,
}
textures: [Textures]Texture2D
manu_campaign_textures: [Campaign]Textures = {
	.Carrot_Harvest = .Grass,
	.Easter_Eggs = .Ground,
}

Font :: struct {
	texture: Textures,
	table: map[rune][2]int,
	glyph_size: [2]int,
}
general_font: Font
hud_font: Font

Direction :: enum {
	None,
	Right,
	Left,
	Down,
	Up,
}

Sprite_Offset :: struct {
	using rect: Rect,
	offset: [2]int,
}

Text_Label :: struct {
	using rect: Rect,
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
Region_Cache :: small_array.Small_Array(512, Rect)
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
	scene: Scene,
	next_scene: Scene,

	fade, intro, end, credits: Animation,

	menu_options: Menu_Options,
	selected_option: int,
	keep_selected_option: bool,

	scoreboard: Scoreboard,
	scoreboard_page: int,

	player: Player,
}
world: World
world_updated: bool
world_lock: sync.Mutex
world_level: Level

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
	max_texture_size: i32,

	// _work shows how much time was spent on actual work in that frame before sleep
	// _time shows total time of the frame, sleep included
	frame_work, frame_time: time.Duration,
	tick_work, tick_time: time.Duration,
	last_update, last_frame, fps, tps: Average_Calculator,

	previous_tick: time.Tick,
	loaded_resources: bool,

	keyboard: Keyboard_State,

	finish_rendering: bool,
	renderer_fallback: bool,
}
global_state: State

window: spl.Window

SPACE_BETWEEN_ARROW_AND_TEXT :: 3
RIGHT_ARROW :: Rect{{183, 115}, {5, 9}}
UP_ARROW :: Rect{{183, 125}, {9, 5}}
INTRO_SPLASH :: Rect{{0, 0}, {128, 128}}
END_SPLASH :: Rect{{0, 128}, {128, 128}}

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

sprites: [Sprites]Rect

HUD_Sprites :: enum {
	Carrot,
	Egg,
	Eyes,
	Silver_Key,
	Golden_Key,
	Copper_Key,
	Success,
}

hud_sprites: [HUD_Sprites]Rect = {
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

end_animation := [?]Rect {
	{{64,  80}, {16, 16}},
	{{80,  80}, {16, 16}},
	{{96,  80}, {16, 16}},
	{{112, 80}, {16, 16}},
}
belt_animation := [?]Rect {
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

array_cast :: linalg.array_cast

fract :: proc(x: f32) -> f32 {
	if x >= 0 {
		return x - #force_inline math.trunc(x)
	}
	return #force_inline math.trunc(-x) + x
}

measure_or_draw_text :: proc(
	renderer: Renderer,
	t: ^Texture2D,
	font: Font,
	text: string,
	pos: [2]int,
	color: image.RGB_Pixel,
	shadow_color: image.RGB_Pixel,
	no_draw := false,
) -> (region: Rect) {
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
			switch renderer {
			case .Software:
				software_draw_from_texture(t, pos + 1, textures[font.texture], {glyph_pos, font.glyph_size}, {}, shadow_color)
				software_draw_from_texture(t, pos, textures[font.texture], {glyph_pos, font.glyph_size}, {}, color)
			case .GL:
				gl_draw_from_texture(pos + 1, font.texture, {glyph_pos, font.glyph_size}, {}, shadow_color)
				gl_draw_from_texture(pos, font.texture, {glyph_pos, font.glyph_size}, {}, color)
			}
		}

		pos.x += font.glyph_size[0] + 1
		region.size[0] = max(region.size[0], pos.x - region.x)
	}
	region.size[1] = pos.y - region.y + font.glyph_size[1] + 1

	return
}

measure_text :: #force_inline proc(font: Font, text: string) -> [2]int {
	region := measure_or_draw_text(.Software, nil, font, text, {}, {}, {}, true)
	return region.size
}

calculate_stats :: proc() {
	@static time_waited: time.Duration

	avg_add(&global_state.last_update, time.duration_milliseconds(sync.atomic_load(&global_state.tick_work)))
	avg_add(&global_state.last_frame, time.duration_milliseconds(sync.atomic_load(&global_state.frame_work)))
	avg_add(&global_state.tps, 1000/time.duration_milliseconds(sync.atomic_load(&global_state.tick_time)))
	avg_add(&global_state.fps, 1000/time.duration_milliseconds(sync.atomic_load(&global_state.frame_time)))

	// DEBUG: see every frame time individually
	//fmt.println(1000/time.duration_milliseconds(sync.atomic_load(&global_state.frame_time)))

	@static tick: time.Tick
	time_waited += time.tick_lap_time(&tick)
	if time_waited >= 50 * time.Millisecond {
		time_waited = 0
		avg_calculate(&global_state.last_update)
		avg_calculate(&global_state.last_frame)
		avg_calculate(&global_state.tps)
		avg_calculate(&global_state.fps)
	}
}

get_fade_alpha :: proc(fade: Animation, frame_delta: f32) -> u8 {
	if !fade.state do return 0

	SECTION_LENGTH :: FADE_LENGTH / 2

	section := fade.timer / SECTION_LENGTH
	time_in_section := f32(fade.timer % SECTION_LENGTH)

	delta := (time_in_section + frame_delta) / SECTION_LENGTH

	alpha: u8
	switch section {
	case 0: // fade-out 0-255
		alpha = u8(clamp(delta * 255, 0, 255))
	case 1: // fade-in 255-0
		alpha = 255 - u8(clamp(delta * 255, 0, 255))
	case:
		alpha = 0
	}

	return alpha
}

get_intro_alpha :: proc(intro: Animation, frame_delta: f32) -> u8 {
	SECTION_LENGTH :: FADE_LENGTH

	section := intro.timer / SECTION_LENGTH
	time_in_section := f32(intro.timer % SECTION_LENGTH)

	delta := (time_in_section + frame_delta) / SECTION_LENGTH

	alpha: u8
	switch section {
	case 0: // fade-in 255-0
		alpha = 255 - u8(clamp(delta * 255, 0, 255))
	case:
		alpha = 0
	}

	return alpha
}

interpolate_tile_position :: #force_inline proc(p: Player, frame_delta: f32) -> [2]f32 {
	if p.walking.state || p.walking.timer != 0 {
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

get_sprite_from_pos :: proc(pos: [2]int, level: Level) -> Rect {
	tile := get_tile_from_pos(pos, level)
	sprite := sprites[.Ground]

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

load_texture :: proc(data: []byte) -> (t: Texture2D) {
	img, err := image.load(data)
	assert(err == nil, fmt.tprint(err))
	defer image.destroy(img)

	t = texture_make(img.width, img.height)

	pixels := mem.slice_data_cast([]image.RGBA_Pixel, bytes.buffer_to_bytes(&img.pixels))
	for p, i in pixels {
		t.pixels[i].rgb = platform_color(p.rgb)
		t.pixels[i].a = p.a
	}

	return
}

load_textures :: proc() {
	textures[.General_Font] = load_texture(#load("../res/font.png"))
	textures[.Atlas] = load_texture(#load("../res/atlas.png"))
	textures[.Splashes] = load_texture(#load("../res/splashes.png"))
	textures[.Logo] = load_texture(#load("../res/logo.png"))
	textures[.Grass] = load_texture(#load("../res/grass.png"))
	textures[.Ground] = load_texture(#load("../res/ground.png"))

	general_font.texture = .General_Font
	general_font.glyph_size = {5, 7}
	general_font.table = make(map[rune][2]int)
	for ch in ` 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ?'".,:;~!@#$^&_|\/%*+-=<>()[]{}` {
		glyph_idx := len(general_font.table)
		gx := (glyph_idx % (textures[.General_Font].size[0] / general_font.glyph_size[0])) * general_font.glyph_size[0]
		gy := (glyph_idx / (textures[.General_Font].size[0] / general_font.glyph_size[0])) * general_font.glyph_size[1]
		general_font.table[ch] = {gx, gy}
	}
	when SUPPORT_LANGUAGES {
		for ch in `бБвВгГґҐдДєЄжЖзЗиИїЇйЙкКлЛмнпПтуУфФцЦчЧшШщЩьЬюЮяЯ` {
			glyph_idx := len(general_font.table)
			gx := (glyph_idx % (textures[.General_Font].size[0] / general_font.glyph_size[0])) * general_font.glyph_size[0]
			gy := (glyph_idx / (textures[.General_Font].size[0] / general_font.glyph_size[0])) * general_font.glyph_size[1]
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

	hud_font.texture = .Atlas
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

	for t in &textures do for p in &t.pixels {
		a_f32 := f32(p.a) / 255
		p.r = u8(f32(p.r) * a_f32)
		p.g = u8(f32(p.g) * a_f32)
		p.b = u8(f32(p.b) * a_f32)
	}
}

copy_level :: proc(dst, src: ^Level, q: ^Tile_Queue) -> (changed: bool) {
	if src.changed {
		src.changed = false
		changed = true

		if len(dst.tiles) > 0 {
			delete(dst.tiles)
		}
		dst.size = world_level.size
		dst.tiles = make([]Tiles, dst.size[0] * dst.size[1])
	}

	dst.current = src.current
	dst.next = src.next
	dst.animation = src.animation
	dst.carrots = src.carrots
	dst.eggs = src.eggs
	dst.can_end = src.can_end
	dst.ended = src.ended
	dst.score = src.score

	if q == nil {
		copy(dst.tiles, src.tiles)
	} else {
		for tile, idx in src.tiles {
			old_tile := dst.tiles[idx]
			dst.tiles[idx] = tile

			if old_tile != tile || tile in belt_tiles || (tile == .End && dst.can_end) {
				small_array.push_back(q, idx)
			}
		}
	}

	return
}

get_frame_delta :: proc(previous_tick: time.Tick) -> f32 {
	TICK_TIME :: 1000/f32(TPS)

	return f32(time.duration_milliseconds(time.tick_diff(previous_tick, time.tick_now()))) / TICK_TIME
}

render :: proc(t: ^thread.Thread) {
	context.assertion_failure_proc = assertion_failure_proc
	context.logger.procedure = logger_proc

	timer: spl.Timer
	ok := spl.create_timer(&timer, settings.fps)
	when ODIN_OS == .Windows {
		assert(ok, fmt.tprintf("{} Anyways, here is the error code: {}", TIMER_FAIL, spl._windows_get_last_error()))
	} else {
		assert(ok, TIMER_FAIL)
	}

	load_textures()
	sync.atomic_store(&global_state.loaded_resources, true)

	finish_renderer := proc(r: Renderer) {
		#partial switch r {
		case .GL: gl_render_finish()
		}
	}

	was_init: [Renderer]bool
	last_renderer := settings.renderer
	for {
		renderer := settings.renderer
		if last_renderer != renderer {
			finish_renderer(last_renderer)
			was_init[renderer] = false
		}
		last_renderer = renderer

		switch renderer {
		case .Software:
			software_render(&timer, was_init[renderer])
		case .GL:
			gl_render(&timer, was_init[renderer])
		}
		was_init[renderer] = true

		if sync.atomic_load(&global_state.finish_rendering) {
			break
		}
	}

	finish_renderer(last_renderer)

	sync.atomic_store(&global_state.finish_rendering, false)
}

can_move :: proc(pos: [2]int, d: Direction) -> bool {
	pos := pos
	current_tile := get_tile_from_pos(pos, world_level)

	#partial switch d {
	case .Right:
		if pos.x == world_level.size[0] - 1 {
			return false
		}
		pos.x += 1
	case .Left:
		if pos.x == 0 {
			return false
		}
		pos.x -= 1
	case .Down:
		if pos.y == world_level.size[1] - 1 {
			return false
		}
		pos.y += 1
	case .Up:
		if pos.y == 0 {
			return false
		}
		pos.y -= 1
	}
	tile := get_tile_from_pos(pos, world_level)

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
		world_level.score.steps += 1
	}
}

move_player :: #force_inline proc(d: Direction) {
	if world_level.ended || world.player.dying.state || world.player.fading.state || world.player.walking.state {
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
	idx := (pos.y * world_level.size[0]) + pos.x
	world_level.tiles[idx] = t
}

press_red_button :: proc() {
	for tile, idx in world_level.tiles {
		pos: [2]int = {idx%world_level.size[0], idx/world_level.size[0]}
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
	for tile, idx in world_level.tiles {
		pos: [2]int = {idx%world_level.size[0], idx/world_level.size[0]}
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

	if world_level.score.time < scoreboard[world_level.current].time || scoreboard[world_level.current].time == 0 {
		scoreboard[world_level.current].time = world_level.score.time
	}

	if world_level.score.steps < scoreboard[world_level.current].steps || scoreboard[world_level.current].steps == 0 {
		scoreboard[world_level.current].steps = world_level.score.steps
	}

	world_level.ended = true
	world_level.next = next
	last_unlocked_level := &settings.last_unlocked_levels[settings.campaign]
	if world_level.next > last_unlocked_level^ {
		last_unlocked_level^ = world_level.next
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
	original_tile := get_tile_from_pos(original_pos, world_level)
	current_tile := get_tile_from_pos(world.player, world_level)

	switch {
	case original_tile == .Trap:
		set_level_tile(original_pos, .Trap_Activated)
	case original_tile == .Egg_Spot:
		set_level_tile(original_pos, .Egg)
		world_level.eggs -= 1
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
		world_level.carrots -= 1
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

	if world_level.carrots == 0 && world_level.eggs == 0 {
		world_level.can_end = true
	}

	if current_tile == .End && world_level.can_end {
		finish_level(world_level.current + 1)
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
	world_level.next = settings.last_unlocked_levels[settings.campaign]
	switch_scene(.Game)
}

main_menu_new_game :: proc() {
	settings.selected_levels[settings.campaign] = 0
	settings.last_unlocked_levels[settings.campaign] = 0
	world_level.next = 0
	switch_scene(.Game)
}

main_menu_select_level :: proc() {
	world_level.next = settings.selected_levels[settings.campaign]
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

select_renderer_prev :: proc() {
	settings.renderer -= Renderer(1)
	world.keep_selected_option = true
	show_main_menu()
}

select_renderer_next :: proc() {
	settings.renderer += Renderer(1)
	world.keep_selected_option = true
	show_main_menu()
}

restart_level :: proc() {
	if world.player.fading.state do return

	world_level.next = world_level.current
	if world_level.ended {
		load_level()
	} else {
		world.scene = .Game
		player_animation_start(&world.player.dying)
	}
}

pause_menu_exit :: proc() {
	world_level.next = -1
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

		milliseconds := score.time
		seconds := milliseconds / 1000
		minutes := seconds / 60

		label_printf(&label, "{:02i}| {:02i}:{:02i}:{:03i}; {:02i} {}", lvl_idx,
			int(minutes),
			int(seconds) % 60,
			int(milliseconds) % 1000,
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

	if last_unlocked_level > 0 {
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

	{
		option: Menu_Option
		label_printf(&option, "{}: {}", language_strings[settings.language][.Renderer], renderer_to_string[settings.language][settings.renderer])
		total_w := option.size[0] + (RIGHT_ARROW.size[0] + SPACE_BETWEEN_ARROW_AND_TEXT) * 2
		option.x = (BUFFER_W - total_w) / 2
		option.y = total_h
		total_h += option.size[1]

		arrows: [2]struct {
			enabled: bool,
			func: proc(),
		}
		arrows[0].func = select_renderer_prev
		arrows[1].func = select_renderer_next

		if int(settings.renderer) > 0 {
			arrows[0].enabled = true
		}
		if int(settings.renderer) < len(Renderer) - 1 {
			arrows[1].enabled = true
		}
		option.arrows = arrows

		small_array.push_back(&world.menu_options, option)
	}

	total_h += general_font.glyph_size[1]

	// TODO: Manual?

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

	// TODO: Help?

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
	next := world_level.next

	if len(world_level.tiles) != 0 {
		delete(world_level.tiles)
	}

	world.player = {}
	world_level = {}

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
	world_level.size[0] = len(levels[next][0])
	world_level.size[1] = len(levels[next])
	lvl = levels[next]

	world_level.current = next
	world_level.next = next
	world_level.tiles = make([]Tiles, world_level.size[0] * world_level.size[1])
	world_level.changed = true

	for row, y in lvl {
		x: int
		for char in row {
			tile := char_to_tile[char] or_else .Ground
			set_level_tile({x, y}, tile)
			#partial switch tile {
			case .Start:
				world.player.pos = {x, y}
			case .Carrot:
				world_level.carrots += 1
			case .Egg_Spot:
				world_level.eggs += 1
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
	#partial switch key {
	case .Right: move_player(.Right)
	case .Left:  move_player(.Left)
	case .Down:  move_player(.Down)
	case .Up:    move_player(.Up)
	case .R:
		if .Pressed in state {
			restart_level()
		}
	case .Escape:
		if .Pressed in state {
			if !world.player.fading.state {
				show_pause_menu()
			}
		}
	case .Enter:
		if .Pressed in state {
			if world_level.ended && !world.player.fading.state {
				switch_scene(.Game)
			}
		}
	}

	when ODIN_DEBUG {
		shift := .Held in global_state.keyboard.keys[.LShift]
		#partial switch key {
		case .F:
			if !world.player.fading.state {
				finish_level(world_level.current + (1 if !shift else -1))
			}
		case .S:
			if !world.player.fading.state {
				world_level.next += (1 if !shift else -1)
				load_level()
			}
		}
	}
}

update_game :: proc() {
	// animations
	switch {
	case world.player.fading.state:
		world.player.fading.frame = world.player.fading.timer / FADING_ANIM_FRAME_LEN

		if world.player.fading.frame < len(fading_animation) {
			if world_level.current == world_level.next {
				// reverse frames when spawning
				world.player.fading.frame = len(fading_animation) - 1 - world.player.fading.frame
			}
			world.player.sprite = fading_animation[world.player.fading.frame]

			world.player.fading.timer += 1
		} else {
			world.player.fading.state = false
			world.player.fading.timer = 0
			world.player.fading.frame = 0
		}
	case world.player.dying.state:
		world.player.dying.frame = world.player.dying.timer / DYING_ANIM_FRAME_LEN

		if world.player.dying.frame < len(dying_animation) {
			world.player.sprite = dying_animation[world.player.dying.frame]

			world.player.dying.timer += 1
		} else {
			if world.player.dying.timer - (len(dying_animation) * DYING_ANIM_FRAME_LEN) < LAYING_DEAD_TIME {
				world.player.dying.timer += 1
			} else {
				world.player.dying.state = false
				world.player.dying.timer = 0
				world.player.dying.frame = 0
				load_level()
			}
		}
	case world.player.walking.state:
		world.player.walking.frame = world.player.walking.timer / WALKING_ANIM_FRAME_LEN

		if world.player.walking.frame + 1 < WALKING_ANIM_LEN {
			if world.player.belt {
				world.player.sprite = get_walking_sprite(0)
			} else {
				world.	player.sprite = get_walking_sprite(world.player.walking.frame + 1)
			}

			world.player.walking.timer += 1
		} else {
			world.player.walking.state = false
			world.player.walking.timer = 0
			world.player.walking.frame = 0
			move_player_to_tile(world.player.direction)
		}
	case world.player.idle.state:
		world.player.idle.frame = world.player.idle.timer / IDLE_ANIM_FRAME_LEN

		world.player.idle.frame %= len(idle_animation)
		world.player.sprite = idle_animation[world.player.idle.frame]

		world.player.idle.timer += 1
	case !world_level.ended:
		world.player.sprite = get_walking_sprite(0)

		if world.player.idle.timer > IDLING_TIME {
			player_animation_start(&world.player.idle)
		}

		world.player.idle.timer += 1
	}

	world_level.animation.frame = world_level.animation.timer / LEVEL_ANIM_FRAME_LEN
	world_level.animation.frame %= len(end_animation) // all persistent animations have the same amount of frames
	world_level.animation.timer += 1

	// belts
	if world.player.belt {
		tile := get_tile_from_pos(world.player, world_level)
		#partial switch tile {
		case .Belt_Left:  move_player(.Left)
		case .Belt_Right: move_player(.Right)
		case .Belt_Down:  move_player(.Down)
		case .Belt_Up:    move_player(.Up)
		}
	}

	// track level time
	if !world_level.ended {
		world_level.score.time += 1000/f32(TPS)
	}
}

update_world :: proc(t: ^thread.Thread) {
	context.assertion_failure_proc = assertion_failure_proc
	context.logger.procedure = logger_proc

	for !sync.atomic_load(&global_state.loaded_resources) {}

	when ODIN_DEBUG {
		show_main_menu()
	} else {
		show_intro()
	}

	timer: spl.Timer
	{
		ok := spl.create_timer(&timer, TPS)
		when ODIN_OS == .Windows {
			assert(ok, fmt.tprintf("{}\nAnyways, here is the error code: {}", TIMER_FAIL, spl._windows_get_last_error()))
		} else {
			assert(ok, TIMER_FAIL)
		}
	}

	for {
		start_tick := time.tick_now()

		{
			sync.guard(&world_lock)
			defer sync.atomic_store(&world_updated, true)

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

			if sync.atomic_load(&global_state.renderer_fallback) {
				settings.renderer = .Software
				world.keep_selected_option = true
				show_main_menu()
				sync.atomic_store(&global_state.renderer_fallback, false)
			}

			global_state.previous_tick = time.tick_now()
		}

		sync.atomic_store(&global_state.tick_work, time.tick_since(start_tick))

		spl.wait_timer(&timer)

		sync.atomic_store(&global_state.tick_time, time.tick_since(start_tick))
	}
}

get_buffer_scale :: proc(client_size: [2]uint) -> uint {
	scale := uint(1)
	for {
		scale += 1
		if BUFFER_W * scale > client_size[0] || BUFFER_H * scale > client_size[1] {
			scale -= 1
			break
		}
	}

	return scale
}

_main :: proc(allocator: runtime.Allocator) {
	context.assertion_failure_proc = assertion_failure_proc
	context.logger.procedure = logger_proc

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

	assert(spl.create(&window, GAME_TITLE, .Centered, [2]uint{WINDOW_W, WINDOW_H}), "Failed to create window")
	defer spl.destroy(&window)

	spl.set_resizable(&window, true)
	spl.set_min_size(&window, {BUFFER_W, BUFFER_H})

	save_to_i64(&global_state.client_size, {i32(window.client_size[0]), i32(window.client_size[1])})

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
					if .Held in state do state = {.Released}
				}
			}
		case spl.Draw_Event:
		case spl.Resize_Event:
			save_to_i64(&global_state.client_size, {i32(window.client_size[0]), i32(window.client_size[1])})
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
			when ODIN_DEBUG {
				if ev.state == .Pressed {
					#partial switch ev.key {
					case .I: settings.show_stats = !settings.show_stats
					}
				}
			}
		case spl.Mouse_Button_Event:
		case spl.Mouse_Move_Event:
		case spl.Mouse_Wheel_Event:
		case spl.User_Event:
		}
	}

	sync.atomic_store(&global_state.finish_rendering, true)
	for sync.atomic_load(&global_state.finish_rendering) {}

	// NOTE: this will only trigger on a proper quit, not on task termination
	{
		data, err := json.marshal(settings, {pretty = true}, allocator)
		assert(err == nil, fmt.tprint("Unable to save the game:", err))

		ok := os.write_entire_file(settings_location, data)
		assert(ok, fmt.tprint("Unable to save the game"))
	}
}
