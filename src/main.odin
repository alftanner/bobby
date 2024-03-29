package main

when ODIN_DEBUG {
	import "core:mem"
	import "core:log"
}

when ODIN_OS == .Windows {
	when ODIN_DEBUG do import pdb "pdb-1618b00" // https://github.com/DaseinPhaos/pdb
}

main :: proc() {
	when ODIN_DEBUG && ODIN_OS == .Windows {
		pdb.SetUnhandledExceptionFilter(pdb.dump_stack_trace_on_exception)
	}

	default_allocator := context.allocator

	when ODIN_DEBUG {
		tracking_allocator: mem.Tracking_Allocator
		mem.tracking_allocator_init(&tracking_allocator, context.allocator)
		context.allocator = mem.tracking_allocator(&tracking_allocator)
	}

	_main(default_allocator)

	when ODIN_DEBUG {
		for _, leak in tracking_allocator.allocation_map {
			log.infof("%v leaked %v bytes\n", leak.location, leak.size)
		}

		for bf in tracking_allocator.bad_free_array {
			log.infof("%v allocation %p was freed badly\n", bf.location, bf.memory)
		}
	}
}
