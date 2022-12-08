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

GL_State :: struct {
	texture: int,
	viewport: [4]int,
	scale: f32,

	vertices: [dynamic][2]f32,
	tex_coords: [dynamic][2]f32,
	colors: [dynamic]image.RGBA_Pixel,
}
gl_state: GL_State

textures_index: [Textures]u32

gl_render :: proc(timer: ^spl.Timer, was_init: bool) {
	// local world state
	@static local_world: World
	@static local_level: Level
	@static local_settings: Settings
	// other state
	@static previous_tick: time.Tick
	@static tick_time: time.Duration
	@static offset: [2]f32

	if !was_init {
		ok := gl.init(&window, settings.vsync)
		if !ok {
			sync.atomic_store(&global_state.renderer_fallback, true)
			for sync.atomic_load(&global_state.renderer_fallback) {}
			return
		}

		gl.Enable(gl.BLEND)
		gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)

		gl.EnableClientState(gl.VERTEX_ARRAY)
		gl.EnableClientState(gl.TEXTURE_COORD_ARRAY)
		gl.EnableClientState(gl.COLOR_ARRAY)

		for _, tex in &textures {
			gl_register_texture(tex)
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
		gl_set_viewport({off_x, off_y, buf_size[0], buf_size[1]}, f32(scale))
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

		if draw_world_background { // TODO: only draw needed parts, not the entire thing?
			bg_pos: [2]int
			bg_pos.x = int(abs(offset.x - f32(int(offset.x))) * TILE_SIZE)
			bg_pos.y = int(abs(offset.y - f32(int(offset.y))) * TILE_SIZE)
			gl_draw_from_texture({}, .Grass, {bg_pos, CANVAS_SIZE})
		}
		for _, idx in local_level.tiles {
			pos: [2]int = {idx%local_level.size[0], idx/local_level.size[0]}
			sprite := get_sprite_from_pos(pos, local_level)
			gl_draw_from_texture((pos * TILE_SIZE) + lvl_offset, .Atlas, sprite)
		}

		// draw player
		if !local_level.ended || (local_level.ended && local_world.player.fading.state) {
			pos := (player_pos + offset) * TILE_SIZE
			px := int(pos.x) + local_world.player.sprite.offset.x
			py := int(pos.y) + local_world.player.sprite.offset.y
			gl_draw_from_texture({px, py}, .Atlas, local_world.player.sprite)
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
				gl_draw_text(hud_font, time_str, {2, 2})
			}
			// level begin screen
			if time.duration_seconds(local_level.score.time) < 2 {
				tbuf: [16]byte
				level_str := fmt.bprintf(tbuf[:], "{} {}", language_strings[local_settings.language][.Level], local_level.current + 1)
				size := measure_text(general_font, level_str)
				pos := (CANVAS_SIZE - size) / 2
				gl_draw_text(general_font, level_str, pos)
			}
			// right part
			{
				pos: [2]int = {CANVAS_SIZE[0] - 2, 2}

				if local_level.carrots > 0 {
					sprite := hud_sprites[.Carrot]
					pos.x -= sprite.size[0]
					gl_draw_from_texture(pos, .Atlas, sprite)
					pos.x -= 2

					tbuf: [8]byte
					str := strconv.itoa(tbuf[:], local_level.carrots)
					{
						size := measure_text(hud_font, str)
						pos.x -= size[0]
					}
					gl_draw_text(hud_font, str, {pos.x, pos.y + 3})
					pos.y += sprite.size[1] + 2
					pos.x = CANVAS_SIZE[0] - 2
				}

				if local_level.eggs > 0 {
					sprite := hud_sprites[.Egg]
					pos.x -= sprite.size[0]
					gl_draw_from_texture(pos, .Atlas, sprite)
					pos.x -= 2

					tbuf: [8]byte
					str := strconv.itoa(tbuf[:], local_level.eggs)
					{
						size := measure_text(hud_font, str)
						pos.x -= size[0]
					}
					gl_draw_text(hud_font, str, {pos.x, pos.y + 3})
					pos.y += sprite.size[1] + 2
					pos.x = CANVAS_SIZE[0] - 2
				}

				if local_world.player.silver_key {
					sprite := hud_sprites[.Silver_Key]
					pos.x -= sprite.size[0]
					gl_draw_from_texture(pos, .Atlas, sprite)
					pos.x -= 2
				}
				if local_world.player.golden_key {
					sprite := hud_sprites[.Golden_Key]
					pos.x -= sprite.size[0]
					gl_draw_from_texture(pos, .Atlas, sprite)
					pos.x -= 2
				}
				if local_world.player.copper_key {
					sprite := hud_sprites[.Copper_Key]
					pos.x -= sprite.size[0]
					gl_draw_from_texture(pos, .Atlas, sprite)
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
			gl_draw_from_texture(pos, .Atlas, success)
			pos.y += success.size[1] + (general_font.glyph_size[1] * 2)

			gl_draw_text(general_font, time_str, {time_x, pos.y})
			pos.y += time_h + general_font.glyph_size[1]

			gl_draw_text(general_font, steps_str, {steps_x, pos.y})
			pos.y += steps_h + (general_font.glyph_size[1] * 2)

			gl_draw_text(general_font, hint_str, {hint_x, pos.y})
		}
	case .Main_Menu, .Scoreboard:
		gl_draw_from_texture({}, .Grass if local_settings.campaign == .Carrot_Harvest else .Ground, {{}, CANVAS_SIZE})
	case .Intro:
		off := (CANVAS_SIZE - INTRO_SPLASH.size) / 2
		gl_draw_from_texture(off, .Splashes, INTRO_SPLASH)
		intro_alpha := get_intro_alpha(local_world.intro, get_frame_delta(previous_tick, tick_time))
		gl_draw_rect({off, INTRO_SPLASH.size}, {0, 0, 0, intro_alpha})
	case .End:
		off := (CANVAS_SIZE - END_SPLASH.size) / 2
		gl_draw_from_texture(off, .Splashes, END_SPLASH)
	case .Credits:
		gl_draw_credits(local_settings.language)
	}

	#partial switch local_world.scene {
	case .Pause_Menu, .Main_Menu, .Scoreboard:
		gl_draw_rect({{}, CANVAS_SIZE}, {0, 0, 0, 0xAA})
	}

	#partial switch local_world.scene {
	case .Main_Menu, .Pause_Menu:
		gl_draw_menu(small_array.slice(&local_world.menu_options), local_world.selected_option)
	case .Scoreboard:
		gl_draw_scoreboard(small_array.slice(&local_world.scoreboard), local_world.scoreboard_page)
	}

	fade_alpha := get_fade_alpha(local_world.fade, get_frame_delta(previous_tick, tick_time))
	if fade_alpha != 0 {
		gl_draw_rect({{}, CANVAS_SIZE}, {0, 0, 0, fade_alpha})
	}

	if local_settings.show_stats {
		calculate_stats()
		gl_set_viewport({0, 0, int(client_size[0]), int(client_size[1])}, f32(scale))
		gl_draw_stats()
	}

	gl_draw()

	sync.atomic_store(&global_state.frame_work, time.tick_since(start_tick))

	if settings.vsync {
		gl.swap_buffers(&window)
	} else {
		spl.wait_timer(timer)
		gl.Flush()
	}

	sync.atomic_store(&global_state.frame_time, time.tick_since(start_tick))
}

gl_render_finish :: proc() {
	gl.deinit(&window)
}

gl_set_viewport :: #force_inline proc(viewport: [4]int, scale: f32) {
	if gl_state.viewport == viewport && gl_state.scale == scale do return

	gl_draw()
	gl.Viewport(i32(viewport[0]), i32(viewport[1]), i32(viewport[2]), i32(viewport[3]))
	gl_state.viewport = viewport
	gl_state.scale = scale
}

gl_register_texture :: #force_inline proc(t: Textures) {
	gl.Enable(gl.TEXTURE_2D)
	gl.GenTextures(1, &textures_index[t])
	gl.BindTexture(gl.TEXTURE_2D, textures_index[t])
	gl.TexImage2D(gl.TEXTURE_2D, 0, gl.RGBA8, i32(textures[t].size[0]), i32(textures[t].size[1]), 0, gl.BGRA_EXT, gl.UNSIGNED_BYTE, raw_data(textures[t].pixels))
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST)
	gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.NEAREST)
}

gl_draw :: proc() {
	if len(gl_state.vertices) == 0 do return

	if len(gl_state.tex_coords) > 0 {
		gl.TexCoordPointer(2, gl.FLOAT, 0, raw_data(gl_state.tex_coords))
	}
	gl.VertexPointer(2, gl.FLOAT, 0, raw_data(gl_state.vertices))
	gl.ColorPointer(4, gl.UNSIGNED_BYTE, 0, raw_data(gl_state.colors))
	gl.DrawArrays(gl.TRIANGLES, 0, auto_cast len(gl_state.colors))

	clear(&gl_state.colors)
	clear(&gl_state.vertices)
	clear(&gl_state.tex_coords)
}

gl_draw_from_texture :: proc(pos: [2]int, tex: Textures, src_rect: Rect, flip: bit_set[Flip] = {}, mod: image.RGB_Pixel = {255, 255, 255}) {
	color := image.RGBA_Pixel{mod.r, mod.g, mod.b, 255}

	if gl_state.texture != auto_cast textures_index[tex] {
		gl_draw()

		if gl_state.texture < 1 {
			gl.Enable(gl.TEXTURE_2D)
		}

		gl.BindTexture(gl.TEXTURE_2D, textures_index[tex])

		gl_state.texture = auto_cast textures_index[tex]
	}

	src := textures[tex]

	canvas_w := f32(gl_state.viewport[2]) / f32(gl_state.scale)
	canvas_h := f32(gl_state.viewport[3]) / f32(gl_state.scale)

	crd_left := f32(src_rect.x) / f32(src.size[0])
	crd_right := f32(src_rect.x + src_rect.size[0]) / f32(src.size[0])
	crd_top := f32(src_rect.y) / f32(src.size[1])
	crd_bottom := f32(src_rect.y + src_rect.size[1]) / f32(src.size[1])

	vrt_left := f32(pos.x) / canvas_w
	vrt_right := f32(pos.x + src_rect.size[0]) / canvas_w
	vrt_top := f32(pos.y) / canvas_h
	vrt_bottom := f32(pos.y + src_rect.size[1]) / canvas_h

	{ // normalize vertices
		vrt_left = (vrt_left * 2) - 1
		vrt_right = (vrt_right * 2) - 1
		vrt_top = (vrt_top * -2) + 1
		vrt_bottom = (vrt_bottom * -2) + 1
	}
	if .Horizontal in flip {
		vrt_left, vrt_right = vrt_right, vrt_left
	}
	if .Vertical in flip {
		vrt_top, vrt_bottom = vrt_bottom, vrt_top
	}

	tex_coords: [6][2]f32 = {
		{crd_left, crd_top},
		{crd_right, crd_top},
		{crd_right, crd_bottom},
		{crd_left, crd_top},
		{crd_right, crd_bottom},
		{crd_left, crd_bottom},
	}
	vertices: [6][2]f32 = {
		{vrt_left, vrt_top},
		{vrt_right, vrt_top},
		{vrt_right, vrt_bottom},
		{vrt_left, vrt_top},
		{vrt_right, vrt_bottom},
		{vrt_left, vrt_bottom},
	}

	for i in 0..<6 {
		append(&gl_state.tex_coords, tex_coords[i])
		append(&gl_state.vertices, vertices[i])
		append(&gl_state.colors, color)
	}
}

gl_draw_rect :: proc(rect: Rect, color: image.RGBA_Pixel) {
	if gl_state.texture != -1 {
		gl_draw()

		gl.Disable(gl.TEXTURE_2D)

		gl_state.texture = -1
	}

	canvas_w := f32(gl_state.viewport[2]) / f32(gl_state.scale)
	canvas_h := f32(gl_state.viewport[3]) / f32(gl_state.scale)

	vrt_left := f32(rect.x) / canvas_w
	vrt_right := f32(rect.x + rect.size[0]) / canvas_w
	vrt_top := f32(rect.y) / canvas_h
	vrt_bottom := f32(rect.y + rect.size[1]) / canvas_h

	{ // normalize vertices
		vrt_left = (vrt_left * 2) - 1
		vrt_right = (vrt_right * 2) - 1
		vrt_top = (vrt_top * -2) + 1
		vrt_bottom = (vrt_bottom * -2) + 1
	}

	vertices: [6][2]f32 = {
		{vrt_left, vrt_top},
		{vrt_right, vrt_top},
		{vrt_right, vrt_bottom},
		{vrt_left, vrt_top},
		{vrt_right, vrt_bottom},
		{vrt_left, vrt_bottom},
	}
	for i in 0..<6 {
		append(&gl_state.vertices, vertices[i])
		append(&gl_state.colors, color)
	}
}

gl_draw_text :: #force_inline proc(
	font: Font,
	text: string,
	pos: [2]int,
	color: image.RGB_Pixel = {255, 255, 255},
	shadow_color: image.RGB_Pixel = {0, 0, 0},
) {
	measure_or_draw_text(.GL, nil, font, text, pos, color, shadow_color)
}

gl_draw_credits :: proc(language: Language) {
	str := language_strings[language][.Credits_Original]
	str2 := language_strings[language][.Credits_Remastered]

	str_size := measure_text(general_font, str)
	str2_size := measure_text(general_font, str2)
	size_h := str_size[1] + general_font.glyph_size[1] + textures[.Logo].size[1] + general_font.glyph_size[1] + str2_size[1]
	off_y := (CANVAS_SIZE[1] - size_h) / 2

	gl_draw_text(general_font, str, {(CANVAS_SIZE[0] - str_size[0]) / 2, off_y})
	off_y += str_size[1] + general_font.glyph_size[1]

	gl_draw_from_texture({(CANVAS_SIZE[0] - textures[.Logo].size[0]) / 2, off_y}, .Logo, {{}, textures[.Logo].size})
	off_y += textures[.Logo].size[1] + general_font.glyph_size[1]

	gl_draw_text(general_font, str2, {(CANVAS_SIZE[0] - str2_size[0]) / 2, off_y})
}

gl_draw_menu :: proc(options: []Menu_Option, selected: int) {
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
			gl_draw_from_texture({x, option.y - 1}, .Atlas, RIGHT_ARROW, {.Horizontal}, color)
			x += RIGHT_ARROW.size[0] + SPACE_BETWEEN_ARROW_AND_TEXT
		}

		gl_draw_text(general_font, text, {x, option.y}, color)

		if option.arrows != nil {
			color := color
			if !option.arrows.?[1].enabled {
				color = DISABLED
			}
			x += option.size[0] + SPACE_BETWEEN_ARROW_AND_TEXT
			gl_draw_from_texture({x, option.y - 1}, .Atlas, RIGHT_ARROW, {}, color)
		}
	}
}

gl_draw_scoreboard :: proc(labels: []Text_Label, page: int) {
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

		gl_draw_text(general_font, text, region.pos, SELECTED)

		y += region.size[1] + general_font.glyph_size[1]
	}

	{
		color := SELECTED
		if page == 0 {
			color = DISABLED
		}
		gl_draw_from_texture(up_arrow.pos, .Atlas, UP_ARROW, {}, color)
	}
	{
		color := SELECTED
		if page == pages - 1 {
			color = DISABLED
		}
		gl_draw_from_texture(down_arrow.pos, .Atlas, UP_ARROW, {.Vertical}, color)
	}
}

gl_draw_stats :: proc() {
	tbuf: [256]byte
	text := fmt.bprintf(
		tbuf[:],
`{}FPS{} {}ms last
{}TPS {}ms last`,
		u32(math.round(global_state.fps.average)), " (VSYNC)" if settings.vsync else "", global_state.last_frame.average,
		u32(math.round(global_state.tps.average)), global_state.last_update.average,
	)

	pos: [2]int
	pos.x = int(f32(gl_state.viewport[2]) / gl_state.scale) - 2
	pos.y = int(f32(gl_state.viewport[3]) / gl_state.scale) - 2
	pos -= measure_text(general_font, text)
	gl_draw_text(general_font, text, pos)
}
