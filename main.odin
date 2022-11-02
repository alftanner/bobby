package miki

import "core:os"
import "core:mem"
import "core:mem/virtual"
import "core:fmt"
import "core:time"
import "core:runtime"
import "core:log"

import swin "simple_window"

assertion_failure_proc :: proc(prefix, message: string, loc: runtime.Source_Code_Location) -> ! {
	error := fmt.tprintf("{}({}:{}) {}", loc.file_path, loc.line, loc.column, prefix)
	if len(message) > 0 {
		error = fmt.tprintf("{}: {}", error, message)
	}

	fmt.eprintln(error)

	swin.show_message_box(.Error, "Error!", error)

	runtime.trap()
}

logger_proc :: proc(data: rawptr, level: runtime.Logger_Level, text: string, options: runtime.Logger_Options, location := #caller_location) {
	if level == .Fatal {
		fmt.eprintf("[{}] {}\n", level, text)
		swin.show_message_box(.Error, "Error!", text)
		runtime.trap()
	} else if level == .Info {
		fmt.eprintf("{}\n", text)
	} else {
		fmt.eprintf("[{}] {}\n", level, text)
	}
}

cycles_lap_time :: proc(prev: ^u64) -> u64 {
	cycles: u64
	cycle_count := time.read_cycle_counter()
	if prev^ != 0 {
		cycles = cycle_count - prev^
	}
	prev^ = cycle_count
	return cycles
}

save_data :: proc(fname: string, data: ^$T) {
	os.write_entire_file(fname, mem.ptr_to_bytes(data, size_of(T)))
}

load_data :: proc(fname: string, data: ^$T) {
	bytes, _ := os.read_entire_file(fname)
	defer delete(bytes)

	w := transmute(^T)(raw_data(bytes))
	data^ = w^
}

when ODIN_OS == .Windows {
	import win32 "core:sys/windows"
	when ODIN_DEBUG do import pdb "pdb-1618b00" // https://github.com/DaseinPhaos/pdb

	_restore_scheduler :: proc() {
		win32.timeEndPeriod(1)
	}

	@(deferred_none=_restore_scheduler)
	make_scheduler_precise :: proc() {
		win32.timeBeginPeriod(1)
	}
} else {
	make_scheduler_precise :: proc() {}
}

main :: proc() {
	when ODIN_DEBUG && ODIN_OS == .Windows {
		pdb.SetUnhandledExceptionFilter(pdb.dump_stack_trace_on_exception)
	}

	context.assertion_failure_proc = assertion_failure_proc
	context.logger.procedure = logger_proc

	tracking_allocator: mem.Tracking_Allocator
	mem.tracking_allocator_init(&tracking_allocator, context.allocator)

	when ODIN_DEBUG {
		context.allocator = mem.tracking_allocator(&tracking_allocator)
	}

	make_scheduler_precise()

	_main()

	for _, leak in tracking_allocator.allocation_map {
		log.infof("%v leaked %v bytes\n", leak.location, leak.size)
	}

	for bf in tracking_allocator.bad_free_array {
		log.infof("%v allocation %p was freed badly\n", bf.location, bf.memory)
	}
}
