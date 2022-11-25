package simple_window

import "core:mem"
import "core:image"

WHITE  :: image.RGBA_Pixel{255, 255, 255, 255}
BLACK  :: image.RGBA_Pixel{0,   0,   0,   255}
RED    :: image.RGBA_Pixel{237, 28,  36,  255}
GREEN  :: image.RGBA_Pixel{28,  237, 36,  255}
BLUE   :: image.RGBA_Pixel{63,  72,  204, 255}
YELLOW :: image.RGBA_Pixel{255, 255, 72,  255}
ORANGE :: image.RGBA_Pixel{255, 127, 39,  255}

Flip :: enum {
	None,
	Horizontal,
	Vertical,
	Both,
}

Rect :: struct {x, y, w, h: int}

Color :: [4]u8

Texture2D :: struct {
	pixels: []Color,
	w, h: int,
	allocator: mem.Allocator,
}

texture_make :: proc(w, h: int, allocator := context.allocator) -> (t: Texture2D) {
	t.w = w
	t.h = h
	t.allocator = allocator
	t.pixels = make([]Color, t.w * t.h, t.allocator)
	return
}

texture_destroy :: proc(t: ^Texture2D) {
	delete(t.pixels, t.allocator)
	t^ = {}
}

color :: proc(r, g, b, a: u8) -> Color {
	when ODIN_OS == .Windows {
		return {b, g, r, a}
	} else {
		return {r, g, b, a}
	}
}

pixel_mod :: proc(dst: ^Color, mod: Color) {
	dst.r = u8(cast(f32)dst.r * (cast(f32)mod.r / 255))
	dst.g = u8(cast(f32)dst.g * (cast(f32)mod.g / 255))
	dst.b = u8(cast(f32)dst.b * (cast(f32)mod.b / 255))
}

// draw every pixel by blending
draw_from_texture :: proc(dst: ^Texture2D, src: Texture2D, pos: [2]int, src_rect: Rect, flip: Flip = .None, mod: image.RGB_Pixel = {255, 255, 255}) {
	needs_mod := mod != {255, 255, 255}
	mod_color := color(mod.r, mod.g, mod.b, 0)

	endx := min(pos.x + src_rect.w, dst.w)
	endy := min(pos.y + src_rect.h, dst.h)

	for y in max(0, pos.y)..<endy do for x in max(0, pos.x)..<endx {
		px, py := x - pos.x, y - pos.y
		spx := src_rect.w - px - 1 if flip == .Horizontal else px
		spy := src_rect.h - py - 1 if flip == .Vertical else py

		sp := (src_rect.y + spy) * src.w + (src_rect.x + spx)
		dp := y * dst.w + x
		src_pixel := src.pixels[sp]
		if needs_mod do pixel_mod(&src_pixel, mod_color)
		blend_pixel(&dst.pixels[dp], src_pixel)
	}
}

draw_rect :: proc(dst: ^Texture2D, rect: Rect, color: Color, filled: bool = true) {
	endx := min(rect.x + rect.w, dst.w)
	endy := min(rect.y + rect.h, dst.h)

	for y in max(0, rect.y)..<endy do for x in max(0, rect.x)..<endx {
		if !filled {
			if (x != rect.x && x != rect.x + rect.w - 1) && (y != rect.y && y != rect.y + rect.h - 1) {
				continue
			}
		}

		dp := y * dst.w + x
		blend_pixel(&dst.pixels[dp], color)
	}
}

// blend foreground pixel with alpha onto background
blend_pixel :: proc(bg: ^Color, fg: Color) {
	// NOTE: these do not necesserily correspond to RGBA mapping, colors can be in any order, as long as alpha is at the same place
	AMASK    :: 0xFF000000
	GMASK    :: 0x0000FF00
	AGMASK   :: 0xFF00FF00
	RBMASK   :: 0x00FF00FF
	ONEALPHA :: 0x01000000

	p1 := transmute(^u32)bg
	p2 := transmute(u32)fg

	a := (p2 & AMASK) >> 24
	inv_a := 255 - a
	rb := ((inv_a * (p1^ & RBMASK)) + (a * (p2 & RBMASK))) >> 8
	ag := (inv_a * ((p1^ & AGMASK) >> 8)) + (a * (ONEALPHA | ((p2 & GMASK) >> 8)))
	p1^ = (rb & RBMASK) | (ag & AGMASK)
}
