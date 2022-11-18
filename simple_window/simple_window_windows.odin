//+private
package simple_window

import "core:image"
import "core:thread"
import "core:runtime"
import win32 "core:sys/windows"

Window_OS_Specific :: struct {
	id: win32.HWND,
}

// need to store pointer to the window for _default_window_proc
@private window_handle: ^Window

_create :: proc "contextless" (window: ^Window, w, h: int, title: string, flags: Window_Flags) -> bool {
	if window_handle != nil {
		return false
	}

	instance := cast(win32.HINSTANCE)win32.GetModuleHandleW(nil)
	black_brush := cast(win32.HBRUSH)win32.GetStockObject(win32.BLACK_BRUSH)
	icon := win32.LoadIconA(nil, win32.IDI_APPLICATION)
	cursor := win32.LoadCursorA(nil, win32.IDC_ARROW)

	window_title: win32.wstring
	{
		context = runtime.default_context()
		window_title = win32.utf8_to_wstring(title)
	}
	class_style := win32.CS_OWNDC | win32.CS_HREDRAW | win32.CS_VREDRAW | win32.CS_DBLCLKS
	window_style := win32.WS_VISIBLE | win32.WS_OVERLAPPEDWINDOW &~ win32.WS_THICKFRAME &~ win32.WS_MAXIMIZEBOX

	w, h := i32(w), i32(h)

	if w < 0 do w = win32.CW_USEDEFAULT
	if h < 0 do h = win32.CW_USEDEFAULT

	// Windows will make a window with specified size as window size, not as client size, AdjustWindowRect gets the client size needed
	if w >= 0 || h >= 0 {
		crect: win32.RECT = {0, 0, w, h}
		win32.AdjustWindowRect(&crect, window_style, false)

		if w >= 0 do w = crect.right - crect.left
		if h >= 0 do h = crect.bottom - crect.top
	}

	window_class: win32.WNDCLASSW = {
		style = class_style,
		lpfnWndProc = _default_window_proc,
		hInstance = instance,
		hIcon = icon,
		hCursor = cursor,
		hbrBackground = black_brush,
		lpszClassName = window_title,
		// TODO(?): hIconSm sets the icon in the task manager
	}
	win32.RegisterClassW(&window_class)

	winid := win32.CreateWindowW(
		lpClassName = window_title, lpWindowName = window_title, dwStyle = window_style, lpParam = nil,
		X = win32.CW_USEDEFAULT, Y = win32.CW_USEDEFAULT, nWidth = w, nHeight = h,
		hWndParent = nil, hMenu = nil, hInstance = instance,
	)

	if winid == nil {
		return false
	}

	// get decorations size
	wr, cr: win32.RECT
	point: win32.POINT
	win32.GetWindowRect(winid, &wr)
	win32.GetClientRect(winid, &cr)
	win32.ClientToScreen(winid, &point)
	dec_w, dec_h := int(wr.right - wr.left - cr.right), int(wr.bottom - wr.top - cr.bottom)

	is_focused := win32.GetForegroundWindow() == winid
	win32.PostMessageW(winid, win32.WM_NCACTIVATE, cast(uintptr)is_focused, 0)

	window^ = {
		specific = {
			id = winid,
		},
		rect = {
			cast(int)wr.left,
			cast(int)wr.top,
			cast(int)wr.right - cast(int)wr.left,
			cast(int)wr.bottom - cast(int)wr.top,
		},
		client = {
			cast(int)point.x,
			cast(int)point.y,
			cast(int)cr.right,
			cast(int)cr.bottom,
		},
		flags = flags, dec_w = dec_w, dec_h = dec_h,
		is_focused = is_focused,
	}

	window_handle = window

	return true
}

_destroy :: proc(window: ^Window) {
	win32.DestroyWindow(window.id)
	window_handle = nil
}

_get_working_area :: #force_inline proc() -> Rect {
	winrect: win32.RECT
	win32.SystemParametersInfoW(win32.SPI_GETWORKAREA, 0, &winrect, 0)
	return {
		cast(int)winrect.left,
		cast(int)winrect.top,
		cast(int)(winrect.right - winrect.left),
		cast(int)(winrect.bottom - winrect.top),
	}
}

_move :: proc(window: ^Window, x, y: int) {
	win32.SetWindowPos(window.id, nil, i32(x), i32(y), 0, 0, win32.SWP_NOSIZE | win32.SWP_NOZORDER | win32.SWP_NOACTIVATE)
}

_resize :: proc(window: ^Window, w, h: int) {
	w, h := i32(w), i32(h)
	crect: win32.RECT = {0, 0, w, h}

	style := cast(u32)win32.GetWindowLongPtrW(window.id, win32.GWL_STYLE)
	win32.AdjustWindowRect(&crect, style, false)
	w, h = crect.right - crect.left, crect.bottom - crect.top
	win32.SetWindowPos(window.id, nil, 0, 0, w, h, win32.SWP_NOMOVE | win32.SWP_NOZORDER)
}

_set_resizable :: proc(window: ^Window, resizable: bool) {
	winid := window.id
	style := cast(u32)win32.GetWindowLongPtrW(winid, win32.GWL_STYLE)
	if resizable {
		style |= win32.WS_THICKFRAME
		style |= win32.WS_MAXIMIZEBOX
	} else {
		style &~= win32.WS_THICKFRAME
		style &~= win32.WS_MAXIMIZEBOX
	}
	win32.SetWindowLongPtrW(winid, win32.GWL_STYLE, cast(int)style)
}

_display_pixels :: proc(window: ^Window, canvas: Texture2D, dest: Rect) {
	bitmap_info: win32.BITMAPINFO = {
		bmiHeader = {
			biSize = size_of(win32.BITMAPINFOHEADER),
			biPlanes = 1,
			biBitCount = 32,
			biCompression = win32.BI_RGB,
			biWidth = cast(i32)canvas.w,
			biHeight = -cast(i32)canvas.h,
		},
	}

	dc := win32.GetDC(window.id)
	defer win32.ReleaseDC(window.id, dc)

	win32.SelectObject(dc, win32.GetStockObject(win32.DC_BRUSH))
	win32.SetDCBrushColor(dc, win32.RGB(expand_to_tuple(window.clear_color)))

	{ // clear
		dx, dy, dr, db, cw, ch: i32
		dx = i32(dest.x)
		dy = i32(dest.y)
		dr = dx + i32(dest.w)
		db = dy + i32(dest.h)
		cw = i32(window.client.w)
		ch = i32(window.client.h)

		if dx > 0 do win32.PatBlt(dc, 0, 0, dx, ch, win32.PATCOPY)
		if dr < cw do win32.PatBlt(dc, dr, 0, cw - dr, ch, win32.PATCOPY)
		if dy > 0 do win32.PatBlt(dc, dx, 0, dr - dx, dy, win32.PATCOPY)
		if db < ch do win32.PatBlt(dc, dx, db, dr - dx, ch - db, win32.PATCOPY)
	}

	win32.StretchDIBits(
		dc,
		cast(i32)dest.x, cast(i32)dest.y, cast(i32)dest.w, cast(i32)dest.h,
		0, 0, cast(i32)canvas.w, cast(i32)canvas.h, raw_data(canvas.pixels),
		&bitmap_info, win32.DIB_RGB_COLORS, win32.SRCCOPY,
	)
}

_wait_vblank :: win32.DwmFlush
