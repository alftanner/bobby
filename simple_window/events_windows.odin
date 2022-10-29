//+build windows
//+private
package simple_window

import win32 "core:sys/windows"

import "core:log"

_next_event :: proc(window: ^Window) {
	msg: win32.MSG = ---
	win32.GetMessageW(&msg, window.id, 0, 0)
	win32.TranslateMessage(&msg)
	win32.DispatchMessageW(&msg)
}

_default_window_proc :: proc "stdcall" (winid: win32.HWND, msg: win32.UINT, wparam: win32.WPARAM, lparam: win32.LPARAM) -> (result: win32.LRESULT) {
	context = thread_context.init_ctx

	window, ok := &window_handle.?
	if !ok {
		return win32.DefWindowProcW(winid, msg, wparam, lparam)
	}

	ev: Event

	switch msg {
	case win32.WM_INPUTLANGCHANGE:
		log.debugf("IC {:x}: {:x} {:x}", msg, wparam, lparam)
	case win32.WM_INPUTLANGCHANGEREQUEST:
		log.debugf("ICR {:x}: {:x} {:x}", msg, wparam, lparam)
	case win32.WM_WINDOWPOSCHANGING: // limit window size, if need be
		pos := cast(^win32.WINDOWPOS)cast(uintptr)lparam

		dw, dh := window.dec_w, window.dec_h
		cw, ch := cast(int)pos.cx - dw, cast(int)pos.cy - dh

		if window.min_w > 0 do cw = max(cw, window.min_w)
		if window.min_h > 0 do ch = max(ch, window.min_h)

		px, py := cast(int)pos.x, cast(int)pos.y
		// correct position when resizing from top/left
		if window.mode == .Resizing {
			if px > window.x && window.client.w > window.min_w {
				px = min(px, window.x + window.client.w - window.min_w)
			} else {
				px = min(px, window.x)
			}

			if py > window.y && window.client.h > window.min_h {
				py = min(py, window.y + window.client.h - window.min_h)
			} else {
				py = min(py, window.y)
			}
		}
		pos.x = cast(i32)px
		pos.y = cast(i32)py

		pos.cx, pos.cy = i32(cw + dw), i32(ch + dh)
	case win32.WM_WINDOWPOSCHANGED:
		pos := cast(^win32.WINDOWPOS)cast(uintptr)lparam

		rect: win32.RECT
		point: win32.POINT
		win32.GetClientRect(winid, &rect)
		win32.ClientToScreen(winid, &point)

		window.rect   = {cast(int)pos.x, cast(int)pos.y, cast(int)pos.cx, cast(int)pos.cy}
		window.client = {cast(int)point.x, cast(int)point.y, cast(int)rect.right, cast(int)rect.bottom}
	case win32.WM_SYSCOMMAND:
		switch t := win32.GET_SC_WPARAM(wparam); t {
		case win32.SC_SIZE:
			window.mode = .Resizing
		case win32.SC_MOVE:
			window.mode = .Moving
		}
	case win32.WM_ENTERSIZEMOVE:
		#partial switch window.mode {
		case .Resizing:
			ev = Resize_Event{
				type = .Start,
			}
		case .Moving:
			ev = Move_Event{
				type = .Start,
			}
		}
	case win32.WM_EXITSIZEMOVE:
		mode := window.mode
		window.mode = .Regular

		#partial switch mode {
		case .Resizing:
			ev = Resize_Event{
				type = .End,
			}
		case .Moving:
			ev = Move_Event{
				type = .End,
			}
		}
	case win32.WM_SIZE:
		resize_type: Resize_Type

		switch wparam {
		case win32.SIZE_RESTORED:
			resize_type = .Default
		case win32.SIZE_MAXIMIZED:
			resize_type = .Maximized
		case win32.SIZE_MINIMIZED:
			resize_type = .Minimized
		}

		window.is_minimized = resize_type == .Minimized

		ev = Resize_Event{
			type = resize_type,
		}
	case win32.WM_MOVE:
		window.is_minimized = window.x == -32000 && window.y == -32000

		ev = Move_Event{
			type = .Minimized if window.is_minimized else .Default,
		}
	case win32.WM_NCACTIVATE: // this is like WM_ACTIVATEAPP but better (or so it seems)
		window.is_focused = bool(wparam)
		for key in &window.is_key_down do key = false
		ev = Focus_Event{window.is_focused}
	case win32.WM_ERASEBKGND:
		return 1
	case win32.WM_PAINT:
		winrect: win32.RECT = ---
		if win32.GetUpdateRect(winid, &winrect, false) {
			win32.ValidateRect(winid, nil)
		}
		ev = Draw_Event{}
	case win32.WM_CHAR:
		ev = Character_Event{
			character = cast(rune)wparam,
		}
	case win32.WM_KEYDOWN, win32.WM_KEYUP, win32.WM_SYSKEYDOWN, win32.WM_SYSKEYUP:
		key: Key_Code
		state: Key_State

		scancode := u32(lparam & 0x00ff0000) >> 16
		extended := (lparam & 0x01000000) != 0
		was_pressed := (lparam & (1 << 31)) == 0
		was_released := (lparam & (1 << 30)) != 0
		alt_was_down := (lparam & (1 << 29)) != 0

		if was_pressed && was_released {
			state = .Repeat
		} else if was_released {
			state = .Released
		} else {
			state = .Pressed
		}

		// TODO: Meta key seems to be 0x5b - check on other computers
		key = vk_conversation_table[wparam] or_else .Unknown

		switch wparam {
		case win32.VK_CONTROL:
			key = .RControl if extended else .LControl
		case win32.VK_MENU:
			key = .RAlt if extended else .LAlt
		case win32.VK_SHIFT:
			is_right := win32.MapVirtualKeyW(scancode, win32.MAPVK_VSC_TO_VK_EX) == win32.VK_RSHIFT
			key = .RShift if is_right else .LShift
		}

		if state == .Pressed && alt_was_down && key == .F4 {
			window.must_close = true
		}

		window.is_key_down[key] = (state != .Released)

		ev = Keyboard_Event{
			scancode = scancode,
			key = key,
			state = state,
		}
	case win32.WM_LBUTTONDOWN, win32.WM_RBUTTONDOWN, win32.WM_MBUTTONDOWN, win32.WM_XBUTTONDOWN,
	win32.WM_LBUTTONUP, win32.WM_RBUTTONUP, win32.WM_MBUTTONUP, win32.WM_XBUTTONUP,
	win32.WM_LBUTTONDBLCLK, win32.WM_RBUTTONDBLCLK, win32.WM_MBUTTONDBLCLK, win32.WM_XBUTTONDBLCLK:
		mev: Mouse_Button_Event

		switch msg {
		case win32.WM_LBUTTONDOWN, win32.WM_RBUTTONDOWN, win32.WM_MBUTTONDOWN, win32.WM_XBUTTONDOWN,
		win32.WM_LBUTTONDBLCLK, win32.WM_RBUTTONDBLCLK, win32.WM_MBUTTONDBLCLK, win32.WM_XBUTTONDBLCLK:
			win32.SetCapture(winid)
			mev.clicked = true
		case:
			win32.ReleaseCapture()
			mev.clicked = false
		}

		switch msg {
		case win32.WM_LBUTTONDOWN, win32.WM_LBUTTONUP, win32.WM_LBUTTONDBLCLK:
			mev.button = .Left
		case win32.WM_RBUTTONDOWN, win32.WM_RBUTTONUP, win32.WM_RBUTTONDBLCLK:
			mev.button = .Right
		case win32.WM_MBUTTONDOWN, win32.WM_MBUTTONUP, win32.WM_MBUTTONDBLCLK:
			mev.button = .Middle
		case win32.WM_XBUTTONDOWN, win32.WM_XBUTTONUP, win32.WM_XBUTTONDBLCLK:
			mev.button = .X1 if win32.GET_XBUTTON_WPARAM(wparam) == win32.XBUTTON1 else .X2
		}

		switch msg {
		case win32.WM_LBUTTONDBLCLK, win32.WM_RBUTTONDBLCLK, win32.WM_MBUTTONDBLCLK, win32.WM_XBUTTONDBLCLK:
			mev.double_clicked = true
		}

		window.is_mouse_button_down[mev.button] = mev.clicked

		ev = mev
	case win32.WM_MOUSEMOVE:
		if !window.is_mouse_inside {
			window.is_mouse_inside = true
			tme: win32.TRACKMOUSEEVENT = {
				cbSize = size_of(win32.TRACKMOUSEEVENT),
				dwFlags = win32.TME_LEAVE,
				hwndTrack = winid,
			}
			win32.TrackMouseEvent(&tme)
		}

		x := cast(i32)win32.LOWORD(cast(win32.DWORD)lparam)
		y := cast(i32)win32.HIWORD(cast(win32.DWORD)lparam)

		ev = Mouse_Move_Event{x, y}
	case win32.WM_MOUSELEAVE:
		window.is_mouse_inside = false
		ev = Mouse_Move_Event{-1, -1}
	case win32.WM_MOUSEWHEEL:
		delta := win32.GET_WHEEL_DELTA_WPARAM(wparam) / 120
		ev = Mouse_Wheel_Event{
			delta = delta,
		}
	case win32.WM_CLOSE:
		window.must_close = true
		ev = Close_Event{}
	}

	if ev != nil {
		context = thread_context.event_ctx
		thread_context.event_handler(window, ev)
	}

	if _, ok := ev.(Close_Event); ok && !window.must_close {
		return 0
	}

	return win32.DefWindowProcW(winid, msg, wparam, lparam)
}
