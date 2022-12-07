package gl

import win32 "core:sys/windows"

import spl ".."

_init :: proc(window: ^spl.Window, vsync: bool) -> (success: bool) {
	dc := win32.GetDC(window.id)
	defer win32.ReleaseDC(window.id, dc)

	flags: win32.DWORD = win32.PFD_SUPPORT_OPENGL | win32.PFD_DRAW_TO_WINDOW
	if vsync {
		flags |= win32.PFD_DOUBLEBUFFER
	}

	pixel_format: win32.PIXELFORMATDESCRIPTOR = {
		nSize = size_of(win32.PIXELFORMATDESCRIPTOR),
		nVersion = 1,
		iPixelType = win32.PFD_TYPE_RGBA,
		dwFlags = flags,
		cColorBits = 24,
		cAlphaBits = 8,
		iLayerType = win32.PFD_MAIN_PLANE,
	}

	format_index := win32.ChoosePixelFormat(dc, &pixel_format)
	win32.DescribePixelFormat(dc, format_index, size_of(format_index), &pixel_format)
	win32.SetPixelFormat(dc, format_index, &pixel_format)

	rc := win32.wglCreateContext(dc)
	if !win32.wglMakeCurrent(dc, rc) {
		win32.wglDeleteContext(rc)
		return
	}

	load_1_1(win32.gl_set_proc_address)

	if vsync {
		win32.wglSwapIntervalEXT = auto_cast win32.wglGetProcAddress("wglSwapIntervalEXT")
		win32.wglSwapIntervalEXT(1)
	}

	return true
}

_swap_buffers :: proc(window: ^spl.Window) {
	dc := win32.GetDC(window.id)
	defer win32.ReleaseDC(window.id, dc)

	win32.SwapBuffers(dc)
}

_deinit :: proc(window: ^spl.Window) {
	rc := win32.wglGetCurrentContext()
	win32.wglMakeCurrent(nil, nil)
	// NOTE: it is an error to delete an OpenGL rendering context that is the current context of another thread
	win32.wglDeleteContext(rc)
}
