package gl

import gl "vendor:OpenGL"

when !gl.GL_DEBUG {
	// VERSION_1_0
	End :: proc "c" () {impl_End()}
	MatrixMode :: proc "c" (mode: GLenum) {impl_MatrixMode(mode)}
	LoadIdentity :: proc "c" () {impl_LoadIdentity()}
	AlphaFunc :: proc "c" (func: GLenum, ref: GLclampf) {impl_AlphaFunc(func, ref)}
} else {
	debug_helper :: gl.debug_helper

	// VERSION_1_0
	End :: proc "c" (loc := #caller_location) {impl_End(); debug_helper(loc, 0)}
	MatrixMode :: proc "c" (mode: GLenum, loc := #caller_location) {impl_MatrixMode(mode); debug_helper(loc, 0, mode)}
	LoadIdentity :: proc "c" (loc := #caller_location) {impl_LoadIdentity(); debug_helper(loc, 0)}
	AlphaFunc :: proc "c" (func: GLenum, ref: GLclampf, loc := #caller_location) {impl_AlphaFunc(func, ref); debug_helper(loc, 0, func, ref)}
}
