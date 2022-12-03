package spl

Timer :: _Timer

has_precise_timer :: #force_inline proc() -> bool { return _has_precise_timer() }
create_timer :: #force_inline proc(rate: uint) -> (Timer, bool) { return _create_timer(rate) }
wait_timer :: #force_inline proc(timer: ^Timer) { _wait_timer(timer) }

make_scheduler_precise :: #force_inline proc() { _make_scheduler_precise() }
restore_scheduler :: #force_inline proc() { _restore_scheduler() }
