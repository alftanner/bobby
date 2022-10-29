package simple_window

Event_Handler_Proc :: #type proc(window: ^Window, event: Event)

Close_Event :: struct {}

Focus_Event :: struct {
	focused: bool,
}

Draw_Event :: struct {}

Resize_Type :: enum {
	Default,
	Start,
	End,
	Maximized,
	Minimized,
}
Resize_Event :: struct {
	type: Resize_Type,
}

Move_Type :: enum {
	Default,
	Start,
	End,
	Minimized,
}
Move_Event :: struct {
	type: Move_Type,
}

Character_Event :: struct {
	character: rune,
}

Keyboard_Event :: struct {
	scancode: u32,
	key: Key_Code,
	state: Key_State,
}

Mouse_Button_Event :: struct {
	button: Mouse_Button,
	clicked: bool,
	double_clicked: bool,
}

Mouse_Move_Event :: struct {
	x, y: i32,
}

Mouse_Wheel_Event :: struct {
	delta: i16,
}

Event :: union {
	Close_Event,
	Focus_Event,
	Draw_Event,
	Resize_Event,
	Move_Event,
	Character_Event,
	Keyboard_Event,
	Mouse_Button_Event,
	Mouse_Move_Event,
	Mouse_Wheel_Event,
}
