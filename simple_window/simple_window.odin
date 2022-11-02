package simple_window

import "core:runtime"
import "core:image"

/*
TODO:
set_fullscreen(.NONE/.FULLSCREEN/.BORDERLESS)
maximize()
minimize()
*/

Window_Flag :: enum {
	// No automatic canvas management
	NoCanvas,
	// TODO: Maximized, Minimized, Hidden(?), Fullscreen, Borderless(?), InputGrabbed(?)
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

Window :: struct {
	// can modify
	must_close: bool,

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
	clear_color:          image.RGB_Pixel,

	// read-only, not very useful
	min_w, min_h: int,
	dec_w, dec_h: int, // TODO: remove decorations and use custom window chrome???
	flags:        Window_Flags,

	// internal
	event_handler: Event_Handler_Proc,
	event_context: Maybe(runtime.Context),
	using specific: Window_OS_Specific,
}

@private window_handle: Maybe(Window)

create :: proc(w: int = -1, h: int = -1, name: string = "Window", flags: Window_Flags = {}) -> (window: ^Window) {
	return _create(name, w, h, flags)
}

destroy :: proc(window: ^Window) {
	_destroy(window)
	window_handle = nil
}

run :: proc(window: ^Window) {
	for !window.must_close {
		_next_event(window)
	}
}

set_event_handler :: proc(window: ^Window, handler: Event_Handler_Proc, event_context: Maybe(runtime.Context) = nil) {
	window.event_handler = handler
	window.event_context = event_context
}

get_working_area :: #force_inline proc() -> Rect { return _get_working_area() }

move :: #force_inline proc(window: ^Window, x, y: int) { _move(window, x, y) }

resize :: #force_inline proc(window: ^Window, w, h: int) { _resize(window, w, h) }

set_resizable :: #force_inline proc(window: ^Window, resizable: bool) { _set_resizable(window, resizable) }

set_min_size :: #force_inline proc(window: ^Window, w, h: int) {
	window.min_w, window.min_h = w, h
	_resize(window, window.client.w, window.client.h)
}

display_pixels :: #force_inline proc(window: ^Window, canvas: Texture2D, dest: Rect, clear := true) { _display_pixels(window, canvas, dest, clear) }

set_clear_color :: proc "contextless" (window: ^Window, color: image.RGB_Pixel) {
	window.clear_color = color
	_set_clear_color(window, color)
}

// TODO: bug
// wait_vblank :: _wait_vblank

wait_vblank :: #force_inline proc() { _wait_vblank() }
