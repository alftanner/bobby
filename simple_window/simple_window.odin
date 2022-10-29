package simple_window

import "core:runtime"
import "core:image"
//import "core:log"

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
	using specific: Window_OS_Specific,
}

create :: proc(
	w: int = -1, h: int = -1,
	name: string = "Window",
	flags: Window_Flags = {},
) -> (window: ^Window, ok: bool) {
	@static initialized: bool
	if !initialized {
		context.allocator = runtime.default_allocator()
		thread_context.init_ctx = context
		// NOTE: it is possible for event handler to be set before creating a window
		if thread_context.event_handler == nil {
			thread_context.event_handler = default_event_handler
		}

		initialized = true
	}

	context = thread_context.init_ctx

	if _, exists := window_handle.?; exists do return

	window, ok = _create(name, w, h, flags)
	if !ok do return

	return
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

set_event_handler :: proc(handler: Event_Handler_Proc, ctx: Maybe(runtime.Context) = nil) {
	if handler != nil {
		thread_context.event_handler = handler
	} else {
		thread_context.event_handler = default_event_handler
	}
	thread_context.event_ctx = ctx.? or_else runtime.default_context()
}

// TODO: support multiple monitors
get_working_area :: #force_inline proc() -> Rect { return _get_working_area() }

move :: #force_inline proc(window: ^Window, x, y: int) { _move(window, x, y) }

resize :: #force_inline proc(window: ^Window, w, h: int) { _resize(window, w, h) }

set_resizable :: #force_inline proc(window: ^Window, resizable: bool) { _set_resizable(window, resizable) }

set_min_size :: #force_inline proc(window: ^Window, w, h: int) {
	window.min_w, window.min_h = w, h
	_resize(window, window.client.w, window.client.h) // TODO: other platforms might work in a different way
}

display_pixels :: #force_inline proc(window: ^Window, canvas: Texture2D, dest: Rect, clear := true) { _display_pixels(window, canvas, dest, clear) }

set_clear_color :: proc(window: ^Window, color: image.RGB_Pixel) {
	window.clear_color = color
	_set_clear_color(window, color)
}

// TODO: bug
// wait_vblank :: _wait_vblank

wait_vblank :: #force_inline proc() { _wait_vblank() }
