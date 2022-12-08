package main

import "core:mem"
import "core:image"

import "spl"

WHITE  := platform_color({255, 255, 255, 255})
BLACK  := platform_color({0,   0,   0,   255})
RED    := platform_color({237, 28,  36,  255})
GREEN  := platform_color({28,  237, 36,  255})
BLUE   := platform_color({63,  72,  204, 255})
YELLOW := platform_color({255, 255, 72,  255})
ORANGE := platform_color({255, 127, 39,  255})

Flip :: enum {
	Horizontal,
	Vertical,
}

Rect :: spl.Rect

Color :: [4]u8

Texture2D :: struct {
	pixels: []Color,
	size: [2]int,
	allocator: mem.Allocator,
}

texture_make :: proc(w, h: int, allocator := context.allocator) -> (t: Texture2D) {
	t.size = {w, h}
	t.allocator = allocator
	t.pixels = make([]Color, t.size[0] * t.size[1], t.allocator)
	return
}

texture_destroy :: proc(t: ^Texture2D) {
	delete(t.pixels, t.allocator)
	t^ = {}
}

platform_color :: #force_inline proc(p: image.RGBA_Pixel) -> Color {
	when ODIN_OS == .Windows {
		return p.bgra
	} else {
		return p
	}
}
