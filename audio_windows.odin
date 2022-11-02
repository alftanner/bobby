//+build windows
package miki

import win32 "core:sys/windows"
import "core:mem"
import "core:math"
//import "core:log"

import "direct_sound"

ds: direct_sound.DirectSound_Context

Sound_Output_Buffer :: struct {
	samples_per_second: int,
	sample_count: int,
	samples: []i16,
}

Sound_Output :: struct {
	samples_per_second: int,
	running_sample_index: int,
	bytes_per_sample: int,
	secondary_buffer_size: int,
	latency_sample_count: int,
	secondary_buffer: direct_sound.LPDIRECTSOUNDBUFFER,
}

sound_output: Sound_Output

audio_init :: proc(winid: win32.HWND, samples_per_second, buffer_size: int) -> (ok: bool) {
	direct_sound.init(&ds)
	ids: direct_sound.LPDIRECTSOUND
	if ds.DirectSoundCreate(nil, &ids, nil) != 0 do return

	wave_format: direct_sound.WAVEFORMATEX = {
		wFormatTag = direct_sound.WAVE_FORMAT_PCM,
		nChannels = 2,
		nSamplesPerSec = u32(samples_per_second),
		wBitsPerSample = 16,
	}
	wave_format.nBlockAlign = (wave_format.nChannels * wave_format.wBitsPerSample) / 8
	wave_format.nAvgBytesPerSec = wave_format.nSamplesPerSec * u32(wave_format.nBlockAlign)

	if ids->SetCooperativeLevel(winid, direct_sound.DSSCL_PRIORITY) != 0 {
		return
	}

	{
		buffer_description: direct_sound.DSBUFFERDESC = {
			dwSize = size_of(direct_sound.DSBUFFERDESC),
			dwFlags = direct_sound.DSBCAPS_PRIMARYBUFFER,
		}
		primary_buffer: direct_sound.LPDIRECTSOUNDBUFFER

		if ids->CreateSoundBuffer(&buffer_description, &primary_buffer, nil) != 0 {
			return
		}
		if primary_buffer->SetFormat(&wave_format) != 0 {
			return
		}
	}

	buffer_description: direct_sound.DSBUFFERDESC = {
		dwSize = size_of(direct_sound.DSBUFFERDESC),
		dwFlags = 0,
		dwBufferBytes = u32(buffer_size),
	}
	buffer_description.lpwfxFormat = &wave_format

	if ids->CreateSoundBuffer(&buffer_description, &sound_output.secondary_buffer, nil) != 0 {
		return
	}

	return true
}

audio_deinit :: proc() {
	world.audio_present = false
	direct_sound.destroy(&ds)
}

audio_start :: proc() {
	clear_sound_buffer()
	sound_output.secondary_buffer->Play(0, 0, direct_sound.DSBPLAY_LOOPING)
}

audio_play :: proc() {
	sound_is_valid: bool
	byte_to_lock, target_cursor, bytes_to_write: int
	play_cursor, write_cursor: u32

	if sound_output.secondary_buffer->GetCurrentPosition(&play_cursor, &write_cursor) == 0 {
		byte_to_lock = (sound_output.running_sample_index * sound_output.bytes_per_sample) % sound_output.secondary_buffer_size
		target_cursor = (
			int(play_cursor) + (sound_output.latency_sample_count * sound_output.bytes_per_sample)
		) % sound_output.secondary_buffer_size

		if byte_to_lock > target_cursor {
			bytes_to_write = sound_output.secondary_buffer_size - byte_to_lock
			bytes_to_write += target_cursor
		} else {
			bytes_to_write = target_cursor - byte_to_lock
		}

		sound_is_valid = true
	}

	sound_buffer: Sound_Output_Buffer = {
		samples_per_second = sound_output.samples_per_second,
		sample_count = bytes_to_write / sound_output.bytes_per_sample,
		samples = world.samples[:],
	}

	output_sound(&sound_buffer, world.tone_hz)

	if sound_is_valid {
		fill_sound_buffer(byte_to_lock, bytes_to_write, &sound_buffer)
	}
}

clear_sound_buffer :: proc() {
	region1, region2: rawptr
	region1_size, region2_size: u32

	if sound_output.secondary_buffer->Lock(
		0, u32(sound_output.secondary_buffer_size),
		&region1, &region1_size,
		&region2, &region2_size, 0,
	) != 0 {
		return
	}
	defer sound_output.secondary_buffer->Unlock(region1, region1_size, region2, region2_size)

	mem.zero(region1, int(region1_size))
	mem.zero(region2, int(region2_size))
}

fill_sound_buffer :: proc(byte_to_lock, bytes_to_write: int, source_buffer: ^Sound_Output_Buffer) {
	region1_ptr, region2_ptr: rawptr
	region1_size, region2_size: u32

	if sound_output.secondary_buffer->Lock(
		u32(byte_to_lock), u32(bytes_to_write),
		&region1_ptr, &region1_size,
		&region2_ptr, &region2_size, 0,
	) != 0 {
		return
	}
	defer sound_output.secondary_buffer->Unlock(region1_ptr, region1_size, region2_ptr, region2_size)

	//region1 := mem.slice_ptr(cast(^i16)region1_ptr, int(region1_size))
	//region2 := mem.slice_ptr(cast(^i16)region2_ptr, int(region2_size))

	region1_sample_count := region1_size / u32(sound_output.bytes_per_sample)
	dest_sample := cast([^]i16)region1_ptr
	source_sample := cast([^]i16)raw_data(source_buffer.samples)
	for sample_idx: u32 = 0; sample_idx < region1_sample_count * 2; sample_idx += 2 {
		dest_sample[sample_idx] = source_sample[sample_idx]
		dest_sample[sample_idx + 1] = source_sample[sample_idx + 1]
		sound_output.running_sample_index += 1
	}

	region2_sample_count := region2_size / u32(sound_output.bytes_per_sample)
	dest_sample = cast(^i16)region2_ptr
	for sample_idx: u32 = 0; sample_idx < region2_sample_count * 2; sample_idx += 2 {
		dest_sample[sample_idx] = source_sample[sample_idx]
		dest_sample[sample_idx + 1] = source_sample[sample_idx + 1]
		sound_output.running_sample_index += 1
	}
}

output_sound :: proc(sound_buffer: ^Sound_Output_Buffer, tone_hz: f32) {
	@thread_local t_sine: f32
	TONE_VOLUME :: 3000

	wave_period := f32(sound_buffer.samples_per_second) / tone_hz

	for sample_idx := 0; sample_idx < sound_buffer.sample_count * 2; sample_idx += 2 {
		sine_value := math.sin(t_sine)
		sample_value: i16 = cast(i16)(sine_value * TONE_VOLUME)

		sound_buffer.samples[sample_idx] = sample_value
		sound_buffer.samples[sample_idx + 1] = sample_value

		t_sine += 2 * math.PI * (1 / wave_period)
	}
}
