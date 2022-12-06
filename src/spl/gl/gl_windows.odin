package spl_gl

import win32 "core:sys/windows"
import spl ".."

_enable_opengl :: proc(window: ^spl.Window) {
	dc := win32.GetDC(window.id)
	defer win32.ReleaseDC(window.id, dc)

	pfd: win32.PIXELFORMATDESCRIPTOR = {
		nSize = size_of(win32.PIXELFORMATDESCRIPTOR),
		nVersion = 1,
		dwFlags = win32.PFD_DRAW_TO_WINDOW | win32.PFD_SUPPORT_OPENGL,
		iPixelType = win32.PFD_TYPE_RGBA,
		cColorBits = 32,
		cAlphaBits = 8,
		iLayerType = win32.PFD_MAIN_PLANE,
	}

	format := win32.ChoosePixelFormat(dc, &pfd)
	win32.SetPixelFormat(dc, format, &pfd)
	window.rc = win32.wglCreateContext(dc)
	win32.wglMakeCurrent(dc, window.rc)

	_load(win32.gl_set_proc_address)
}

_disable_opengl :: proc(window: ^spl.Window) {
	win32.wglMakeCurrent(nil, nil)
	win32.wglDeleteContext(window.rc)
}
