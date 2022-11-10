package miki

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
import "core:container/small_array"
import "core:fmt"

import swin "simple_window"

SKY_BLUE: image.RGBA_Pixel : {139, 216, 245, 255}

GLYPH_W, GLYPH_H :: 5, 7
Font :: struct {
	using texture: swin.Texture2D,
	table: map[rune]int,
}
font: Font

Direction :: enum {
	Right,
	Left,
	Up,
	Down,
}

// since settings will be saved to the file, they probably should be packed
Settings :: struct #packed {
	fps, tps: int,
	vsync: bool,
	show_stats, show_hitboxes: bool,
}
default_settings: Settings = {
	fps = 60,
	tps = 30,
	vsync = true,
	show_stats = true,
	show_hitboxes = true,
}
settings: Settings = default_settings

Pos :: struct {
	using pos: [2]f32,
	prev: [2]f32,
}

Player :: struct {
	using position: Pos,
	is_dead: bool,
}

World :: struct {
	updated: bool,
	lock: sync.Mutex,
	atlas: swin.Texture2D,

	player: Player,
}
world: World

State :: struct {
	// TODO: i128 with atomic_load/store
	client_size: i64, // stores 2 i32 values

	// _work shows how much time was spent on actual work in that frame before sleep
	// _time shows total time of the frame, sleep included
	frame_work, frame_time: time.Duration,
	tick_work, tick_time: time.Duration,
	previous_tick: time.Tick,
}
global_state: State

// NOTE: this data structure assumes 2 presses in a row are not possible
Key_Queue :: small_array.Small_Array(20, bool) // probably no human can press and release the same button more than 20 times a second
key_data: [swin.Key_Code]Key_Queue
key_data_lock: sync.Mutex

save_client_size :: #force_inline proc(width, height: int) {
	sync.atomic_store(&global_state.client_size, transmute(i64)[2]i32{i32(width), i32(height)})
}

get_client_size :: #force_inline proc() -> (int, int) {
	size := transmute([2]i32)sync.atomic_load(&global_state.client_size)
	return int(size[0]), int(size[1])
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

interpolate_position :: #force_inline proc (frame_pos, frame_len: time.Duration, pos: Pos) -> [2]f32 {
	ix := pos.prev.x + f32(frame_pos) * ((pos.x - pos.prev.x)/f32(frame_len))
	iy := pos.prev.y + f32(frame_pos) * ((pos.y - pos.prev.y)/f32(frame_len))
	return {ix, iy}
}

render :: proc(window: ^swin.Window) {
	previous_tick: time.Tick
	tick_time: time.Duration
	draw_player := world.player

	client_w, client_h := get_client_size()
	canvas := swin.texture_make(client_w, client_h)

	clear_color := swin.color(expand_to_tuple(window.clear_color), 0xff)

	for {
		start_tick := time.tick_now()

		client_w, client_h = get_client_size()
		if client_w != canvas.w || client_h != canvas.h {
			swin.texture_destroy(canvas)
			canvas = swin.texture_make(client_w, client_h)
		}

		if sync.atomic_load(&world.updated) {
			sync.guard(&world.lock)

			// save the world state
			draw_player = world.player
			previous_tick = global_state.previous_tick
			tick_time = sync.atomic_load(&global_state.tick_time)

			sync.atomic_store(&world.updated, false)
		}

		slice.fill(canvas.pixels, clear_color)

		{ // draw the world
			player_pos := interpolate_position(time.tick_diff(previous_tick, time.tick_now()), tick_time, draw_player.position)
			swin.draw_rect(&canvas, {int(player_pos.x), int(player_pos.y), 10, 10}, swin.WHITE)
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

// NOTE: this input processor squashes multiple key presses in-between frames into a single keypress
process_inputs :: proc(handler: proc(swin.Key_Code)) {
	sync.guard(&key_data_lock)
	for states, key in &key_data do for idx := 0; idx < states.len; idx += 1 {
		// released
		if !states.data[idx] {
			// pop it
			small_array.pop_front(&states)
			idx -= 1

			// if release was first in the stack, that means press was not recorded, just skip
			if idx < 0 do continue

			// if release was not first, then pop it
			small_array.pop_front(&states)
			idx -= 1

			// key pressed
			if states.len == 0 {
				handler(key)
			}
			continue
		}

		// key held
		if states.len == 1 {
			handler(key)
		}
	}
}

input_handler :: proc(key: swin.Key_Code) {
	SPEED :: 5

	if key == .Right do world.player.x += SPEED
	if key == .Left do world.player.x -= SPEED
	if key == .Down do world.player.y += SPEED
	if key == .Up do world.player.y -= SPEED
}

update_world :: proc(window: ^swin.Window) {
	for { // NOTE: 30 TPS is assumed
		start_tick := time.tick_now()

		{
			sync.guard(&world.lock)

			world.player.position.prev = world.player.position.pos
			process_inputs(input_handler)

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
		if swin.show_message_box(.OkCancel, "miki game", "Do you really want to quit?", window) == .Cancel {
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
		save_client_size(window.client.w, window.client.h)
	case swin.Move_Event:
	case swin.Character_Event:
	case swin.Keyboard_Event:
		switch ev.state {
		case .Repeat, .Released:
		case .Pressed:
			#partial switch ev.key {
			case .Q, .Escape:
				window.must_close = true
			case .V:
				settings.vsync = !settings.vsync
			case .Num0:
				settings.fps = 0
			case .Num1:
				settings.fps = 10
			case .Num2:
				settings.fps = 200
			case .Num3:
				settings.fps = 30
			case .Num4:
				settings.fps = 144
			case .Num6:
				settings.fps = 60
			case .F:
				settings.show_stats = !settings.show_stats
			case .H:
				settings.show_hitboxes = !settings.show_hitboxes
			case .N:
				save_data("settings.save", &settings)
			case .B:
				settings = default_settings
			}
		}

		if ev.state == .Released || ev.state == .Pressed {
			sync.guard(&key_data_lock)
			small_array.push_back(&key_data[ev.key], ev.state == .Pressed)
		}
	case swin.Mouse_Button_Event:
	case swin.Mouse_Move_Event:
	case swin.Mouse_Wheel_Event:
	}
}

load_resources :: proc() {
	{ // font atlas
		img, err := image.load(#load("res/font.png"))
		assert(err == nil, fmt.tprint(err))
		defer image.destroy(img)

		font.w, font.h = img.width, img.height
		font.texture = swin.texture_make(font.w, font.h)

		// TODO: consider different channel/depth than RGBA, at least RGB
		pixels := mem.slice_data_cast([]image.RGBA_Pixel, bytes.buffer_to_bytes(&img.pixels))
		for p, i in pixels {
			font.texture.pixels[i] = swin.color(expand_to_tuple(p))
		}
	}

	font.table = make(map[rune]int)
	for ch in ` 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ?'".,:;~!@#$^&_|\/%*+-=<>()[]{}` {
		font.table[ch] = len(font.table)
	}

	{ // main atlas
		img, err := image.load(#load("res/atlas.png"))
		assert(err == nil, fmt.tprint(err))
		defer image.destroy(img)

		world.atlas = swin.texture_make(img.width, img.height)

		pixels := mem.slice_data_cast([]image.RGBA_Pixel, bytes.buffer_to_bytes(&img.pixels))
		copy(world.atlas.pixels, pixels)
	}
}

free_resources :: proc() {
	swin.texture_destroy(font.texture)
	delete(font.table)
	swin.texture_destroy(world.atlas)
}

_main :: proc() {
	// Load resources
	load_resources()
	defer free_resources()

	if os.exists("settings.save") {
		load_data("settings.save", &settings)
	}

	// Open window
	window := swin.create(640, 480, "Miki's World: The Lost Tiara")
	assert(window != nil, "Failed to create window")
	defer swin.destroy(window)

	{ // center the window
		wr := swin.get_working_area()
		swin.move(window, wr.x + (wr.w/2 - window.w/2), wr.y + (wr.h/2 - window.h/2))
	}

	window.clear_color = swin.BLUE.rgb
	swin.set_resizable(window, true)
	swin.set_min_size(window, 640, 480)

	save_client_size(window.client.w, window.client.h)

	update_thread := thread.create_and_start_with_poly_data(data = window, fn = update_world, priority = .High)
	defer {
		thread.terminate(update_thread, 0)
		thread.destroy(update_thread)
	}

	render_thread := thread.create_and_start_with_poly_data(data = window, fn = render, priority = .High)
	defer {
		thread.terminate(render_thread, 0)
		thread.destroy(render_thread)
	}

	swin.set_event_handler(window, event_handler)
	swin.run(window)
}
