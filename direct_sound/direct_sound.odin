package direct_sound

// @note(zh): Ported using mostly msdn, but do not trust everything from there.
//            Corrected any errors by checking dsound.h directly.
// @ref(zh):  https://docs.microsoft.com/en-us/previous-versions/windows/desktop/ee416975(v=vs.85)
// @ref(zh):  dsound.h (10.0.18362.0)

import win32 "core:sys/windows"
import "core:dynlib"
import "core:runtime"

DirectSound_Context :: struct {
	_lib: dynlib.Library,

	DirectSoundCreate : proc "std" (lpcGuidDevice: win32.LPCGUID, ppDS: ^LPDIRECTSOUND, pUnkOuter: LPUNKNOWN) -> win32.HRESULT,
	DirectSoundCreate8 : proc "std" (lpcGuidDevice: win32.LPCGUID, ppDS8: ^LPDIRECTSOUND8, pUnkOuter: LPUNKNOWN) -> win32.HRESULT,
	DirectSoundCaptureCreate : proc "std" (lpcGUID: win32.LPCGUID, lplpDSC: ^LPDIRECTSOUNDCAPTURE, pUnkOuter: LPUNKNOWN) -> win32.HRESULT,
	DirectSoundCaptureCreate8 : proc "std" (lpcGUID: win32.LPCGUID, lplpDSC8: ^LPDIRECTSOUNDCAPTURE8, pUnkOuter: LPUNKNOWN) -> win32.HRESULT,
	DirectSoundCaptureEnumerateW : proc "std" (lpDSEnumCallback: LPDSENUMCALLBACKW, lpContext: win32.LPVOID) -> win32.HRESULT,
	DirectSoundEnumerateW : proc "std" (lpDSEnumCallback: LPDSENUMCALLBACKW, lpContext: win32.LPVOID) -> win32.HRESULT,

	DirectSoundFullDuplexCreate : proc "std" (
		pcGuidCaptureDevice: win32.LPCGUID,
		pcGuidRenderDevice: win32.LPCGUID,
		pcDSCBufferDesc: LPCDSCBUFFERDESC,
		pcDSBufferDesc: LPCDSBUFFERDESC,
		hWnd: win32.HWND,
		dwLevel: win32.DWORD,
		ppDSFD: ^LPDIRECTSOUNDFULLDUPLEX,
		ppDSCBuffer: ^LPDIRECTSOUNDCAPTUREBUFFER,
		ppDSBuffer: ^LPDIRECTSOUNDBUFFER,
		pUnkOuter: LPUNKNOWN,
	) -> win32.HRESULT,

	GetDeviceID : proc "std" (pGuidSrc: win32.LPCGUID, pGuidDest: win32.LPCGUID) -> win32.HRESULT,
}

init :: proc(ds: ^DirectSound_Context) -> bool {
	ds._lib = dynlib.load_library("dsound.dll") or_return

	ti := runtime.type_info_base(type_info_of(DirectSound_Context))
	s, _ := ti.variant.(runtime.Type_Info_Struct)

	for fname, i in s.names {
		if fname == "_lib" do continue

		proc_ptr, exists := dynlib.symbol_address(ds._lib, fname)
		if !exists do continue

		field_ptr := cast(^rawptr)(uintptr(ds) + s.offsets[i])
		field_ptr^ = proc_ptr
	}

	return true
}

destroy :: proc(ctx: ^DirectSound_Context) {
	if ctx._lib == nil do return

	dynlib.unload_library(ctx._lib)
}
