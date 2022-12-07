package main

import "core:fmt"
import "core:math"
import "core:time"
import "core:sync"
import "core:slice"
import "core:image"
import "core:strconv"
import "core:container/small_array"

import "spl"

get_frame_delta :: proc(previous_tick: time.Tick, tick_time: time.Duration) -> f32 {
	return f32(time.duration_milliseconds(time.tick_diff(previous_tick, time.tick_now())) / time.duration_milliseconds(tick_time))
}

render_software :: proc(timer: ^spl.Timer) {
	// local world state
	@static local_world: World
	@static local_level: Level
	@static local_settings: Settings
	// rendering stuff
	@static canvas, scene_texture: Texture2D
	@static canvas_cache, canvas_cache_slow: Region_Cache
	@static tiles_updated: Tile_Queue
	@static backgrounds: [Campaign]Texture2D
	// other state
	@static previous_tick: time.Tick
	@static tick_time: time.Duration
	@static offset: [2]f32
	@static intro_alpha: u8

	@static init: bool
	if !init {
		init = true

		canvas = texture_make(BUFFER_W, BUFFER_H)
		scene_texture = texture_make(BUFFER_W, BUFFER_H)
		for bg, c in &backgrounds {
			bg = texture_make(BUFFER_W + TILE_SIZE, BUFFER_H + TILE_SIZE)

			sprite := sprites[.Grass if c == .Carrot_Harvest else .Ground]
			for y in 0..=TILES_H do for x in 0..=TILES_W {
				pos: [2]int = {x, y}
				draw_from_texture_software(&bg, textures[.Atlas], pos * TILE_SIZE, sprite)
			}
		}
	}

	start_tick := time.tick_now()

	canvas_redraw, cache_slow_redraw, scene_redraw: bool

	old_fade := local_world.fade
	old_scene := local_world.scene
	old_scoreboard_page := local_world.scoreboard_page
	old_selected_option := local_world.selected_option
	old_selected_levels := local_settings.selected_levels
	old_language := local_settings.language
	old_campaign := local_settings.campaign

	if sync.atomic_load(&world_updated) {
		sync.guard(&world_lock)
		defer sync.atomic_store(&world_updated, false)

		if copy_level(&local_level, &world_level, &tiles_updated) {
			scene_redraw = true
		}

		local_world = world
		local_settings = settings
		previous_tick = global_state.previous_tick
		tick_time = sync.atomic_load(&global_state.tick_time)
	}

	if old_scene != local_world.scene || old_campaign != local_settings.campaign {
		scene_redraw = true
	}
	if old_scoreboard_page != local_world.scoreboard_page || old_selected_option != local_world.selected_option ||
	old_selected_levels != local_settings.selected_levels || old_language != local_settings.language ||
	old_fade.state || local_world.fade.state {
		cache_slow_redraw = true
	}

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

	draw_world_background: bool
	#partial switch local_world.scene {
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
				pos: [2]int = {tile_idx%local_level.size[0], tile_idx/local_level.size[0]}
				sprite := get_sprite_from_pos(pos, local_level)

				region: Rect
				region.pos = (pos * TILE_SIZE) + lvl_offset
				region.size = {TILE_SIZE, TILE_SIZE}

				draw_from_texture_software(&scene_texture, textures[.Atlas], region.pos, sprite)
				small_array.push_back(&canvas_cache, region)
			}
		} else {
			small_array.clear(&tiles_updated)
		}
	case .Intro: // do not redraw the intro after alpha became 0
		old_intro_alpha := intro_alpha
		intro_alpha = get_intro_alpha(local_world.intro, get_frame_delta(previous_tick, tick_time))
		if old_intro_alpha != 0 || intro_alpha != 0 {
			scene_redraw = true
		}
	}

	if scene_redraw {
		switch local_world.scene {
		case .Game:
			lvl_offset: [2]int
			lvl_offset.x = int(offset.x * TILE_SIZE)
			lvl_offset.y = int(offset.y * TILE_SIZE)

			if draw_world_background { // TODO: only draw needed parts, not the entire thing
				bg_rect: Rect
				bg_rect.pos.x = int(abs(offset.x - f32(int(offset.x))) * TILE_SIZE)
				bg_rect.pos.y = int(abs(offset.y - f32(int(offset.y))) * TILE_SIZE)
				bg_rect.size = backgrounds[.Carrot_Harvest].size - bg_rect.pos
				draw_from_texture_software(&scene_texture, backgrounds[.Carrot_Harvest], {}, bg_rect)
			}
			for _, idx in local_level.tiles {
				pos: [2]int = {idx%local_level.size[0], idx/local_level.size[0]}
				sprite := get_sprite_from_pos(pos, local_level)
				draw_from_texture_software(&scene_texture, textures[.Atlas], (pos * TILE_SIZE) + lvl_offset, sprite)
			}
		case .Pause_Menu, .Main_Menu, .Scoreboard:
			texture := backgrounds[local_settings.campaign]
			if local_world.scene == .Pause_Menu {
				texture = canvas
			}
			draw_from_texture_software(&scene_texture, texture, {}, {{}, scene_texture.size})
			draw_rect_software(&scene_texture, {{}, scene_texture.size}, {0, 0, 0, 0xAA})
		case .Intro:
			slice.fill(scene_texture.pixels, BLACK)

			off := (scene_texture.size - INTRO_SPLASH.size) / 2
			draw_from_texture_software(&scene_texture, textures[.Splashes], off, INTRO_SPLASH)
			draw_rect_software(&scene_texture, {off, INTRO_SPLASH.size}, {0, 0, 0, intro_alpha})
		case .End:
			slice.fill(scene_texture.pixels, BLACK)

			off := (scene_texture.size - END_SPLASH.size) / 2
			draw_from_texture_software(&scene_texture, textures[.Splashes], off, END_SPLASH)
		case .Credits:
			slice.fill(scene_texture.pixels, BLACK)

			draw_credits_software(&scene_texture, local_settings.language)
		case .None:
			slice.fill(scene_texture.pixels, BLACK)
		}

		canvas_redraw = true
	}

	if canvas_redraw {
		small_array.clear(&canvas_cache)
		small_array.clear(&canvas_cache_slow)
		draw_from_texture_software(&canvas, scene_texture, {}, {{}, scene_texture.size})
	} else { // cached rendering
		for cache_region in small_array.pop_back_safe(&canvas_cache) {
			draw_from_texture_software(&canvas, scene_texture, cache_region.pos, cache_region)
		}
	}

	if canvas_redraw || cache_slow_redraw {
		for cache_region in small_array.pop_back_safe(&canvas_cache_slow) {
			draw_from_texture_software(&canvas, scene_texture, cache_region.pos, cache_region)
		}

		// slow cached drawing
		#partial switch local_world.scene {
		case .Main_Menu, .Pause_Menu:
			draw_menu_software(&canvas, &canvas_cache_slow, small_array.slice(&local_world.menu_options), local_world.selected_option)
		case .Scoreboard:
			draw_scoreboard_software(&canvas, &canvas_cache_slow, small_array.slice(&local_world.scoreboard), local_world.scoreboard_page)
		}
	}

	// do scene specific drawing that gets into fast cache, such as player/HUD/etc
	if local_world.scene == .Game {
		// draw player
		if !local_level.ended || (local_level.ended && local_world.player.fading.state) {
			pos := (player_pos + offset) * TILE_SIZE
			px := int(pos.x) + local_world.player.sprite.offset.x
			py := int(pos.y) + local_world.player.sprite.offset.y
			draw_from_texture_software(&canvas, textures[.Atlas], {px, py}, local_world.player.sprite)
			small_array.push_back(&canvas_cache, Rect{{px, py}, local_world.player.sprite.size})
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
				small_array.push_back(&canvas_cache, draw_text_software(&canvas, hud_font, time_str, {2, 2}))
			}
			// level begin screen
			if time.duration_seconds(local_level.score.time) < 2 {
				tbuf: [16]byte
				level_str := fmt.bprintf(tbuf[:], "{} {}", language_strings[settings.language][.Level], local_level.current + 1)
				size := measure_text(general_font, level_str)
				pos := (canvas.size - size) / 2
				small_array.push_back(&canvas_cache, draw_text_software(&canvas, general_font, level_str, pos))
			}
			// right part
			{
				pos: [2]int = {canvas.size[0] - 2, 2}

				if local_level.carrots > 0 {
					sprite := hud_sprites[.Carrot]
					pos.x -= sprite.size[0]
					draw_from_texture_software(&canvas, textures[.Atlas], pos, sprite)
					small_array.push_back(&canvas_cache, Rect{pos, sprite.size})
					pos.x -= 2

					tbuf: [8]byte
					str := strconv.itoa(tbuf[:], local_level.carrots)
					{
						size := measure_text(hud_font, str)
						pos.x -= size[0]
					}
					small_array.push_back(&canvas_cache, draw_text_software(&canvas, hud_font, str, {pos.x, pos.y + 3}))
					pos.y += sprite.size[1] + 2
					pos.x = canvas.size[0] - 2
				}

				if local_level.eggs > 0 {
					sprite := hud_sprites[.Egg]
					pos.x -= sprite.size[0]
					draw_from_texture_software(&canvas, textures[.Atlas], pos, sprite)
					small_array.push_back(&canvas_cache, Rect{pos, sprite.size})
					pos.x -= 2

					tbuf: [8]byte
					str := strconv.itoa(tbuf[:], local_level.eggs)
					{
						size := measure_text(hud_font, str)
						pos.x -= size[0]
					}
					small_array.push_back(&canvas_cache, draw_text_software(&canvas, hud_font, str, {pos.x, pos.y + 3}))
					pos.y += sprite.size[1] + 2
					pos.x = canvas.size[0] - 2
				}

				if local_world.player.silver_key {
					sprite := hud_sprites[.Silver_Key]
					pos.x -= sprite.size[0]
					draw_from_texture_software(&canvas, textures[.Atlas], pos, sprite)
					small_array.push_back(&canvas_cache, Rect{pos, sprite.size})
					pos.x -= 2
				}
				if local_world.player.golden_key {
					sprite := hud_sprites[.Golden_Key]
					pos.x -= sprite.size[0]
					draw_from_texture_software(&canvas, textures[.Atlas], pos, sprite)
					small_array.push_back(&canvas_cache, Rect{pos, sprite.size})
					pos.x -= 2
				}
				if local_world.player.copper_key {
					sprite := hud_sprites[.Copper_Key]
					pos.x -= sprite.size[0]
					draw_from_texture_software(&canvas, textures[.Atlas], pos, sprite)
					small_array.push_back(&canvas_cache, Rect{pos, sprite.size})
					pos.x -= 2
				}
			}
		}

		// level end screen
		if local_level.ended && !local_world.player.fading.state {
			total_h: int
			success := hud_sprites[.Success]
			success_x := (canvas.size[0] - success.size[0]) / 2
			total_h += success.size[1] + (general_font.glyph_size[1] * 2)

			tbuf: [64]byte
			time_str := fmt.bprintf(tbuf[:32], "{}: {:02i}:{:02i}:{:02i}",
				language_strings[settings.language][.Time],
				int(time.duration_minutes(local_level.score.time)),
				int(time.duration_seconds(local_level.score.time)) % 60,
				int(time.duration_milliseconds(local_level.score.time)) % 60,
			)
			time_x, time_h: int
			{
				size := measure_text(general_font, time_str)
				time_x = (canvas.size[0] - size[0]) / 2
				time_h = size[1]
			}
			total_h += time_h + general_font.glyph_size[1]

			steps_str := fmt.bprintf(tbuf[32:], "{}: {}", language_strings[settings.language][.Steps], local_level.score.steps)
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
			draw_from_texture_software(&canvas, textures[.Atlas], pos, success)
			small_array.push_back(&canvas_cache, Rect{pos, success.size})
			pos.y += success.size[1] + (general_font.glyph_size[1] * 2)

			small_array.push_back(&canvas_cache, draw_text_software(&canvas, general_font, time_str, {time_x, pos.y}))
			pos.y += time_h + general_font.glyph_size[1]

			small_array.push_back(&canvas_cache, draw_text_software(&canvas, general_font, steps_str, {steps_x, pos.y}))
			pos.y += steps_h + (general_font.glyph_size[1] * 2)

			small_array.push_back(&canvas_cache, draw_text_software(&canvas, general_font, hint_str, {hint_x, pos.y}))
		}
	}

	fade_alpha := get_fade_alpha(local_world.fade, get_frame_delta(previous_tick, tick_time))
	if fade_alpha != 0 {
		draw_rect_software(&canvas, {{}, canvas.size}, {0, 0, 0, fade_alpha})
		small_array.clear(&canvas_cache_slow)
		small_array.clear(&canvas_cache)
		small_array.push_back(&canvas_cache, Rect{{}, canvas.size})
	}

	if settings.show_stats {
		calculate_stats()
		small_array.push_back(&canvas_cache, draw_stats_software(&canvas))
	}

	sync.atomic_store(&global_state.frame_work, time.tick_since(start_tick))

	if settings.vsync {
		display_software(&canvas)
		// TODO: if i send the event to another thread, it will block 99% when i exit
		//spl.send_user_event(&window, {data = &canvas})
		spl.wait_vblank()
		sync.atomic_store(&global_state.frame_time, time.tick_since(start_tick))
	} else {
		spl.wait_timer(timer)
		sync.atomic_store(&global_state.frame_time, time.tick_since(start_tick))
		display_software(&canvas)
	}
}

display_software :: proc(canvas: ^Texture2D) {
	client_size := get_from_i64(&global_state.client_size)
	scale := get_buffer_scale(client_size[0], client_size[1])
	buf_w, buf_h := BUFFER_W * scale, BUFFER_H * scale
	off_x := (cast(int)client_size[0] - buf_w) / 2
	off_y := (cast(int)client_size[1] - buf_h) / 2
	spl.display_pixels(&window, canvas.pixels, canvas.size, {{off_x, off_y}, {buf_w, buf_h}})
}

draw_scoreboard_software :: proc(t: ^Texture2D, q: ^Region_Cache, labels: []Text_Label, page: int) {
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

		draw_text_software(t, general_font, text, region.pos, SELECTED)
		small_array.push_back(q, region)

		y += region.size[1] + general_font.glyph_size[1]
	}

	{
		color := SELECTED
		if page == 0 {
			color = DISABLED
		}
		draw_from_texture_software(t, textures[.Atlas], up_arrow.pos, UP_ARROW, {}, color)
		small_array.push_back(q, up_arrow)
	}
	{
		color := SELECTED
		if page == pages - 1 {
			color = DISABLED
		}
		draw_from_texture_software(t, textures[.Atlas], down_arrow.pos, UP_ARROW, {.Vertical}, color)
		small_array.push_back(q, down_arrow)
	}
}

draw_menu_software :: proc(t: ^Texture2D, q: ^Region_Cache, options: []Menu_Option, selected: int) {
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
			draw_from_texture_software(t, textures[.Atlas], {x, option.y - 1}, RIGHT_ARROW, {.Horizontal}, color)
			x += RIGHT_ARROW.size[0] + SPACE_BETWEEN_ARROW_AND_TEXT
			region.size[0] += (RIGHT_ARROW.size[0] + SPACE_BETWEEN_ARROW_AND_TEXT) * 2
			region.y -= 1
			region.size[1] += 2
		}

		draw_text_software(t, general_font, text, {x, option.y}, color)

		if option.arrows != nil {
			color := color
			if !option.arrows.?[1].enabled {
				color = DISABLED
			}
			x += option.size[0] + SPACE_BETWEEN_ARROW_AND_TEXT
			draw_from_texture_software(t, textures[.Atlas], {x, option.y - 1}, RIGHT_ARROW, {}, color)
		}

		small_array.push_back(q, region)
	}
}

draw_credits_software :: proc(t: ^Texture2D, language: Language) {
	str := language_strings[language][.Credits_Original]
	str2 := language_strings[language][.Credits_Remastered]

	str_size := measure_text(general_font, str)
	str2_size := measure_text(general_font, str2)
	size_h := str_size[1] + general_font.glyph_size[1] + textures[.Logo].size[1] + general_font.glyph_size[1] + str2_size[1]
	off_y := (t.size[1] - size_h) / 2

	draw_text_software(t, general_font, str, {(t.size[0] - str_size[0]) / 2, off_y})
	off_y += str_size[1] + general_font.glyph_size[1]
	draw_from_texture_software(t, textures[.Logo], {(t.size[0] - textures[.Logo].size[0]) / 2, off_y}, {{}, textures[.Logo].size})
	off_y += textures[.Logo].size[1] + general_font.glyph_size[1]
	draw_text_software(t, general_font, str2, {(t.size[0] - str2_size[0]) / 2, off_y})
}

draw_stats_software :: proc(t: ^Texture2D) -> Rect {
	tbuf: [256]byte
	text := fmt.bprintf(
		tbuf[:],
`{}FPS{} {}ms last
{}TPS {}ms last`,
		u32(math.round(global_state.fps.average)), " (VSYNC)" if settings.vsync else "", global_state.last_frame.average,
		u32(math.round(global_state.tps.average)), global_state.last_update.average,
	)

	pos: [2]int = {t.size[0] - 2, t.size[1] - 2}
	pos -= measure_text(general_font, text)
	return draw_text_software(t, general_font, text, pos)
}

draw_text_software :: #force_inline proc(
	t: ^Texture2D,
	font: Font,
	text: string,
	pos: [2]int,
	color: image.RGB_Pixel = {255, 255, 255},
	shadow_color: image.RGB_Pixel = {0, 0, 0},
) -> (region: Rect) {
	return measure_or_draw_text(.Software, t, font, text, pos, color, shadow_color)
}

// blend foreground pixel with alpha onto background
blend_pixel_software :: proc(bg: ^Color, fg: Color) {
	// NOTE: these do not necesserily correspond to RGBA mapping, colors can be in any order, as long as alpha is at the same place
	AMASK    :: 0xFF000000
	GMASK    :: 0x0000FF00
	AGMASK   :: 0xFF00FF00
	RBMASK   :: 0x00FF00FF
	ONEALPHA :: 0x01000000

	p1 := transmute(^u32)bg
	p2 := transmute(u32)fg

	a := (p2 & AMASK) >> 24
	inv_a := 255 - a
	rb := ((inv_a * (p1^ & RBMASK)) + (a * (p2 & RBMASK))) >> 8
	ag := (inv_a * ((p1^ & AGMASK) >> 8)) + (a * (ONEALPHA | ((p2 & GMASK) >> 8)))
	p1^ = (rb & RBMASK) | (ag & AGMASK)
}

pixel_mod_software :: proc(dst: ^Color, mod: Color) {
	dst.r = u8(cast(f32)dst.r * (cast(f32)mod.r / 255))
	dst.g = u8(cast(f32)dst.g * (cast(f32)mod.g / 255))
	dst.b = u8(cast(f32)dst.b * (cast(f32)mod.b / 255))
}

draw_from_texture_software :: proc(dst: ^Texture2D, src: Texture2D, pos: [2]int, src_rect: Rect, flip: bit_set[Flip] = {}, mod: image.RGB_Pixel = {255, 255, 255}) {
	needs_mod := mod != {255, 255, 255}
	mod_color := color({mod.r, mod.g, mod.b, 0})

	endx := min(pos.x + src_rect.size[0], dst.size[0])
	endy := min(pos.y + src_rect.size[1], dst.size[1])

	for y in max(0, pos.y)..<endy do for x in max(0, pos.x)..<endx {
		px, py := x - pos.x, y - pos.y
		spx := src_rect.size[0] - px - 1 if .Horizontal in flip else px
		spy := src_rect.size[1] - py - 1 if .Vertical in flip else py

		sp := (src_rect.y + spy) * src.size[0] + (src_rect.x + spx)
		dp := y * dst.size[0] + x
		src_pixel := src.pixels[sp]
		if needs_mod do pixel_mod_software(&src_pixel, mod_color)
		blend_pixel_software(&dst.pixels[dp], src_pixel)
	}
}

draw_rect_software :: proc(dst: ^Texture2D, rect: Rect, col: image.RGBA_Pixel, filled: bool = true) {
	c := color(col)
	endx := min(rect.x + rect.size[0], dst.size[0])
	endy := min(rect.y + rect.size[1], dst.size[1])

	for y in max(0, rect.y)..<endy do for x in max(0, rect.x)..<endx {
		if !filled {
			if (x != rect.x && x != rect.x + rect.size[0] - 1) && (y != rect.y && y != rect.y + rect.size[1] - 1) {
				continue
			}
		}

		dp := y * dst.size[0] + x
		blend_pixel_software(&dst.pixels[dp], c)
	}
}
