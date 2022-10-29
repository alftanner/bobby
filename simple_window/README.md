# Simple window management API for Odin programming language.

This API allows for a simple way to create and destroy windows, and provides a simple pixel buffer to draw into.

## Features

* Non-blocking resize and move.
Requires a callback system, but it's not that bad, even though it forces you into have some global state.
Don't @ me, it's all Windows' fault.

* Custom event system that is sane and easy to work with.

* Simple pixel buffer to easily start drawing pixels to the screen.
By default buffer size is automatically changed on resize, but you can opt out of it with ManualPixels flag.

---

# LICENSING

This code is public domain.
