package simple_window

import "core:runtime"

Thread_Context :: struct {
	init_ctx:      runtime.Context,
	event_ctx:     runtime.Context,
	event_handler: Event_Handler_Proc,
}

@private @thread_local window_handle: Maybe(Window)
@private @thread_local thread_context: Thread_Context

@private default_event_handler :: proc(window: ^Window, event: Event) { return }
