package spl_gl

import "core:c"
import gl "vendor:OpenGL"

GLenum :: c.uint
GLboolean :: c.uchar
GLbitfield :: c.uint
GLbyte :: c.char
GLshort :: c.short
GLint :: c.int
GLsizei :: c.int
GLubyte :: c.uchar
GLushort :: c.ushort
GLuint :: c.uint
GLfloat :: c.float
GLclampf :: c.float
GLdouble :: c.double
GLclampd :: c.double

ClearColor :: gl.ClearColor
Clear :: gl.Clear
Viewport :: gl.Viewport
TexImage2D :: gl.TexImage2D
Enable :: gl.Enable
BindTexture :: gl.BindTexture
GenTextures :: gl.GenTextures
TexParameteri :: gl.TexParameteri
Flush :: gl.Flush

Begin: proc "c" (mode: GLenum)
Vertex2i: proc "c" (x, y: GLint)
Vertex2f: proc "c" (x, y: GLfloat)
Vertex3f: proc "c" (x, y, z: GLfloat)
TexCoord2f: proc "c" (s, t: GLfloat)

impl_End: proc "c" ()
impl_MatrixMode: proc "c" (mode: GLenum)
impl_LoadIdentity: proc "c" ()
impl_TexEnvi: proc "c" (target, pname: GLenum, param: GLint)

when !gl.GL_DEBUG {
	End :: proc "c" () { impl_End() }
	MatrixMode :: proc "c" (mode: GLenum) { impl_MatrixMode(mode) }
	LoadIdentity :: proc "c" () { impl_LoadIdentity() }
	TexEnvi :: proc "c" (target, pname: GLenum, param: GLint) { impl_TexEnvi(target, pname, param) }
} else {
	End :: proc "c" (loc := #caller_location) { impl_End(); gl.debug_helper(loc, 0) }
	MatrixMode :: proc "c" (mode: GLenum, loc := #caller_location) { impl_MatrixMode(mode); gl.debug_helper(loc, 0, mode) }
	LoadIdentity :: proc "c" (loc := #caller_location) { impl_LoadIdentity(); gl.debug_helper(loc, 0) }
	TexEnvi :: proc "c" (target, pname: GLenum, param: GLint, loc := #caller_location) { impl_TexEnvi(target, pname, param); gl.debug_helper(loc, 0, target, pname, param) }
}

_load_missing :: proc(set_proc_address: gl.Set_Proc_Address_Type) {
	set_proc_address(&Begin, "glBegin")
	set_proc_address(&Vertex2i, "glVertex2i")
	set_proc_address(&Vertex2f, "glVertex2f")
	set_proc_address(&Vertex3f, "glVertex3f")
	set_proc_address(&TexCoord2f, "glTexCoord2f")

	set_proc_address(&impl_End, "glEnd")
	set_proc_address(&impl_MatrixMode, "glMatrixMode")
	set_proc_address(&impl_LoadIdentity, "glLoadIdentity")
	set_proc_address(&impl_TexEnvi, "glTexEnvi")
}
