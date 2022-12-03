package simple_window

import win32 "core:sys/windows"

_Timer :: struct {
	rate: win32.LARGE_INTEGER,
	handle: win32.HANDLE,
}

_has_precise_timer :: proc() -> bool {
	handle := win32.CreateWaitableTimerExW(nil, nil, win32.CREATE_WAITABLE_TIMER_HIGH_RESOLUTION, win32.TIMER_ALL_ACCESS)
	if handle == nil {
		return false
	}
	win32.CloseHandle(handle)
	return true
}

_create_timer :: proc(rate: uint) -> (timer: Timer, success: bool) {
	rate := -win32.LARGE_INTEGER(10000000 / f32(rate))

	handle := win32.CreateWaitableTimerExW(nil, nil, win32.CREATE_WAITABLE_TIMER_HIGH_RESOLUTION, win32.TIMER_ALL_ACCESS)
	if handle == nil {
		return
	}

	if !win32.SetWaitableTimerEx(handle, &rate, 0, nil, nil, nil, 0) {
		return
	}

	success = true
	timer.rate = rate
	timer.handle = handle
	return
}

_wait_timer :: proc(timer: ^Timer) {
	win32.WaitForSingleObject(timer.handle, win32.INFINITE)
	win32.SetWaitableTimerEx(timer.handle, &timer.rate, 0, nil, nil, nil, 0)
}

_make_scheduler_precise :: proc() {
	win32.timeBeginPeriod(1)
}

_restore_scheduler :: proc() {
	win32.timeEndPeriod(1)
}