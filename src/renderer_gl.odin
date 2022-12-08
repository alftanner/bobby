package main

import "core:image"
import "core:sync"
import "core:fmt"
import "core:time"
import "core:math"
import "core:strconv"
import "core:container/small_array"

import "spl"
import "spl/gl"

render_gl :: proc(timer: ^spl.Timer) {
	// local world state
	@static local_world: World
	@static local_level: Level
	@static local_settings: Settings
	// other state
	@static previous_tick: time.Tick
	@static tick_time: time.Duration
	@static offset: [2]f32

	@static init: bool
	if !init {
		init = true

		ok := gl.init(&window, settings.vsync)
		if !ok {
			fmt.println("OpenGL init failed!")
			settings.renderer = .Software
			return
		}

		gl.Enable(gl.BLEND)
		gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

		// TODO: this is needed?
		gl.Enable(gl.ALPHA_TEST)
		gl.AlphaFunc(gl.GREATER, 0)

		for tex in &textures {
			register_texture_gl(&tex)
		}
	}

	start_tick := time.tick_now()

	if sync.atomic_load(&world_updated) {
		sync.guard(&world_lock)
		defer sync.atomic_store(&world_updated, false)

		copy_level(&local_level, &world_level, nil)

		local_world = world
		local_settings = settings
		previous_tick = global_state.previous_tick
		tick_time = sync.atomic_load(&global_state.tick_time)
	}

	client_size := get_from_i64(&global_state.client_size)
	scale := get_buffer_scale(client_size[0], client_size[1])
	{
		buf_size := CANVAS_SIZE * scale
		off_x := (int(client_size[0]) - buf_size[0]) / 2
		off_y := (int(client_size[1]) - buf_size[1]) / 2
		set_viewport_gl({off_x, off_y, buf_size[0], buf_size[1]}, f32(scale))
	}

	gl.ClearColor(0, 0, 0, 1)
	gl.Clear(gl.COLOR_BUFFER_BIT)

	gl.MatrixMode(gl.TEXTURE)
	gl.LoadIdentity()
	gl.MatrixMode(gl.MODELVIEW)
	gl.LoadIdentity()
	gl.MatrixMode(gl.PROJECTION)
	gl.LoadIdentity()

	#partial switch local_world.scene {
	case .Game, .Pause_Menu:
		draw_world_background: bool
		offset = {}
		diff: [2]f32 = {f32(TILES_W - local_level.size[0]), f32(TILES_H - local_level.size[1])}

		player_pos: [2]f32
		frame_delta := get_frame_delta(previous_tick, tick_time)
		@static prev_player_delta: f32
		if local_world.scene == .Pause_Menu || (local_world.player.walking.state && local_world.player.dying.state) {
			frame_delta = prev_player_delta
		} else {
			prev_player_delta = frame_delta
		}
		player_pos = interpolate_tile_position(local_world.player, frame_delta)

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

		lvl_offset: [2]int
		lvl_offset.x = int(offset.x * TILE_SIZE)
		lvl_offset.y = int(offset.y * TILE_SIZE)

		if draw_world_background { // TODO: only draw needed parts, not the entire thing
			bg_pos: [2]int
			bg_pos.x = int(abs(offset.x - f32(int(offset.x))) * TILE_SIZE)
			bg_pos.y = int(abs(offset.y - f32(int(offset.y))) * TILE_SIZE)
			draw_from_texture_gl(textures[.Grass], {}, {bg_pos, CANVAS_SIZE})
		}
		for _, idx in local_level.tiles {
			pos: [2]int = {idx%local_level.size[0], idx/local_level.size[0]}
			sprite := get_sprite_from_pos(pos, local_level)
			draw_from_texture_gl(textures[.Atlas], (pos * TILE_SIZE) + lvl_offset, sprite)
		}

		// draw player
		if !local_level.ended || (local_level.ended && local_world.player.fading.state) {
			pos := (player_pos + offset) * TILE_SIZE
			px := int(pos.x) + local_world.player.sprite.offset.x
			py := int(pos.y) + local_world.player.sprite.offset.y
			draw_from_texture_gl(textures[.Atlas], {px, py}, local_world.player.sprite)
		}

		// HUD
		if !local_level.ended {
			// left part
			{
				tbuf: [8]byte
				time_str := fmt.bprintf(
					tbuf[:], "{:02i}:{:02i}",
					int(time.duration_minutes(local_level.score.time)),
					int(time.duration_seconds(local_level.score.time)) % 60,
				)
				draw_text_gl(hud_font, time_str, {2, 2})
			}
			// level begin screen
			if time.duration_seconds(local_level.score.time) < 2 {
				tbuf: [16]byte
				level_str := fmt.bprintf(tbuf[:], "{} {}", language_strings[local_settings.language][.Level], local_level.current + 1)
				size := measure_text(general_font, level_str)
				pos := (CANVAS_SIZE - size) / 2
				draw_text_gl(general_font, level_str, pos)
			}
			// right part
			{
				pos: [2]int = {CANVAS_SIZE[0] - 2, 2}

				if local_level.carrots > 0 {
					sprite := hud_sprites[.Carrot]
					pos.x -= sprite.size[0]
					draw_from_texture_gl(textures[.Atlas], pos, sprite)
					pos.x -= 2

					tbuf: [8]byte
					str := strconv.itoa(tbuf[:], local_level.carrots)
					{
						size := measure_text(hud_font, str)
						pos.x -= size[0]
					}
					draw_text_gl(hud_font, str, {pos.x, pos.y + 3})
					pos.y += sprite.size[1] + 2
					pos.x = CANVAS_SIZE[0] - 2
				}

				if local_level.eggs > 0 {
					sprite := hud_sprites[.Egg]
					pos.x -= sprite.size[0]
					draw_from_texture_gl(textures[.Atlas], pos, sprite)
					pos.x -= 2

					tbuf: [8]byte
					str := strconv.itoa(tbuf[:], local_level.eggs)
					{
						size := measure_text(hud_font, str)
						pos.x -= size[0]
					}
					draw_text_gl(hud_font, str, {pos.x, pos.y + 3})
					pos.y += sprite.size[1] + 2
					pos.x = CANVAS_SIZE[0] - 2
				}

				if local_world.player.silver_key {
					sprite := hud_sprites[.Silver_Key]
					pos.x -= sprite.size[0]
					draw_from_texture_gl(textures[.Atlas], pos, sprite)
					pos.x -= 2
				}
				if local_world.player.golden_key {
					sprite := hud_sprites[.Golden_Key]
					pos.x -= sprite.size[0]
					draw_from_texture_gl(textures[.Atlas], pos, sprite)
					pos.x -= 2
				}
				if local_world.player.copper_key {
					sprite := hud_sprites[.Copper_Key]
					pos.x -= sprite.size[0]
					draw_from_texture_gl(textures[.Atlas], pos, sprite)
					pos.x -= 2
				}
			}
		}

		// level end screen
		if local_level.ended && !local_world.player.fading.state {
			total_h: int
			success := hud_sprites[.Success]
			success_x := (CANVAS_SIZE[0] - success.size[0]) / 2
			total_h += success.size[1] + (general_font.glyph_size[1] * 2)

			tbuf: [64]byte
			time_str := fmt.bprintf(tbuf[:32], "{}: {:02i}:{:02i}:{:02i}",
				language_strings[local_settings.language][.Time],
				int(time.duration_minutes(local_level.score.time)),
				int(time.duration_seconds(local_level.score.time)) % 60,
				int(time.duration_milliseconds(local_level.score.time)) % 60,
			)
			time_x, time_h: int
			{
				size := measure_text(general_font, time_str)
				time_x = (CANVAS_SIZE[0] - size[0]) / 2
				time_h = size[1]
			}
			total_h += time_h + general_font.glyph_size[1]

			steps_str := fmt.bprintf(tbuf[32:], "{}: {}", language_strings[local_settings.language][.Steps], local_level.score.steps)
			steps_x, steps_h: int
			{
				size := measure_text(general_font, steps_str)
				steps_x = (CANVAS_SIZE[0] - size[0]) / 2
				steps_h = size[1]
			}
			total_h += steps_h + (general_font.glyph_size[1] * 2)

			hint_str := language_strings[local_settings.language][.Press_Enter]
			hint_x, hint_h: int
			{
				size := measure_text(general_font, hint_str)
				hint_x = (CANVAS_SIZE[0] - size[0]) / 2
				hint_h = size[1]
			}
			total_h += hint_h

			pos: [2]int
			pos.x = (CANVAS_SIZE[0] - success.size[0]) / 2
			pos.y = (CANVAS_SIZE[1] - total_h) / 2
			draw_from_texture_gl(textures[.Atlas], pos, success)
			pos.y += success.size[1] + (general_font.glyph_size[1] * 2)

			draw_text_gl(general_font, time_str, {time_x, pos.y})
			pos.y += time_h + general_font.glyph_size[1]

			draw_text_gl(general_font, steps_str, {steps_x, pos.y})
			pos.y += steps_h + (general_font.glyph_size[1] * 2)

			draw_text_gl(general_font, hint_str, {hint_x, pos.y})
		}
	case .Main_Menu, .Scoreboard:
		draw_from_texture_gl(textures[.Grass if local_settings.campaign == .Carrot_Harvest else .Ground], {}, {{}, CANVAS_SIZE})
	case .Intro:
		off := (CANVAS_SIZE - INTRO_SPLASH.size) / 2
		draw_from_texture_gl(textures[.Splashes], off, INTRO_SPLASH)
		intro_alpha := get_intro_alpha(local_world.intro, get_frame_delta(previous_tick, tick_time))
		draw_rect_gl({off, INTRO_SPLASH.size}, {0, 0, 0, intro_alpha})
	case .End:
		off := (CANVAS_SIZE - END_SPLASH.size) / 2
		draw_from_texture_gl(textures[.Splashes], off, END_SPLASH)
	case .Credits:
		draw_credits_gl(local_settings.language)
	}

	#partial switch local_world.scene {
	case .Pause_Menu, .Main_Menu, .Scoreboard:
		draw_rect_gl({{}, CANVAS_SIZE}, {0, 0, 0, 0xAA})
	}

	#partial switch local_world.scene {
	case .Main_Menu, .Pause_Menu:
		draw_menu_gl(small_array.slice(&local_world.menu_options), local_world.selected_option)
	case .Scoreboard:
		draw_scoreboard_gl(small_array.slice(&local_world.scoreboard), local_world.scoreboard_page)
	}

	fade_alpha := get_fade_alpha(local_world.fade, get_frame_delta(previous_tick, tick_time))
	if fade_alpha != 0 {
		draw_rect_gl({{}, CANVAS_SIZE}, {0, 0, 0, fade_alpha})
	}

	if local_settings.show_stats {
		calculate_stats()
		set_viewport_gl({0, 0, int(client_size[0]), int(client_size[1])}, f32(scale))
		draw_stats_gl()
	}

	sync.atomic_store(&global_state.frame_work, time.tick_since(start_tick))

	if settings.vsync {
		gl.swap_buffers(&window)
	} else {
		spl.wait_timer(timer)
		gl.Flush()
	}

	sync.atomic_store(&global_state.frame_time, time.tick_since(start_tick))
}

render_gl_finish :: proc() {
	gl.deinit(&window)
}

set_viewport_gl :: #force_inline proc(viewport: [4]int, scale: f32) {
	global_state.viewport = viewport
	gl.Viewport(i32(viewport[0]), i32(viewport[1]), i32(viewport[2]), i32(viewport[3]))
	global_state.rendering_scale = scale
}

register_texture_gl :: #force_inline proc(t: ^Texture2D) {
	gl.Enable(gl.TEXTURE_2D)
	defer gl.Disable(gl.TEXTURE_2D)

	gl.GenTextures(1, &t.index)
	gl.BindTexture(gl.TEXTURE_2D, t.index)
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, i32(t.size[0]), i32(t.size[1]), 0, gl.BGRA_EXT, gl.UNSIGNED_BYTE, raw_data(t.pixels))
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
}

draw_text_gl :: #force_inline proc(
	font: Font,
	text: string,
	pos: [2]int,
	color: image.RGB_Pixel = {255, 255, 255},
	shadow_color: image.RGB_Pixel = {0, 0, 0},
) {
	gl.Enable(gl.TEXTURE_2D)
	defer gl.Disable(gl.TEXTURE_2D)

	gl.BindTexture(gl.TEXTURE_2D, font.texture.index)

	gl.Begin(gl.TRIANGLES)
	defer gl.End()

	measure_or_draw_text(.GL, nil, font, text, pos, color, shadow_color)
}

draw_from_texture_gl :: proc(src: Texture2D, pos: [2]int, src_rect: Rect, flip: bit_set[Flip] = {}, mod: image.RGB_Pixel = {255, 255, 255}, bind := true) {
	needs_mod := mod != {255, 255, 255}

	if needs_mod {
		gl.Color3ub(expand_to_tuple(mod))
	}
	defer if needs_mod {
		gl.Color3ub(255, 255, 255)
	}

	if bind {
		gl.Enable(gl.TEXTURE_2D)
		gl.BindTexture(gl.TEXTURE_2D, src.index)
		gl.Begin(gl.TRIANGLES)
	}
	defer if bind {
		gl.End()
		gl.Disable(gl.TEXTURE_2D)
	}

	canvas_w := f32(global_state.viewport[2]) / f32(global_state.rendering_scale)
	canvas_h := f32(global_state.viewport[3]) / f32(global_state.rendering_scale)

	src_left := f32(src_rect.x) / f32(src.size[0])
	src_right := f32(src_rect.x + src_rect.size[0]) / f32(src.size[0])
	src_top := f32(src_rect.y) / f32(src.size[1])
	src_bottom := f32(src_rect.y + src_rect.size[1]) / f32(src.size[1])

	dst_left := f32(pos.x) / canvas_w
	dst_right := f32(pos.x + src_rect.size[0]) / canvas_w
	dst_top := f32(pos.y) / canvas_h
	dst_bottom := f32(pos.y + src_rect.size[1]) / canvas_h

	{ // normalize dst coordinates
		dst_left = (dst_left * 2) - 1
		dst_right = (dst_right * 2) - 1
		dst_top = (dst_top * -2) + 1
		dst_bottom = (dst_bottom * -2) + 1
	}
	if .Horizontal in flip {
		dst_left, dst_right = dst_right, dst_left
	}
	if .Vertical in flip {
		dst_top, dst_bottom = dst_bottom, dst_top
	}

	gl.TexCoord2f(src_left, src_top)
	gl.Vertex2f(dst_left, dst_top)
	gl.TexCoord2f(src_right, src_top)
	gl.Vertex2f(dst_right, dst_top)
	gl.TexCoord2f(src_right, src_bottom)
	gl.Vertex2f(dst_right, dst_bottom)

	gl.TexCoord2f(src_left, src_top)
	gl.Vertex2f(dst_left, dst_top)
	gl.TexCoord2f(src_right, src_bottom)
	gl.Vertex2f(dst_right, dst_bottom)
	gl.TexCoord2f(src_left, src_bottom)
	gl.Vertex2f(dst_left, dst_bottom)
}

draw_rect_gl :: proc(rect: Rect, col: image.RGBA_Pixel, filled: bool = true) {
	gl.Color4ub(expand_to_tuple(col))
	defer gl.Color4ub(255, 255, 255, 255)

	{
		gl.Begin(gl.TRIANGLES)
		defer gl.End()

		canvas_w := f32(global_state.viewport[2]) / f32(global_state.rendering_scale)
		canvas_h := f32(global_state.viewport[3]) / f32(global_state.rendering_scale)

		dst_left := f32(rect.x) / canvas_w
		dst_right := f32(rect.x + rect.size[0]) / canvas_w
		dst_top := f32(rect.y) / canvas_h
		dst_bottom := f32(rect.y + rect.size[1]) / canvas_h

		{ // normalize dst coordinates
			dst_left = (dst_left * 2) - 1
			dst_right = (dst_right * 2) - 1
			dst_top = (dst_top * -2) + 1
			dst_bottom = (dst_bottom * -2) + 1
		}

		gl.Vertex2f(dst_left, dst_top)
		gl.Vertex2f(dst_right, dst_top)
		gl.Vertex2f(dst_right, dst_bottom)

		gl.Vertex2f(dst_left, dst_top)
		gl.Vertex2f(dst_right, dst_bottom)
		gl.Vertex2f(dst_left, dst_bottom)
	}
}

draw_credits_gl :: proc(language: Language) {
	str := language_strings[language][.Credits_Original]
	str2 := language_strings[language][.Credits_Remastered]

	str_size := measure_text(general_font, str)
	str2_size := measure_text(general_font, str2)
	size_h := str_size[1] + general_font.glyph_size[1] + textures[.Logo].size[1] + general_font.glyph_size[1] + str2_size[1]
	off_y := (CANVAS_SIZE[1] - size_h) / 2

	draw_text_gl(general_font, str, {(CANVAS_SIZE[0] - str_size[0]) / 2, off_y})
	off_y += str_size[1] + general_font.glyph_size[1]
	draw_from_texture_gl(textures[.Logo], {(CANVAS_SIZE[0] - textures[.Logo].size[0]) / 2, off_y}, {{}, textures[.Logo].size})
	off_y += textures[.Logo].size[1] + general_font.glyph_size[1]
	draw_text_gl(general_font, str2, {(CANVAS_SIZE[0] - str2_size[0]) / 2, off_y})
}

draw_menu_gl :: proc(options: []Menu_Option, selected: int) {
	DISABLED :: image.RGB_Pixel{75, 75, 75}
	NORMAL :: image.RGB_Pixel{145, 145, 145}
	SELECTED :: image.RGB_Pixel{255, 255, 255}

	for option, idx in options {
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
			draw_from_texture_gl(textures[.Atlas], {x, option.y - 1}, RIGHT_ARROW, {.Horizontal}, color)
			x += RIGHT_ARROW.size[0] + SPACE_BETWEEN_ARROW_AND_TEXT
		}

		draw_text_gl(general_font, text, {x, option.y}, color)

		if option.arrows != nil {
			color := color
			if !option.arrows.?[1].enabled {
				color = DISABLED
			}
			x += option.size[0] + SPACE_BETWEEN_ARROW_AND_TEXT
			draw_from_texture_gl(textures[.Atlas], {x, option.y - 1}, RIGHT_ARROW, {}, color)
		}
	}
}

draw_scoreboard_gl :: proc(labels: []Text_Label, page: int) {
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

	up_arrow, down_arrow: Rect
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

		draw_text_gl(general_font, text, region.pos, SELECTED)

		y += region.size[1] + general_font.glyph_size[1]
	}

	{
		color := SELECTED
		if page == 0 {
			color = DISABLED
		}
		draw_from_texture_gl(textures[.Atlas], up_arrow.pos, UP_ARROW, {}, color)
	}
	{
		color := SELECTED
		if page == pages - 1 {
			color = DISABLED
		}
		draw_from_texture_gl(textures[.Atlas], down_arrow.pos, UP_ARROW, {.Vertical}, color)
	}
}

draw_stats_gl :: proc() {
	tbuf: [256]byte
	text := fmt.bprintf(
		tbuf[:],
`{}FPS{} {}ms last
{}TPS {}ms last`,
		u32(math.round(global_state.fps.average)), " (VSYNC)" if settings.vsync else "", global_state.last_frame.average,
		u32(math.round(global_state.tps.average)), global_state.last_update.average,
	)

	viewport_size := swizzle(global_state.viewport, 2, 3)
	pos: [2]int
	pos.x = int(f32(viewport_size[0]) / global_state.rendering_scale) - 2
	pos.y = int(f32(viewport_size[1]) / global_state.rendering_scale) - 2
	pos -= measure_text(general_font, text)
	draw_text_gl(general_font, text, pos)
}
