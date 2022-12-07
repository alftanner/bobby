package gl

import spl ".."

init :: proc(window: ^spl.Window, vsync: bool) -> (success: bool) { return _init(window, vsync) }
deinit :: proc(window: ^spl.Window) { _deinit(window) }
swap_buffers :: proc(window: ^spl.Window) { _swap_buffers(window) }
