package gl

import "core:c"
import gl "vendor:OpenGL"

GLenum     :: c.uint
GLboolean  :: c.uchar
GLbitfield :: c.uint
GLbyte     :: c.char
GLshort    :: c.short
GLint      :: c.int
GLsizei    :: c.int
GLubyte    :: c.uchar
GLushort   :: c.ushort
GLuint     :: c.uint
GLfloat    :: c.float
GLclampf   :: c.float
GLdouble   :: c.double
GLclampd   :: c.double

// VERSION_1_0
Begin: proc "c" (mode: GLenum)
impl_End: proc "c" ()
impl_MatrixMode: proc "c" (mode: GLenum)
impl_LoadIdentity: proc "c" ()
impl_AlphaFunc: proc "c" (func: GLenum, ref: GLclampf)
Color3ub: proc "c" (red, green, blue: GLubyte)
Color4ub: proc "c" (red, green, blue, alpha: GLubyte)
TexCoord2f: proc "c" (s, t: GLfloat)
Vertex2f: proc "c" (x, y: GLfloat)

load_1_1 :: proc(set_proc_address: gl.Set_Proc_Address_Type) {
	gl.load_up_to(1, 1, set_proc_address)
	set_proc_address(&Begin, "glBegin")
	set_proc_address(&impl_End, "glEnd")
	set_proc_address(&impl_MatrixMode, "glMatrixMode")
	set_proc_address(&impl_LoadIdentity, "glLoadIdentity")
	set_proc_address(&impl_AlphaFunc, "glAlphaFunc")
	set_proc_address(&Color3ub, "glColor3ub")
	set_proc_address(&Color4ub, "glColor4ub")
	set_proc_address(&TexCoord2f, "glTexCoord2f")
	set_proc_address(&Vertex2f, "glVertex2f")
}
