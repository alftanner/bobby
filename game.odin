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
	fps, tps: int,
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

TPS_SECOND :: default_settings.tps
MOVE_FRAMES :: TPS_SECOND / 2
IDLE_FRAMES :: TPS_SECOND * 2
TILE_SIZE :: 16

Sprite :: struct {
	using rect: swin.Rect,
	origin: [2]int,
}

Pos :: struct {
	using pos: [2]int,
	prev: [2]int,
}

Player :: struct {
	using position: Pos,
	is_dead: bool,

	sprite: Sprite,

	direction: Direction,
	moving: bool,
	moving_timer: int,

	idle: bool,
	idle_timer: int,
}

World :: struct {
	updated: bool,
	lock: sync.Mutex,

	player: Player,
	menu: bool,

	level: int,
	level_map: []string,
}
world: World = {
	menu = false,
	level_map = levels[0],
	player = {
		direction = .Down,
		sprite = idle_animation[0],
	},
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
	Spikes,
	Spikes_Activated,
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
	Spikes,
	Spikes_Activated,
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

idle_animation := [?]Sprite {
	{{0,  96, 18, 25}, {-1, 7}},
	{{18, 96, 18, 25}, {-1, 7}},
	{{36, 96, 18, 25}, {-1, 7}},
}

walk_animation := [?]Sprite {
	{{0,   121, 18, 25}, {-1, 7}},
	{{18,  121, 18, 25}, {-1, 7}},
	{{36,  121, 18, 25}, {-1, 7}},
	{{54,  121, 18, 25}, {-1, 7}},
	{{72,  121, 18, 25}, {-1, 7}},
	{{90,  121, 18, 25}, {-1, 7}},
	{{108, 121, 18, 25}, {-1, 7}},
	{{126, 121, 18, 25}, {-1, 7}},
}
IDLE_FRAME :: 3

char_to_tile: map[rune]Tiles = {
	'.' = .Grass,
	' ' = .Ground,
	's' = .Start,
	'e' = .End,
	'c' = .Carrot,
	'-' = .Fence,
}

levels: [][]string = {
	{
		"..   ..",
		"   e   ",
		" ----- ",
		" -ccc- ",
		" -ccc- ",
		" -ccc- ",
		" -- -- ",
		"       ",
		"   s   ",
		"..   ..",
	},
}

save_2_ints :: #force_inline proc(p: ^i64, a, b: i32) {
	sync.atomic_store(p, transmute(i64)[2]i32{a, b})
}

get_2_ints :: #force_inline proc(p: ^i64) -> (i32, i32) {
	return expand_to_tuple(transmute([2]i32)sync.atomic_load(p))
}

limit_frame :: proc(frame_time: time.Duration, frame_limit: int, accurate := true) {
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
	if p.moving {
		frame_len := 1/f32(MOVE_FRAMES)
		pos := f32(p.moving_timer) * frame_len
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

	client_w, client_h := get_2_ints(&global_state.client_size)
	canvas := swin.texture_make(int(client_w), int(client_h))

	tiles_w := int(math.ceil(f32(client_w) / TILE_SIZE))
	tiles_h := int(math.ceil(f32(client_h) / TILE_SIZE))
	menu_bg := swin.texture_make(tiles_w*TILE_SIZE, tiles_h*TILE_SIZE)
	for y in 0..<tiles_h do for x in 0..<tiles_w {
		swin.draw_from_texture(&menu_bg, atlas, x*TILE_SIZE, y*TILE_SIZE, sprites[.Grass])
	}

	clear_color := swin.color(expand_to_tuple(SKY_BLUE))

	for {
		start_tick := time.tick_now()

		client_w, client_h = get_2_ints(&global_state.client_size)
		if int(client_w) != canvas.w || int(client_h) != canvas.h {
			swin.texture_destroy(canvas)
			canvas = swin.texture_make(int(client_w), int(client_h))

			tiles_w = int(math.ceil(f32(client_w) / TILE_SIZE))
			tiles_h = int(math.ceil(f32(client_h) / TILE_SIZE))
			swin.texture_destroy(menu_bg)
			menu_bg = swin.texture_make(tiles_w*TILE_SIZE, tiles_h*TILE_SIZE)
			for y in 0..<tiles_h do for x in 0..<tiles_w {
				swin.draw_from_texture(&menu_bg, atlas, x*TILE_SIZE, y*TILE_SIZE, sprites[.Grass])
			}
		}

		if sync.atomic_load(&world.updated) {
			sync.guard(&world.lock)

			// save the world state
			draw_player = world.player
			previous_tick = global_state.previous_tick
			tick_time = sync.atomic_load(&global_state.tick_time)

			sync.atomic_store(&world.updated, false)
		}

		// draw the world
		if sync.atomic_load(&world.menu) {
			swin.draw_from_texture(&canvas, menu_bg, 0, 0, {0, 0, canvas.w, canvas.h})
			swin.draw_from_texture(&canvas, atlas, 50, 50, {0, 273, 128, 128})
		} else {
			slice.fill(canvas.pixels, clear_color)

			for row, y in world.level_map do for char, x in row {
				tile := char_to_tile[char] or_else .Ground

				sprite: Sprite = sprites[.Ground]
				#partial switch tile {
				case .Grass: sprite = sprites[.Grass] // TODO: grass generation
				case .Start: sprite = sprites[.Start]
				case .End: sprite = sprites[.End]
				case .Fence: sprite = sprites[.Fence_Right]
				case .Carrot: sprite = sprites[.Carrot]
				}

				swin.draw_from_texture(&canvas, atlas, x*TILE_SIZE, y*TILE_SIZE, sprite)
			}

			player_pos := interpolate_tile_position(time.tick_diff(previous_tick, time.tick_now()), tick_time, draw_player)
			px := int(player_pos.x * TILE_SIZE) + draw_player.sprite.origin.x
			py := int(player_pos.y * TILE_SIZE) + draw_player.sprite.origin.y
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
		swin.display_pixels(window, canvas, {0, 0, canvas.w, canvas.h})

		sync.atomic_store(&global_state.frame_time, time.tick_since(start_tick))
	}
}

//TODO 16:12

move_player :: #force_inline proc(d: Direction) {
	if !world.player.moving {
		world.player.direction = d
		world.player.moving = true
	}
}

keyboard_handler :: proc(key: swin.Key_Code) {
	#partial switch key {
	case .Right: move_player(.Right)
	case .Left:  move_player(.Left)
	case .Down:  move_player(.Down)
	case .Up:    move_player(.Up)
	}

	menu := sync.atomic_load(&world.menu)
	if key == .Enter && menu {
		sync.atomic_store(&world.menu, false)
	} else if key == .Escape && !menu {
		sync.atomic_store(&world.menu, true)
	}
}

offset_walking_sprite :: proc() {
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

					keyboard_handler(key)
					if data == 2 do data = 0
				}
			}

			if !world.player.moving {
				world.player.sprite = walk_animation[IDLE_FRAME]
				offset_walking_sprite()
				world.player.idle_timer += 1
				if world.player.idle_timer > IDLE_FRAMES {
					world.player.idle = true
					// TODO: start playing idle animation
				}
			} else {
				world.player.idle_timer = 0
				world.player.moving_timer += 1
				if world.player.moving_timer == MOVE_FRAMES {
					world.player.moving_timer = 0
					world.player.moving = false
					#partial switch world.player.direction {
					case .Right: world.player.x += 1
					case .Left: world.player.x -= 1
					case .Down: world.player.y += 1
					case .Up: world.player.y -= 1
					}
				} else {
					FRAME_LEN :: f32(MOVE_FRAMES) / f32(len(walk_animation))
					current_frame := int(f32(world.player.moving_timer) / FRAME_LEN)
					world.player.sprite = walk_animation[current_frame]
					offset_walking_sprite()
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

	MAX_Y :: 12
	for s in Sprites {
		idx := int(s)
		x := idx%MAX_Y
		y := idx/MAX_Y
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
	ok := swin.create(&window, 640, 480, GAME_TITLE)
	assert(ok, "Failed to create window")
	defer swin.destroy(&window)

	{ // center the window
		wr := swin.get_working_area()
		swin.move(&window, wr.x + (wr.w/2 - window.w/2), wr.y + (wr.h/2 - window.h/2))
	}

	window.clear_color = SKY_BLUE.rgb
	window.event_handler = event_handler
	swin.set_resizable(&window, true)
	swin.set_min_size(&window, 640, 480)

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
