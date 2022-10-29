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
import "core:fmt"
when ODIN_DEBUG do import "core:log"

import swin "simple_window"

SKY_BLUE: image.RGBA_Pixel : {139, 216, 245, 255}

GLYPH_W, GLYPH_H :: 5, 7
Font :: struct {
	using texture: swin.Texture2D,
	table: map[rune]int,
}
font: Font

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

World :: struct {
	client_size: i64, // stores 2 i32 values
	// TODO: i128 with atomic_load/store

	updated: bool,
	frame_time, frame: time.Duration,
	tick_frame_time, tick_frame: time.Duration,
	lock: sync.Mutex,
	atlas: swin.Texture2D,

	tone_hz: f32,
	x_offset: f32,

	audio_present: bool,
	samples: []i16,
}
world: World

save_client_size :: #force_inline proc(width, height: int) {
	sync.atomic_store(&world.client_size, transmute(i64)[2]i32{i32(width), i32(height)})
}

get_client_size :: #force_inline proc() -> (int, int) {
	client_size := transmute([2]i32)sync.atomic_load(&world.client_size)
	return int(client_size[0]), int(client_size[1])
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

draw_stats :: proc(canvas: ^swin.Texture2D, vsync: bool) {
	@static time_waited: time.Duration
	@static lastu, lastf, fps, tps: Average_Calculator

	avg_add(&lastu, time.duration_milliseconds(sync.atomic_load(&world.tick_frame_time)))
	avg_add(&lastf, time.duration_milliseconds(sync.atomic_load(&world.frame_time)))
	avg_add(&tps, 1000/time.duration_milliseconds(sync.atomic_load(&world.tick_frame)))
	avg_add(&fps, 1000/time.duration_milliseconds(sync.atomic_load(&world.frame)))

	@static tick: time.Tick
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
		u32(math.round(fps.average)), " (VSYNC)" if vsync else "", lastf.average,
		u32(math.round(tps.average)), lastu.average,
	)

	draw_text(canvas, text, &x, &y)
}

render :: proc(data: rawptr) {
	window := cast(^swin.Window)data

	client_w, client_h := get_client_size()
	canvas := swin.texture_make(client_w, client_h, runtime.default_allocator())

	clear_color := swin.color(expand_to_tuple(window.clear_color), 0xff)

	for {
		start_tick := time.tick_now()

		client_w, client_h = get_client_size()
		if client_w != canvas.w || client_h != canvas.h {
			swin.texture_destroy(canvas)
			canvas = swin.texture_make(client_w, client_h, runtime.default_allocator())
		}


		if sync.atomic_load(&world.updated) {
			sync.guard(&world.lock)
			// TODO: collect needed info from the world update
			sync.atomic_store(&world.updated, false)
		}

		slice.fill(canvas.pixels, clear_color)
		// TODO: draw the world, interpolate if necessary

		vsync := settings.vsync
		if settings.show_stats {
			draw_stats(&canvas, vsync)
		}

		sync.atomic_store(&world.frame_time, time.tick_since(start_tick))

		if vsync {
			swin.wait_vblank()
		} else {
			limit_frame(time.tick_since(start_tick), settings.fps)
		}
		swin.display_pixels(window, canvas, {0, 0, canvas.w, canvas.h})

		sync.atomic_store(&world.frame, time.tick_since(start_tick))
	}
}

world_update :: proc(data: rawptr) {
	window := cast(^swin.Window)data

	LATENCY_FRAMES :: 3

	sound_output = {
		samples_per_second = 48000,
		bytes_per_sample = size_of(i16)*2,
	}
	sound_output.secondary_buffer_size = sound_output.samples_per_second * sound_output.bytes_per_sample
	sound_output.latency_sample_count = (sound_output.samples_per_second / 15) * LATENCY_FRAMES

	if audio_init(window.id, sound_output.samples_per_second, sound_output.secondary_buffer_size) {
		audio_start()
		world.samples = make([]i16, sound_output.secondary_buffer_size, runtime.default_allocator())
		world.audio_present = true
	}

	// NOTE: doesn't run because the thread is terminated
	// TODO: is not deiniting audio a problem?
	// TODO: move audio into a separate thread anyway
	defer if world.audio_present {
		delete(world.samples)
		audio_deinit()
	}

	for { // NOTE: 30 TPS is assumed
		start_tick := time.tick_now()

		{
			sync.guard(&world.lock)
			// update world

			sync.atomic_store(&world.updated, true)
		}

		world.tone_hz = 256 + (world.x_offset / 4)

		if world.audio_present {
			audio_play()
		}

		sync.atomic_store(&world.tick_frame_time, time.tick_since(start_tick))

		limit_frame(time.tick_since(start_tick), settings.tps, false) // NOTE: not using accurate timer for 30 TPS, maybe I should?

		sync.atomic_store(&world.tick_frame, time.tick_since(start_tick))
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
			settings.vsync = default_settings.vsync
			settings.fps = default_settings.fps
			settings.tps = default_settings.tps
		} else {
			settings.vsync = false
			settings.tps = 5
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
			case .Space: // jump
				//sync.guard(&world.lock)
				//world.player.should_jump = true
			}
		}
	case swin.Mouse_Button_Event:
	case swin.Mouse_Move_Event:
	case swin.Mouse_Wheel_Event:
	}
}

run :: proc() {
	// Load resources
	{
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
	defer swin.texture_destroy(font.texture)

	font.table = make(map[rune]int)
	for ch in ` 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ?'".,:;~!@#$^&_|\/%*+-=<>()[]{}` {
		font.table[ch] = len(font.table)
	}
	defer delete(font.table)

	if os.exists("settings.save") {
		load_data("settings.save", &settings)
	}

	{ // load the main texture
		img, err := image.load(#load("res/atlas.png"))
		assert(err == nil, fmt.tprint(err))
		defer image.destroy(img)

		world.atlas = swin.texture_make(img.width, img.height)

		pixels := mem.slice_data_cast([]image.RGBA_Pixel, bytes.buffer_to_bytes(&img.pixels))
		copy(world.atlas.pixels, pixels)
	}
	defer swin.texture_destroy(world.atlas)

	// Open window
	window, ok := swin.create(640, 480, "Miki's World: The Lost Tiara")
	assert(ok, "Failed to create window")
	defer swin.destroy(window)

	{ // center the window
		wr := swin.get_working_area()
		swin.move(window, wr.x + (wr.w/2 - window.w/2), wr.y + (wr.h/2 - window.h/2))
	}

	swin.set_clear_color(window, swin.BLUE.rgb)
	swin.set_resizable(window, true)
	swin.set_min_size(window, 640, 480)

	save_client_size(window.client.w, window.client.h)

	update_thread := thread.create_and_start_with_data(window, world_update, default_context, .High)
	defer {
		thread.terminate(update_thread, 0)
		thread.destroy(update_thread)
	}

	render_thread := thread.create_and_start_with_data(window, render, default_context, .High)
	defer {
		thread.terminate(render_thread, 0)
		thread.destroy(render_thread)
	}

	swin.set_event_handler(event_handler, default_context)
	swin.run(window)
}
