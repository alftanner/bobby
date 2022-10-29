//+build windows
//+private
package simple_window

import win32 "core:sys/windows"

vk_conversation_table := map[win32.WPARAM]Key_Code{
	win32.VK_UP      = .Up,
	win32.VK_DOWN    = .Down,
	win32.VK_LEFT    = .Left,
	win32.VK_RIGHT   = .Right,
	win32.VK_SPACE   = .Space,
	win32.VK_RETURN  = .Enter,
	win32.VK_ESCAPE  = .Escape,
	win32.VK_BACK    = .Backspace,
	win32.VK_TAB     = .Tab,
	win32.VK_APPS    = .Application,
	win32.VK_CAPITAL = .CapsLock,
	win32.VK_PRIOR   = .PageUp,
	win32.VK_NEXT    = .PageDown,
	win32.VK_INSERT  = .Insert,
	win32.VK_DELETE  = .Delete,
	win32.VK_HOME    = .Home,
	win32.VK_END     = .End,

	win32.VK_SNAPSHOT = .PrintScreen,
	win32.VK_SCROLL   = .ScrollLock,
	win32.VK_PAUSE    = .Pause,
	win32.VK_CANCEL   = .Break, // VK_CANCEL also sends .Control before .Break

	win32.VK_A = .A,
	win32.VK_B = .B,
	win32.VK_C = .C,
	win32.VK_D = .D,
	win32.VK_E = .E,
	win32.VK_F = .F,
	win32.VK_G = .G,
	win32.VK_H = .H,
	win32.VK_I = .I,
	win32.VK_J = .J,
	win32.VK_K = .K,
	win32.VK_L = .L,
	win32.VK_M = .M,
	win32.VK_N = .N,
	win32.VK_O = .O,
	win32.VK_P = .P,
	win32.VK_Q = .Q,
	win32.VK_R = .R,
	win32.VK_S = .S,
	win32.VK_T = .T,
	win32.VK_U = .U,
	win32.VK_V = .V,
	win32.VK_W = .W,
	win32.VK_X = .X,
	win32.VK_Y = .Y,
	win32.VK_Z = .Z,

	win32.VK_0 = .Num0,
	win32.VK_1 = .Num1,
	win32.VK_2 = .Num2,
	win32.VK_3 = .Num3,
	win32.VK_4 = .Num4,
	win32.VK_5 = .Num5,
	win32.VK_6 = .Num6,
	win32.VK_7 = .Num7,
	win32.VK_8 = .Num8,
	win32.VK_9 = .Num9,

	win32.VK_NUMLOCK   = .Numlock,
	win32.VK_NUMPAD0   = .Numpad0,
	win32.VK_NUMPAD1   = .Numpad1,
	win32.VK_NUMPAD2   = .Numpad2,
	win32.VK_NUMPAD3   = .Numpad3,
	win32.VK_NUMPAD4   = .Numpad4,
	win32.VK_NUMPAD5   = .Numpad5,
	win32.VK_NUMPAD6   = .Numpad6,
	win32.VK_NUMPAD7   = .Numpad7,
	win32.VK_NUMPAD8   = .Numpad8,
	win32.VK_NUMPAD9   = .Numpad9,
	win32.VK_MULTIPLY  = .Multiply,
	win32.VK_ADD       = .Add,
	win32.VK_SUBTRACT  = .Subtract,
	win32.VK_DIVIDE    = .Divide,
	win32.VK_DECIMAL   = .Decimal,
	win32.VK_SEPARATOR = .Separator,

	win32.VK_F1  = .F1,
	win32.VK_F2  = .F2,
	win32.VK_F3  = .F3,
	win32.VK_F4  = .F4,
	win32.VK_F5  = .F5,
	win32.VK_F6  = .F6,
	win32.VK_F7  = .F7,
	win32.VK_F8  = .F8,
	win32.VK_F9  = .F9,
	win32.VK_F10 = .F10,
	win32.VK_F11 = .F11,
	win32.VK_F12 = .F12,
	win32.VK_F13 = .F13,
	win32.VK_F14 = .F14,
	win32.VK_F15 = .F15,
	win32.VK_F16 = .F16,
	win32.VK_F17 = .F17,
	win32.VK_F18 = .F18,
	win32.VK_F19 = .F19,
	win32.VK_F20 = .F20,
	win32.VK_F21 = .F21,
	win32.VK_F22 = .F22,
	win32.VK_F23 = .F23,
	win32.VK_F24 = .F24,

	win32.VK_BROWSER_BACK      = .BrowserBack,
	win32.VK_BROWSER_FORWARD   = .BrowserForward,
	win32.VK_BROWSER_REFRESH   = .BrowserRefresh,
	win32.VK_BROWSER_STOP      = .BrowserStop,
	win32.VK_BROWSER_SEARCH    = .BrowserSearch,
	win32.VK_BROWSER_FAVORITES = .BrowserFavorites,
	win32.VK_BROWSER_HOME      = .BrowserHome,

	win32.VK_VOLUME_MUTE      = .VolumeMute,
	win32.VK_VOLUME_DOWN      = .VolumeDown,
	win32.VK_VOLUME_UP        = .VolumeUp,
	win32.VK_MEDIA_NEXT_TRACK = .MediaNextTrack,
	win32.VK_MEDIA_PREV_TRACK = .MediaPrevTrack,
	win32.VK_MEDIA_STOP       = .MediaStop,
	win32.VK_MEDIA_PLAY_PAUSE = .MediaPlayPause,

	win32.VK_LAUNCH_MAIL         = .LaunchMail,
	win32.VK_LAUNCH_MEDIA_SELECT = .LaunchMediaSelect,
	win32.VK_LAUNCH_APP1         = .LaunchApp1,
	win32.VK_LAUNCH_APP2         = .LaunchApp2,
}
