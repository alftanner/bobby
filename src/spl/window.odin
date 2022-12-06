package spl

import "core:image"

/*
TODO:
set_fullscreen(.NONE/.FULLSCREEN/.BORDERLESS)
maximize()
minimize()
*/

Window_Flag :: enum {
	Hide_Cursor,
	// TODO: Maximized, Minimized, Hidden(?), Fullscreen, Borderless(?)
}
Window_Flags :: distinct bit_set[Window_Flag; u8]

Fullscreen_Type :: enum {
	None,
	Fullscreen,
	Borderless,
}

Window_Mode :: enum {
	Regular,
	Moving,
	Resizing,
}

Rect :: struct {
	using pos: [2]int,
	size: [2]int,
}

Window :: struct {
	// can modify
	must_close: bool,
	clear_color: image.RGB_Pixel,

	// read-only
	using rect:           Rect,
	client:               Rect,
	is_key_down:          [Key_Code]bool,
	is_mouse_button_down: [Mouse_Button]bool,
	fullscreen:           Fullscreen_Type,
	is_minimized:         bool,
	is_focused:           bool,
	is_mouse_inside:      bool,
	mode:                 Window_Mode,

	// read-only, not very useful
	min_w, min_h: int,
	dec_w, dec_h: int, // TODO: remove decorations and use custom window chrome???
	flags:        Window_Flags,

	// internal
	using specific: Window_OS_Specific,
}

create :: proc(window: ^Window, pos: [2]int = {-1, -1}, size: [2]int = {-1, -1}, name: string = "Window", flags: Window_Flags = {}) -> bool {
	return _create(window, pos, size, name, flags)
}

destroy :: #force_inline proc(window: ^Window) { _destroy(window) }

next_event :: #force_inline proc(window: ^Window) -> Event { return _next_event(window) }

send_user_event :: #force_inline proc(window: ^Window, ev: User_Event) { _send_user_event(window, ev) }

get_working_area :: #force_inline proc() -> Rect { return _get_working_area() }

move :: #force_inline proc(window: ^Window, pos: [2]int) { _move(window, pos) }

resize :: #force_inline proc(window: ^Window, size: [2]int) { _resize(window, size) }

set_resizable :: #force_inline proc(window: ^Window, resizable: bool) { _set_resizable(window, resizable) }

set_min_size :: #force_inline proc(window: ^Window, size: [2]int) {
	window.min_w, window.min_h = size[0], size[1]
	_resize(window, window.client.size)
}

display_pixels :: #force_inline proc(window: ^Window, pixels: [][4]u8, pixels_size: [2]int, dest: Rect) { _display_pixels(window, pixels, pixels_size, dest) }

// TODO: bug
//wait_vblank :: _wait_vblank

wait_vblank :: #force_inline proc() { _wait_vblank() }
