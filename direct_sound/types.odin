package direct_sound

import win32 "core:sys/windows"
import "core:c"

///////////////////////////////////////////////
// Types
///////////////////////////////////////////////
//@note(zh): Still missing in sys/windows
D3DCOLOR   :: win32.DWORD
LPD3DCOLOR :: win32.DWORD
D3DVALUE   :: c.float
LPD3DVALUE :: ^D3DVALUE
LPLONG     :: ^win32.LONG
REFGUID    :: win32.GUID
IID        :: win32.GUID
REFIID     :: ^win32.GUID
FLT_MAX    :: 3.402823466e+38 // max value
FLT_MIN    :: 1.175494351e-38 // min normalized positive value

///////////////////////////////////////////////
// Misc
///////////////////////////////////////////////
DSFX_LOCHARDWARE                                :: 0x00000001
DSFX_LOCSOFTWARE                                :: 0x00000002
DSFXR_PRESENT                                   :: 0
DSFXR_LOCHARDWARE                               :: 1
DSFXR_LOCSOFTWARE                               :: 2
DSFXR_UNALLOCATED                               :: 3
DSFXR_FAILED                                    :: 4
DSFXR_UNKNOWN                                   :: 5
DSFXR_SENDLOOP                                  :: 6
DSCFX_LOCHARDWARE                               :: 0x00000001
DSCFX_LOCSOFTWARE                               :: 0x00000002
DSCFXR_LOCHARDWARE                              :: 0x00000010
DSCFXR_LOCSOFTWARE                              :: 0x00000020
KSPROPERTY_SUPPORT_GET                          :: 0x00000001
KSPROPERTY_SUPPORT_SET                          :: 0x00000002
DSFXCHORUS_WAVE_TRIANGLE                        :: 0
DSFXCHORUS_WAVE_SIN                             :: 1
DSFXCHORUS_WETDRYMIX_MIN                        :: 0.0
DSFXCHORUS_WETDRYMIX_MAX                        :: 100.0
DSFXCHORUS_DEPTH_MIN                            :: 0.0
DSFXCHORUS_DEPTH_MAX                            :: 100.0
DSFXCHORUS_FEEDBACK_MIN                         :: -99.0
DSFXCHORUS_FEEDBACK_MAX                         :: 99.0
DSFXCHORUS_FREQUENCY_MIN                        :: 0.0
DSFXCHORUS_FREQUENCY_MAX                        :: 10.0
DSFXCHORUS_DELAY_MIN                            :: 0.0
DSFXCHORUS_DELAY_MAX                            :: 20.0
DSFXCHORUS_PHASE_MIN                            :: 0
DSFXCHORUS_PHASE_MAX                            :: 4
DSFXCHORUS_PHASE_NEG_180                        :: 0
DSFXCHORUS_PHASE_NEG_90                         :: 1
DSFXCHORUS_PHASE_ZERO                           :: 2
DSFXCHORUS_PHASE_90                             :: 3
DSFXCHORUS_PHASE_180                            :: 4
DSFXFLANGER_WAVE_TRIANGLE                       :: 0
DSFXFLANGER_WAVE_SIN                            :: 1
DSFXFLANGER_WETDRYMIX_MIN                       :: 0.0
DSFXFLANGER_WETDRYMIX_MAX                       :: 100.0
DSFXFLANGER_FREQUENCY_MIN                       :: 0.0
DSFXFLANGER_FREQUENCY_MAX                       :: 10.0
DSFXFLANGER_DEPTH_MIN                           :: 0.0
DSFXFLANGER_DEPTH_MAX                           :: 100.0
DSFXFLANGER_PHASE_MIN                           :: 0
DSFXFLANGER_PHASE_MAX                           :: 4
DSFXFLANGER_FEEDBACK_MIN                        :: -99.0
DSFXFLANGER_FEEDBACK_MAX                        :: 99.0
DSFXFLANGER_DELAY_MIN                           :: 0.0
DSFXFLANGER_DELAY_MAX                           :: 4.0
DSFXFLANGER_PHASE_NEG_180                       :: 0
DSFXFLANGER_PHASE_NEG_90                        :: 1
DSFXFLANGER_PHASE_ZERO                          :: 2
DSFXFLANGER_PHASE_90                            :: 3
DSFXFLANGER_PHASE_180                           :: 4
DSFXECHO_WETDRYMIX_MIN                          :: 0.0
DSFXECHO_WETDRYMIX_MAX                          :: 100.0
DSFXECHO_FEEDBACK_MIN                           :: 0.0
DSFXECHO_FEEDBACK_MAX                           :: 100.0
DSFXECHO_LEFTDELAY_MIN                          :: 1.0
DSFXECHO_LEFTDELAY_MAX                          :: 2000.0
DSFXECHO_RIGHTDELAY_MIN                         :: 1.0
DSFXECHO_RIGHTDELAY_MAX                         :: 2000.0
DSFXECHO_PANDELAY_MIN                           :: 0
DSFXECHO_PANDELAY_MAX                           :: 1
DSFXDISTORTION_GAIN_MIN                         :: -60.0
DSFXDISTORTION_GAIN_MAX                         :: 0.0
DSFXDISTORTION_EDGE_MIN                         :: 0.0
DSFXDISTORTION_EDGE_MAX                         :: 100.0
DSFXDISTORTION_POSTEQCENTERFREQUENCY_MIN        :: 100.0
DSFXDISTORTION_POSTEQCENTERFREQUENCY_MAX        :: 8000.0
DSFXDISTORTION_POSTEQBANDWIDTH_MIN              :: 100.0
DSFXDISTORTION_POSTEQBANDWIDTH_MAX              :: 8000.0
DSFXDISTORTION_PRELOWPASSCUTOFF_MIN             :: 100.0
DSFXDISTORTION_PRELOWPASSCUTOFF_MAX             :: 8000.0
DSFXCOMPRESSOR_GAIN_MIN                         :: -60.0
DSFXCOMPRESSOR_GAIN_MAX                         :: 60.0
DSFXCOMPRESSOR_ATTACK_MIN                       :: 0.01
DSFXCOMPRESSOR_ATTACK_MAX                       :: 500.0
DSFXCOMPRESSOR_RELEASE_MIN                      :: 50.0
DSFXCOMPRESSOR_RELEASE_MAX                      :: 3000.0
DSFXCOMPRESSOR_THRESHOLD_MIN                    :: -60.0
DSFXCOMPRESSOR_THRESHOLD_MAX                    :: 0.0
DSFXCOMPRESSOR_RATIO_MIN                        :: 1.0
DSFXCOMPRESSOR_RATIO_MAX                        :: 100.0
DSFXCOMPRESSOR_PREDELAY_MIN                     :: 0.0
DSFXCOMPRESSOR_PREDELAY_MAX                     :: 4.0
DSFXPARAMEQ_CENTER_MIN                          :: 80.0
DSFXPARAMEQ_CENTER_MAX                          :: 16000.0
DSFXPARAMEQ_BANDWIDTH_MIN                       :: 1.0
DSFXPARAMEQ_BANDWIDTH_MAX                       :: 36.0
DSFXPARAMEQ_GAIN_MIN                            :: -15.0
DSFXPARAMEQ_GAIN_MAX                            :: 15.0
DSFX_I3DL2REVERB_ROOM_MIN                       :: (-10000)
DSFX_I3DL2REVERB_ROOM_MAX                       :: 0
DSFX_I3DL2REVERB_ROOM_DEFAULT                   :: (-1000)
DSFX_I3DL2REVERB_ROOMHF_MIN                     :: (-10000)
DSFX_I3DL2REVERB_ROOMHF_MAX                     :: 0
DSFX_I3DL2REVERB_ROOMHF_DEFAULT                 :: (-100)
DSFX_I3DL2REVERB_ROOMROLLOFFFACTOR_MIN          :: 0.0
DSFX_I3DL2REVERB_ROOMROLLOFFFACTOR_MAX          :: 10.0
DSFX_I3DL2REVERB_ROOMROLLOFFFACTOR_DEFAULT      :: 0.0
DSFX_I3DL2REVERB_DECAYTIME_MIN                  :: 0.1
DSFX_I3DL2REVERB_DECAYTIME_MAX                  :: 20.0
DSFX_I3DL2REVERB_DECAYTIME_DEFAULT              :: 1.49
DSFX_I3DL2REVERB_DECAYHFRATIO_MIN               :: 0.1
DSFX_I3DL2REVERB_DECAYHFRATIO_MAX               :: 2.0
DSFX_I3DL2REVERB_DECAYHFRATIO_DEFAULT           :: 0.83
DSFX_I3DL2REVERB_REFLECTIONS_MIN                :: (-10000)
DSFX_I3DL2REVERB_REFLECTIONS_MAX                :: 1000
DSFX_I3DL2REVERB_REFLECTIONS_DEFAULT            :: (-2602)
DSFX_I3DL2REVERB_REFLECTIONSDELAY_MIN           :: 0.0
DSFX_I3DL2REVERB_REFLECTIONSDELAY_MAX           :: 0.3
DSFX_I3DL2REVERB_REFLECTIONSDELAY_DEFAULT       :: 0.007
DSFX_I3DL2REVERB_REVERB_MIN                     :: (-10000)
DSFX_I3DL2REVERB_REVERB_MAX                     :: 2000
DSFX_I3DL2REVERB_REVERB_DEFAULT                 :: (200)
DSFX_I3DL2REVERB_REVERBDELAY_MIN                :: 0.0
DSFX_I3DL2REVERB_REVERBDELAY_MAX                :: 0.1
DSFX_I3DL2REVERB_REVERBDELAY_DEFAULT            :: 0.011
DSFX_I3DL2REVERB_DIFFUSION_MIN                  :: 0.0
DSFX_I3DL2REVERB_DIFFUSION_MAX                  :: 100.0
DSFX_I3DL2REVERB_DIFFUSION_DEFAULT              :: 100.0
DSFX_I3DL2REVERB_DENSITY_MIN                    :: 0.0
DSFX_I3DL2REVERB_DENSITY_MAX                    :: 100.0
DSFX_I3DL2REVERB_DENSITY_DEFAULT                :: 100.0
DSFX_I3DL2REVERB_HFREFERENCE_MIN                :: 20.0
DSFX_I3DL2REVERB_HFREFERENCE_MAX                :: 20000.0
DSFX_I3DL2REVERB_HFREFERENCE_DEFAULT            :: 5000.0
DSFX_I3DL2REVERB_QUALITY_MIN                    :: 0
DSFX_I3DL2REVERB_QUALITY_MAX                    :: 3
DSFX_I3DL2REVERB_QUALITY_DEFAULT                :: 2
DSFX_WAVESREVERB_INGAIN_MIN                     :: -96.0
DSFX_WAVESREVERB_INGAIN_MAX                     :: 0.0
DSFX_WAVESREVERB_INGAIN_DEFAULT                 :: 0.0
DSFX_WAVESREVERB_REVERBMIX_MIN                  :: -96.0
DSFX_WAVESREVERB_REVERBMIX_MAX                  :: 0.0
DSFX_WAVESREVERB_REVERBMIX_DEFAULT              :: 0.0
DSFX_WAVESREVERB_REVERBTIME_MIN                 :: 0.001
DSFX_WAVESREVERB_REVERBTIME_MAX                 :: 3000.0
DSFX_WAVESREVERB_REVERBTIME_DEFAULT             :: 1000.0
DSFX_WAVESREVERB_HIGHFREQRTRATIO_MIN            :: 0.001
DSFX_WAVESREVERB_HIGHFREQRTRATIO_MAX            :: 0.999
DSFX_WAVESREVERB_HIGHFREQRTRATIO_DEFAULT        :: 0.001
DSCFX_AEC_MODE_PASS_THROUGH                     :: 0x0
DSCFX_AEC_MODE_HALF_DUPLEX                      :: 0x1
DSCFX_AEC_MODE_FULL_DUPLEX                      :: 0x2
DSCFX_AEC_STATUS_HISTORY_UNINITIALIZED          :: 0x0
DSCFX_AEC_STATUS_HISTORY_CONTINUOUSLY_CONVERGED :: 0x1
DSCFX_AEC_STATUS_HISTORY_PREVIOUSLY_DIVERGED    :: 0x2
DSCFX_AEC_STATUS_CURRENTLY_CONVERGED            :: 0x8

///////////////////////////////////////////////
// Return codes
///////////////////////////////////////////////
DS_OK                    :: 0x00000000
DSERR_OUTOFMEMORY        :: 0x00000007
DSERR_NOINTERFACE        :: 0x000001AE
DS_NO_VIRTUALIZATION     :: 0x0878000A
DS_INCOMPLETE            :: 0x08780014
DSERR_UNSUPPORTED        :: 0x80004001
DSERR_GENERIC            :: 0x80004005
DSERR_ACCESSDENIED       :: 0x80070005
DSERR_INVALIDPARAM       :: 0x80070057
DSERR_ALLOCATED          :: 0x8878000A
DSERR_CONTROLUNAVAIL     :: 0x8878001E
DSERR_INVALIDCALL        :: 0x88780032
DSERR_PRIOLEVELNEEDED    :: 0x88780046
DSERR_BADFORMAT          :: 0x88780064
DSERR_NODRIVER           :: 0x88780078
DSERR_ALREADYINITIALIZED :: 0x88780082
DSERR_BUFFERLOST         :: 0x88780096
DSERR_OTHERAPPHASPRIO    :: 0x887800A0
DSERR_UNINITIALIZED      :: 0x887800AA
DSERR_BUFFERTOOSMALL     :: 0x887810B4
DSERR_DS8_REQUIRED       :: 0x887810BE
DSERR_SENDLOOP           :: 0x887810C8
DSERR_BADSENDBUFFERGUID  :: 0x887810D2
DSERR_FXUNAVAILABLE      :: 0x887810DC
DSERR_OBJECTNOTFOUND     :: 0x88781161

///////////////////////////////////////////////
// Flags
///////////////////////////////////////////////
/* Windows XP SP2 and higher, Windows Server 2003 SP1 and higher, Longhorn, or higher */
//@note(zh): Setting this should be fine. I doubt we will ever have to support older stuff.
DIRECTSOUND_VERSION           :: 0x0900
DSCAPS_PRIMARYMONO            :: 0x00000001
DSCAPS_PRIMARYSTEREO          :: 0x00000002
DSCAPS_PRIMARY8BIT            :: 0x00000004
DSCAPS_PRIMARY16BIT           :: 0x00000008
DSCAPS_CONTINUOUSRATE         :: 0x00000010
DSCAPS_EMULDRIVER             :: 0x00000020
DSCAPS_CERTIFIED              :: 0x00000040
DSCAPS_SECONDARYMONO          :: 0x00000100
DSCAPS_SECONDARYSTEREO        :: 0x00000200
DSCAPS_SECONDARY8BIT          :: 0x00000400
DSCAPS_SECONDARY16BIT         :: 0x00000800
DSSCL_NORMAL                  :: 0x00000001
DSSCL_PRIORITY                :: 0x00000002
DSSCL_EXCLUSIVE               :: 0x00000003
DSSCL_WRITEPRIMARY            :: 0x00000004
DSSPEAKER_DIRECTOUT           :: 0x00000000
DSSPEAKER_HEADPHONE           :: 0x00000001
DSSPEAKER_MONO                :: 0x00000002
DSSPEAKER_QUAD                :: 0x00000003
DSSPEAKER_STEREO              :: 0x00000004
DSSPEAKER_SURROUND            :: 0x00000005
DSSPEAKER_5POINT1             :: 0x00000006  // obsolete 5.1 setting
DSSPEAKER_7POINT1             :: 0x00000007  // obsolete 7.1 setting
DSSPEAKER_7POINT1_SURROUND    :: 0x00000008  // correct 7.1 Home Theater setting
DSSPEAKER_5POINT1_SURROUND    :: 0x00000009  // correct 5.1 setting
DSSPEAKER_7POINT1_WIDE        :: DSSPEAKER_7POINT1
DSSPEAKER_5POINT1_BACK        :: DSSPEAKER_5POINT1
DSSPEAKER_GEOMETRY_MIN        :: 0x00000005  //   5 degrees
DSSPEAKER_GEOMETRY_NARROW     :: 0x0000000A  //  10 degrees
DSSPEAKER_GEOMETRY_WIDE       :: 0x00000014  //  20 degrees
DSSPEAKER_GEOMETRY_MAX        :: 0x000000B4  // 180 degrees
DSSPEAKER_COMBINED :: #force_inline proc(c, g: c.int) -> win32.DWORD { return win32.DWORD(win32.BYTE(c)) | win32.DWORD(win32.BYTE(g)) << 16 }
DSSPEAKER_CONFIG   :: #force_inline proc(a: c.int)    -> win32.BYTE { return win32.BYTE(a) }
DSSPEAKER_GEOMETRY :: #force_inline proc(a: c.int)    -> win32.BYTE { return (win32.BYTE(win32.DWORD(a)) >> 16) & 0x00FF }
DSBCAPS_PRIMARYBUFFER         :: 0x00000001
DSBCAPS_STATIC                :: 0x00000002
DSBCAPS_LOCHARDWARE           :: 0x00000004
DSBCAPS_LOCSOFTWARE           :: 0x00000008
DSBCAPS_CTRL3D                :: 0x00000010
DSBCAPS_CTRLFREQUENCY         :: 0x00000020
DSBCAPS_CTRLPAN               :: 0x00000040
DSBCAPS_CTRLVOLUME            :: 0x00000080
DSBCAPS_CTRLPOSITIONNOTIFY    :: 0x00000100
DSBCAPS_CTRLFX                :: 0x00000200
DSBCAPS_STICKYFOCUS           :: 0x00004000
DSBCAPS_GLOBALFOCUS           :: 0x00008000
DSBCAPS_GETCURRENTPOSITION2   :: 0x00010000
DSBCAPS_MUTE3DATMAXDISTANCE   :: 0x00020000
DSBCAPS_LOCDEFER              :: 0x00040000
DSBCAPS_TRUEPLAYPOSITION      :: 0x00080000
DSBPLAY_LOOPING               :: 0x00000001
DSBPLAY_LOCHARDWARE           :: 0x00000002
DSBPLAY_LOCSOFTWARE           :: 0x00000004
DSBPLAY_TERMINATEBY_TIME      :: 0x00000008
DSBPLAY_TERMINATEBY_DISTANCE  :: 0x000000010
DSBPLAY_TERMINATEBY_PRIORITY  :: 0x000000020
DSBSTATUS_PLAYING             :: 0x00000001
DSBSTATUS_BUFFERLOST          :: 0x00000002
DSBSTATUS_LOOPING             :: 0x00000004
DSBSTATUS_LOCHARDWARE         :: 0x00000008
DSBSTATUS_LOCSOFTWARE         :: 0x00000010
DSBSTATUS_TERMINATED          :: 0x00000020
DSBLOCK_FROMWRITECURSOR       :: 0x00000001
DSBLOCK_ENTIREBUFFER          :: 0x00000002
DSBFREQUENCY_ORIGINAL         :: 0
DSBFREQUENCY_MIN              :: 100
when DIRECTSOUND_VERSION >= 0x0900 {
	DSBFREQUENCY_MAX          :: 200000
} else {
	DSBFREQUENCY_MAX          :: 100000
}
DSBPAN_LEFT                   :: -10000
DSBPAN_CENTER                 :: 0
DSBPAN_RIGHT                  :: 10000
DSBVOLUME_MIN                 :: -10000
DSBVOLUME_MAX                 :: 0
DSBSIZE_MIN                   :: 4
DSBSIZE_MAX                   :: 0x0FFFFFFF
DSBSIZE_FX_MIN                :: 150  // NOTE: Milliseconds, not bytes
DSBNOTIFICATIONS_MAX          :: 100000
DS3DMODE_NORMAL               :: 0x00000000
DS3DMODE_HEADRELATIVE         :: 0x00000001
DS3DMODE_DISABLE              :: 0x00000002
DS3D_IMMEDIATE                :: 0x00000000
DS3D_DEFERRED                 :: 0x00000001
DS3D_MINDISTANCEFACTOR        :: FLT_MIN
DS3D_MAXDISTANCEFACTOR        :: FLT_MAX
DS3D_DEFAULTDISTANCEFACTOR    :: 1.0
DS3D_MINROLLOFFFACTOR         :: 0.0
DS3D_MAXROLLOFFFACTOR         :: 10.0
DS3D_DEFAULTROLLOFFFACTOR     :: 1.0
DS3D_MINDOPPLERFACTOR         :: 0.0
DS3D_MAXDOPPLERFACTOR         :: 10.0
DS3D_DEFAULTDOPPLERFACTOR     :: 1.0
DS3D_DEFAULTMINDISTANCE       :: 1.0
DS3D_DEFAULTMAXDISTANCE       :: 1000000000.0
DS3D_MINCONEANGLE             :: 0
DS3D_MAXCONEANGLE             :: 360
DS3D_DEFAULTCONEANGLE         :: 360
DS3D_DEFAULTCONEOUTSIDEVOLUME :: DSBVOLUME_MAX

// IDirectSoundCapture attributes
DSCCAPS_EMULDRIVER            :: DSCAPS_EMULDRIVER
DSCCAPS_CERTIFIED             :: DSCAPS_CERTIFIED
DSCCAPS_MULTIPLECAPTURE       :: 0x00000001

// IDirectSoundCaptureBuffer attributes
DSCBCAPS_WAVEMAPPED           :: 0x80000000
when DIRECTSOUND_VERSION >= 0x0800 {
	DSCBCAPS_CTRLFX           :: 0x00000200
}
DSCBLOCK_ENTIREBUFFER         :: 0x00000001
DSCBSTATUS_CAPTURING          :: 0x00000001
DSCBSTATUS_LOOPING            :: 0x00000002
DSCBSTART_LOOPING             :: 0x00000001
DSBPN_OFFSETSTOP              :: 0xFFFFFFFF
DS_CERTIFIED                  :: 0x00000000
DS_UNCERTIFIED                :: 0x00000001

///////////////////////////////////////////////
// Wave formats
///////////////////////////////////////////////
/* defines for dwFormat field of WAVEINCAPS and WAVEOUTCAPS */
WAVE_FORMAT_PCM    :: 1          /* flags for wFormatTag field of WAVEFORMAT */
WAVE_INVALIDFORMAT :: 0x00000000 /* invalid format */
WAVE_FORMAT_1M08   :: 0x00000001 /* 11.025 kHz, Mono,   8-bit  */
WAVE_FORMAT_1S08   :: 0x00000002 /* 11.025 kHz, Stereo, 8-bit  */
WAVE_FORMAT_1M16   :: 0x00000004 /* 11.025 kHz, Mono,   16-bit */
WAVE_FORMAT_1S16   :: 0x00000008 /* 11.025 kHz, Stereo, 16-bit */
WAVE_FORMAT_2M08   :: 0x00000010 /* 22.05  kHz, Mono,   8-bit  */
WAVE_FORMAT_2S08   :: 0x00000020 /* 22.05  kHz, Stereo, 8-bit  */
WAVE_FORMAT_2M16   :: 0x00000040 /* 22.05  kHz, Mono,   16-bit */
WAVE_FORMAT_2S16   :: 0x00000080 /* 22.05  kHz, Stereo, 16-bit */
WAVE_FORMAT_4M08   :: 0x00000100 /* 44.1   kHz, Mono,   8-bit  */
WAVE_FORMAT_4S08   :: 0x00000200 /* 44.1   kHz, Stereo, 8-bit  */
WAVE_FORMAT_4M16   :: 0x00000400 /* 44.1   kHz, Mono,   16-bit */
WAVE_FORMAT_4S16   :: 0x00000800 /* 44.1   kHz, Stereo, 16-bit */
WAVE_FORMAT_44M08  :: 0x00000100 /* 44.1   kHz, Mono,   8-bit  */
WAVE_FORMAT_44S08  :: 0x00000200 /* 44.1   kHz, Stereo, 8-bit  */
WAVE_FORMAT_44M16  :: 0x00000400 /* 44.1   kHz, Mono,   16-bit */
WAVE_FORMAT_44S16  :: 0x00000800 /* 44.1   kHz, Stereo, 16-bit */
WAVE_FORMAT_48M08  :: 0x00001000 /* 48     kHz, Mono,   8-bit  */
WAVE_FORMAT_48S08  :: 0x00002000 /* 48     kHz, Stereo, 8-bit  */
WAVE_FORMAT_48M16  :: 0x00004000 /* 48     kHz, Mono,   16-bit */
WAVE_FORMAT_48S16  :: 0x00008000 /* 48     kHz, Stereo, 16-bit */
WAVE_FORMAT_96M08  :: 0x00010000 /* 96     kHz, Mono,   8-bit  */
WAVE_FORMAT_96S08  :: 0x00020000 /* 96     kHz, Stereo, 8-bit  */
WAVE_FORMAT_96M16  :: 0x00040000 /* 96     kHz, Mono,   16-bit */
WAVE_FORMAT_96S16  :: 0x00080000 /* 96     kHz, Stereo, 16-bit */
// WAV compression format codes
// @note(zh): Taken from mmreg.h
//
WAVE_FORMAT_UNKNOWN                             :: 0x0000 /* Microsoft Corporation */
WAVE_FORMAT_ADPCM                               :: 0x0002 /* Microsoft Corporation */
WAVE_FORMAT_IEEE_FLOAT                          :: 0x0003 /* Microsoft Corporation */
WAVE_FORMAT_VSELP                               :: 0x0004 /* Compaq Computer Corp. */
WAVE_FORMAT_IBM_CVSD                            :: 0x0005 /* IBM Corporation */
WAVE_FORMAT_ALAW                                :: 0x0006 /* Microsoft Corporation */
WAVE_FORMAT_MULAW                               :: 0x0007 /* Microsoft Corporation */
WAVE_FORMAT_DTS                                 :: 0x0008 /* Microsoft Corporation */
WAVE_FORMAT_DRM                                 :: 0x0009 /* Microsoft Corporation */
WAVE_FORMAT_WMAVOICE9                           :: 0x000A /* Microsoft Corporation */
WAVE_FORMAT_WMAVOICE10                          :: 0x000B /* Microsoft Corporation */
WAVE_FORMAT_OKI_ADPCM                           :: 0x0010 /* OKI */
WAVE_FORMAT_DVI_ADPCM                           :: 0x0011 /* Intel Corporation */
WAVE_FORMAT_IMA_ADPCM                           :: (WAVE_FORMAT_DVI_ADPCM) /*  Intel Corporation */
WAVE_FORMAT_MEDIASPACE_ADPCM                    :: 0x0012 /* Videologic */
WAVE_FORMAT_SIERRA_ADPCM                        :: 0x0013 /* Sierra Semiconductor Corp */
WAVE_FORMAT_G723_ADPCM                          :: 0x0014 /* Antex Electronics Corporation */
WAVE_FORMAT_DIGISTD                             :: 0x0015 /* DSP Solutions, Inc. */
WAVE_FORMAT_DIGIFIX                             :: 0x0016 /* DSP Solutions, Inc. */
WAVE_FORMAT_DIALOGIC_OKI_ADPCM                  :: 0x0017 /* Dialogic Corporation */
WAVE_FORMAT_MEDIAVISION_ADPCM                   :: 0x0018 /* Media Vision, Inc. */
WAVE_FORMAT_CU_CODEC                            :: 0x0019 /* Hewlett-Packard Company */
WAVE_FORMAT_HP_DYN_VOICE                        :: 0x001A /* Hewlett-Packard Company */
WAVE_FORMAT_YAMAHA_ADPCM                        :: 0x0020 /* Yamaha Corporation of America */
WAVE_FORMAT_SONARC                              :: 0x0021 /* Speech Compression */
WAVE_FORMAT_DSPGROUP_TRUESPEECH                 :: 0x0022 /* DSP Group, Inc */
WAVE_FORMAT_ECHOSC1                             :: 0x0023 /* Echo Speech Corporation */
WAVE_FORMAT_AUDIOFILE_AF36                      :: 0x0024 /* Virtual Music, Inc. */
WAVE_FORMAT_APTX                                :: 0x0025 /* Audio Processing Technology */
WAVE_FORMAT_AUDIOFILE_AF10                      :: 0x0026 /* Virtual Music, Inc. */
WAVE_FORMAT_PROSODY_1612                        :: 0x0027 /* Aculab plc */
WAVE_FORMAT_LRC                                 :: 0x0028 /* Merging Technologies S.A. */
WAVE_FORMAT_DOLBY_AC2                           :: 0x0030 /* Dolby Laboratories */
WAVE_FORMAT_GSM610                              :: 0x0031 /* Microsoft Corporation */
WAVE_FORMAT_MSNAUDIO                            :: 0x0032 /* Microsoft Corporation */
WAVE_FORMAT_ANTEX_ADPCME                        :: 0x0033 /* Antex Electronics Corporation */
WAVE_FORMAT_CONTROL_RES_VQLPC                   :: 0x0034 /* Control Resources Limited */
WAVE_FORMAT_DIGIREAL                            :: 0x0035 /* DSP Solutions, Inc. */
WAVE_FORMAT_DIGIADPCM                           :: 0x0036 /* DSP Solutions, Inc. */
WAVE_FORMAT_CONTROL_RES_CR10                    :: 0x0037 /* Control Resources Limited */
WAVE_FORMAT_NMS_VBXADPCM                        :: 0x0038 /* Natural MicroSystems */
WAVE_FORMAT_CS_IMAADPCM                         :: 0x0039 /* Crystal Semiconductor IMA ADPCM */
WAVE_FORMAT_ECHOSC3                             :: 0x003A /* Echo Speech Corporation */
WAVE_FORMAT_ROCKWELL_ADPCM                      :: 0x003B /* Rockwell International */
WAVE_FORMAT_ROCKWELL_DIGITALK                   :: 0x003C /* Rockwell International */
WAVE_FORMAT_XEBEC                               :: 0x003D /* Xebec Multimedia Solutions Limited */
WAVE_FORMAT_G721_ADPCM                          :: 0x0040 /* Antex Electronics Corporation */
WAVE_FORMAT_G728_CELP                           :: 0x0041 /* Antex Electronics Corporation */
WAVE_FORMAT_MSG723                              :: 0x0042 /* Microsoft Corporation */
WAVE_FORMAT_INTEL_G723_1                        :: 0x0043 /* Intel Corp. */
WAVE_FORMAT_INTEL_G729                          :: 0x0044 /* Intel Corp. */
WAVE_FORMAT_SHARP_G726                          :: 0x0045 /* Sharp */
WAVE_FORMAT_MPEG                                :: 0x0050 /* Microsoft Corporation */
WAVE_FORMAT_RT24                                :: 0x0052 /* InSoft, Inc. */
WAVE_FORMAT_PAC                                 :: 0x0053 /* InSoft, Inc. */
WAVE_FORMAT_MPEGLAYER3                          :: 0x0055 /* ISO/MPEG Layer3 Format Tag */
WAVE_FORMAT_LUCENT_G723                         :: 0x0059 /* Lucent Technologies */
WAVE_FORMAT_CIRRUS                              :: 0x0060 /* Cirrus Logic */
WAVE_FORMAT_ESPCM                               :: 0x0061 /* ESS Technology */
WAVE_FORMAT_VOXWARE                             :: 0x0062 /* Voxware Inc */
WAVE_FORMAT_CANOPUS_ATRAC                       :: 0x0063 /* Canopus, co., Ltd. */
WAVE_FORMAT_G726_ADPCM                          :: 0x0064 /* APICOM */
WAVE_FORMAT_G722_ADPCM                          :: 0x0065 /* APICOM */
WAVE_FORMAT_DSAT                                :: 0x0066 /* Microsoft Corporation */
WAVE_FORMAT_DSAT_DISPLAY                        :: 0x0067 /* Microsoft Corporation */
WAVE_FORMAT_VOXWARE_BYTE_ALIGNED                :: 0x0069 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_AC8                         :: 0x0070 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_AC10                        :: 0x0071 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_AC16                        :: 0x0072 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_AC20                        :: 0x0073 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_RT24                        :: 0x0074 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_RT29                        :: 0x0075 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_RT29HW                      :: 0x0076 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_VR12                        :: 0x0077 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_VR18                        :: 0x0078 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_TQ40                        :: 0x0079 /* Voxware Inc */
WAVE_FORMAT_VOXWARE_SC3                         :: 0x007A /* Voxware Inc */
WAVE_FORMAT_VOXWARE_SC3_1                       :: 0x007B /* Voxware Inc */
WAVE_FORMAT_SOFTSOUND                           :: 0x0080 /* Softsound, Ltd. */
WAVE_FORMAT_VOXWARE_TQ60                        :: 0x0081 /* Voxware Inc */
WAVE_FORMAT_MSRT24                              :: 0x0082 /* Microsoft Corporation */
WAVE_FORMAT_G729A                               :: 0x0083 /* AT&T Labs, Inc. */
WAVE_FORMAT_MVI_MVI2                            :: 0x0084 /* Motion Pixels */
WAVE_FORMAT_DF_G726                             :: 0x0085 /* DataFusion Systems (Pty) (Ltd) */
WAVE_FORMAT_DF_GSM610                           :: 0x0086 /* DataFusion Systems (Pty) (Ltd) */
WAVE_FORMAT_ISIAUDIO                            :: 0x0088 /* Iterated Systems, Inc. */
WAVE_FORMAT_ONLIVE                              :: 0x0089 /* OnLive! Technologies, Inc. */
WAVE_FORMAT_MULTITUDE_FT_SX20                   :: 0x008A /* Multitude Inc. */
WAVE_FORMAT_INFOCOM_ITS_G721_ADPCM              :: 0x008B /* Infocom */
WAVE_FORMAT_CONVEDIA_G729                       :: 0x008C /* Convedia Corp. */
WAVE_FORMAT_CONGRUENCY                          :: 0x008D /* Congruency Inc. */
WAVE_FORMAT_SBC24                               :: 0x0091 /* Siemens Business Communications Sys */
WAVE_FORMAT_DOLBY_AC3_SPDIF                     :: 0x0092 /* Sonic Foundry */
WAVE_FORMAT_MEDIASONIC_G723                     :: 0x0093 /* MediaSonic */
WAVE_FORMAT_PROSODY_8KBPS                       :: 0x0094 /* Aculab plc */
WAVE_FORMAT_ZYXEL_ADPCM                         :: 0x0097 /* ZyXEL Communications, Inc. */
WAVE_FORMAT_PHILIPS_LPCBB                       :: 0x0098 /* Philips Speech Processing */
WAVE_FORMAT_PACKED                              :: 0x0099 /* Studer Professional Audio AG */
WAVE_FORMAT_MALDEN_PHONYTALK                    :: 0x00A0 /* Malden Electronics Ltd. */
WAVE_FORMAT_RACAL_RECORDER_GSM                  :: 0x00A1 /* Racal recorders */
WAVE_FORMAT_RACAL_RECORDER_G720_A               :: 0x00A2 /* Racal recorders */
WAVE_FORMAT_RACAL_RECORDER_G723_1               :: 0x00A3 /* Racal recorders */
WAVE_FORMAT_RACAL_RECORDER_TETRA_ACELP          :: 0x00A4 /* Racal recorders */
WAVE_FORMAT_NEC_AAC                             :: 0x00B0 /* NEC Corp. */
WAVE_FORMAT_RAW_AAC1                            :: 0x00FF /* For Raw AAC, with format block AudioSpecificConfig() (as defined by MPEG-4), that follows WAVEFORMATEX */
WAVE_FORMAT_RHETOREX_ADPCM                      :: 0x0100 /* Rhetorex Inc. */
WAVE_FORMAT_IRAT                                :: 0x0101 /* BeCubed Software Inc. */
WAVE_FORMAT_VIVO_G723                           :: 0x0111 /* Vivo Software */
WAVE_FORMAT_VIVO_SIREN                          :: 0x0112 /* Vivo Software */
WAVE_FORMAT_PHILIPS_CELP                        :: 0x0120 /* Philips Speech Processing */
WAVE_FORMAT_PHILIPS_GRUNDIG                     :: 0x0121 /* Philips Speech Processing */
WAVE_FORMAT_DIGITAL_G723                        :: 0x0123 /* Digital Equipment Corporation */
WAVE_FORMAT_SANYO_LD_ADPCM                      :: 0x0125 /* Sanyo Electric Co., Ltd. */
WAVE_FORMAT_SIPROLAB_ACEPLNET                   :: 0x0130 /* Sipro Lab Telecom Inc. */
WAVE_FORMAT_SIPROLAB_ACELP4800                  :: 0x0131 /* Sipro Lab Telecom Inc. */
WAVE_FORMAT_SIPROLAB_ACELP8V3                   :: 0x0132 /* Sipro Lab Telecom Inc. */
WAVE_FORMAT_SIPROLAB_G729                       :: 0x0133 /* Sipro Lab Telecom Inc. */
WAVE_FORMAT_SIPROLAB_G729A                      :: 0x0134 /* Sipro Lab Telecom Inc. */
WAVE_FORMAT_SIPROLAB_KELVIN                     :: 0x0135 /* Sipro Lab Telecom Inc. */
WAVE_FORMAT_VOICEAGE_AMR                        :: 0x0136 /* VoiceAge Corp. */
WAVE_FORMAT_G726ADPCM                           :: 0x0140 /* Dictaphone Corporation */
WAVE_FORMAT_DICTAPHONE_CELP68                   :: 0x0141 /* Dictaphone Corporation */
WAVE_FORMAT_DICTAPHONE_CELP54                   :: 0x0142 /* Dictaphone Corporation */
WAVE_FORMAT_QUALCOMM_PUREVOICE                  :: 0x0150 /* Qualcomm, Inc. */
WAVE_FORMAT_QUALCOMM_HALFRATE                   :: 0x0151 /* Qualcomm, Inc. */
WAVE_FORMAT_TUBGSM                              :: 0x0155 /* Ring Zero Systems, Inc. */
WAVE_FORMAT_MSAUDIO1                            :: 0x0160 /* Microsoft Corporation */
WAVE_FORMAT_WMAUDIO2                            :: 0x0161 /* Microsoft Corporation */
WAVE_FORMAT_WMAUDIO3                            :: 0x0162 /* Microsoft Corporation */
WAVE_FORMAT_WMAUDIO_LOSSLESS                    :: 0x0163 /* Microsoft Corporation */
WAVE_FORMAT_WMASPDIF                            :: 0x0164 /* Microsoft Corporation */
WAVE_FORMAT_UNISYS_NAP_ADPCM                    :: 0x0170 /* Unisys Corp. */
WAVE_FORMAT_UNISYS_NAP_ULAW                     :: 0x0171 /* Unisys Corp. */
WAVE_FORMAT_UNISYS_NAP_ALAW                     :: 0x0172 /* Unisys Corp. */
WAVE_FORMAT_UNISYS_NAP_16K                      :: 0x0173 /* Unisys Corp. */
WAVE_FORMAT_SYCOM_ACM_SYC008                    :: 0x0174 /* SyCom Technologies */
WAVE_FORMAT_SYCOM_ACM_SYC701_G726L              :: 0x0175 /* SyCom Technologies */
WAVE_FORMAT_SYCOM_ACM_SYC701_CELP54             :: 0x0176 /* SyCom Technologies */
WAVE_FORMAT_SYCOM_ACM_SYC701_CELP68             :: 0x0177 /* SyCom Technologies */
WAVE_FORMAT_KNOWLEDGE_ADVENTURE_ADPCM           :: 0x0178 /* Knowledge Adventure, Inc. */
WAVE_FORMAT_FRAUNHOFER_IIS_MPEG2_AAC            :: 0x0180 /* Fraunhofer IIS */
WAVE_FORMAT_DTS_DS                              :: 0x0190 /* Digital Theatre Systems, Inc. */
WAVE_FORMAT_CREATIVE_ADPCM                      :: 0x0200 /* Creative Labs, Inc */
WAVE_FORMAT_CREATIVE_FASTSPEECH8                :: 0x0202 /* Creative Labs, Inc */
WAVE_FORMAT_CREATIVE_FASTSPEECH10               :: 0x0203 /* Creative Labs, Inc */
WAVE_FORMAT_UHER_ADPCM                          :: 0x0210 /* UHER informatic GmbH */
WAVE_FORMAT_ULEAD_DV_AUDIO                      :: 0x0215 /* Ulead Systems, Inc. */
WAVE_FORMAT_ULEAD_DV_AUDIO_1                    :: 0x0216 /* Ulead Systems, Inc. */
WAVE_FORMAT_QUARTERDECK                         :: 0x0220 /* Quarterdeck Corporation */
WAVE_FORMAT_ILINK_VC                            :: 0x0230 /* I-link Worldwide */
WAVE_FORMAT_RAW_SPORT                           :: 0x0240 /* Aureal Semiconductor */
WAVE_FORMAT_ESST_AC3                            :: 0x0241 /* ESS Technology, Inc. */
WAVE_FORMAT_GENERIC_PASSTHRU                    :: 0x0249
WAVE_FORMAT_IPI_HSX                             :: 0x0250 /* Interactive Products, Inc. */
WAVE_FORMAT_IPI_RPELP                           :: 0x0251 /* Interactive Products, Inc. */
WAVE_FORMAT_CS2                                 :: 0x0260 /* Consistent Software */
WAVE_FORMAT_SONY_SCX                            :: 0x0270 /* Sony Corp. */
WAVE_FORMAT_SONY_SCY                            :: 0x0271 /* Sony Corp. */
WAVE_FORMAT_SONY_ATRAC3                         :: 0x0272 /* Sony Corp. */
WAVE_FORMAT_SONY_SPC                            :: 0x0273 /* Sony Corp. */
WAVE_FORMAT_TELUM_AUDIO                         :: 0x0280 /* Telum Inc. */
WAVE_FORMAT_TELUM_IA_AUDIO                      :: 0x0281 /* Telum Inc. */
WAVE_FORMAT_NORCOM_VOICE_SYSTEMS_ADPCM          :: 0x0285 /* Norcom Electronics Corp. */
WAVE_FORMAT_FM_TOWNS_SND                        :: 0x0300 /* Fujitsu Corp. */
WAVE_FORMAT_MICRONAS                            :: 0x0350 /* Micronas Semiconductors, Inc. */
WAVE_FORMAT_MICRONAS_CELP833                    :: 0x0351 /* Micronas Semiconductors, Inc. */
WAVE_FORMAT_BTV_DIGITAL                         :: 0x0400 /* Brooktree Corporation */
WAVE_FORMAT_INTEL_MUSIC_CODER                   :: 0x0401 /* Intel Corp. */
WAVE_FORMAT_INDEO_AUDIO                         :: 0x0402 /* Ligos */
WAVE_FORMAT_QDESIGN_MUSIC                       :: 0x0450 /* QDesign Corporation */
WAVE_FORMAT_ON2_VP7_AUDIO                       :: 0x0500 /* On2 Technologies */
WAVE_FORMAT_ON2_VP6_AUDIO                       :: 0x0501 /* On2 Technologies */
WAVE_FORMAT_VME_VMPCM                           :: 0x0680 /* AT&T Labs, Inc. */
WAVE_FORMAT_TPC                                 :: 0x0681 /* AT&T Labs, Inc. */
WAVE_FORMAT_LIGHTWAVE_LOSSLESS                  :: 0x08AE /* Clearjump */
WAVE_FORMAT_OLIGSM                              :: 0x1000 /* Ing C. Olivetti & C., S.p.A. */
WAVE_FORMAT_OLIADPCM                            :: 0x1001 /* Ing C. Olivetti & C., S.p.A. */
WAVE_FORMAT_OLICELP                             :: 0x1002 /* Ing C. Olivetti & C., S.p.A. */
WAVE_FORMAT_OLISBC                              :: 0x1003 /* Ing C. Olivetti & C., S.p.A. */
WAVE_FORMAT_OLIOPR                              :: 0x1004 /* Ing C. Olivetti & C., S.p.A. */
WAVE_FORMAT_LH_CODEC                            :: 0x1100 /* Lernout & Hauspie */
WAVE_FORMAT_LH_CODEC_CELP                       :: 0x1101 /* Lernout & Hauspie */
WAVE_FORMAT_LH_CODEC_SBC8                       :: 0x1102 /* Lernout & Hauspie */
WAVE_FORMAT_LH_CODEC_SBC12                      :: 0x1103 /* Lernout & Hauspie */
WAVE_FORMAT_LH_CODEC_SBC16                      :: 0x1104 /* Lernout & Hauspie */
WAVE_FORMAT_NORRIS                              :: 0x1400 /* Norris Communications, Inc. */
WAVE_FORMAT_ISIAUDIO_2                          :: 0x1401 /* ISIAudio */
WAVE_FORMAT_SOUNDSPACE_MUSICOMPRESS             :: 0x1500 /* AT&T Labs, Inc. */
WAVE_FORMAT_MPEG_ADTS_AAC                       :: 0x1600 /* Microsoft Corporation */
WAVE_FORMAT_MPEG_RAW_AAC                        :: 0x1601 /* Microsoft Corporation */
WAVE_FORMAT_MPEG_LOAS                           :: 0x1602 /* Microsoft Corporation (MPEG-4 Audio Transport Streams (LOAS/LATM) */
WAVE_FORMAT_NOKIA_MPEG_ADTS_AAC                 :: 0x1608 /* Microsoft Corporation */
WAVE_FORMAT_NOKIA_MPEG_RAW_AAC                  :: 0x1609 /* Microsoft Corporation */
WAVE_FORMAT_VODAFONE_MPEG_ADTS_AAC              :: 0x160A /* Microsoft Corporation */
WAVE_FORMAT_VODAFONE_MPEG_RAW_AAC               :: 0x160B /* Microsoft Corporation */
WAVE_FORMAT_MPEG_HEAAC                          :: 0x1610 /* Microsoft Corporation (MPEG-2 AAC or MPEG-4 HE-AAC v1/v2 streams with any payload (ADTS, ADIF, LOAS/LATM, RAW). Format block includes MP4 AudioSpecificConfig() -- see HEAACWAVEFORMAT below */
WAVE_FORMAT_VOXWARE_RT24_SPEECH                 :: 0x181C /* Voxware Inc. */
WAVE_FORMAT_SONICFOUNDRY_LOSSLESS               :: 0x1971 /* Sonic Foundry */
WAVE_FORMAT_INNINGS_TELECOM_ADPCM               :: 0x1979 /* Innings Telecom Inc. */
WAVE_FORMAT_LUCENT_SX8300P                      :: 0x1C07 /* Lucent Technologies */
WAVE_FORMAT_LUCENT_SX5363S                      :: 0x1C0C /* Lucent Technologies */
WAVE_FORMAT_CUSEEME                             :: 0x1F03 /* CUSeeMe */
WAVE_FORMAT_NTCSOFT_ALF2CM_ACM                  :: 0x1FC4 /* NTCSoft */
WAVE_FORMAT_DVM                                 :: 0x2000 /* FAST Multimedia AG */
WAVE_FORMAT_DTS2                                :: 0x2001
WAVE_FORMAT_MAKEAVIS                            :: 0x3313
WAVE_FORMAT_DIVIO_MPEG4_AAC                     :: 0x4143 /* Divio, Inc. */
WAVE_FORMAT_NOKIA_ADAPTIVE_MULTIRATE            :: 0x4201 /* Nokia */
WAVE_FORMAT_DIVIO_G726                          :: 0x4243 /* Divio, Inc. */
WAVE_FORMAT_LEAD_SPEECH                         :: 0x434C /* LEAD Technologies */
WAVE_FORMAT_LEAD_VORBIS                         :: 0x564C /* LEAD Technologies */
WAVE_FORMAT_WAVPACK_AUDIO                       :: 0x5756 /* xiph.org */
WAVE_FORMAT_ALAC                                :: 0x6C61 /* Apple Lossless */
WAVE_FORMAT_OGG_VORBIS_MODE_1                   :: 0x674F /* Ogg Vorbis */
WAVE_FORMAT_OGG_VORBIS_MODE_2                   :: 0x6750 /* Ogg Vorbis */
WAVE_FORMAT_OGG_VORBIS_MODE_3                   :: 0x6751 /* Ogg Vorbis */
WAVE_FORMAT_OGG_VORBIS_MODE_1_PLUS              :: 0x676F /* Ogg Vorbis */
WAVE_FORMAT_OGG_VORBIS_MODE_2_PLUS              :: 0x6770 /* Ogg Vorbis */
WAVE_FORMAT_OGG_VORBIS_MODE_3_PLUS              :: 0x6771 /* Ogg Vorbis */
WAVE_FORMAT_3COM_NBX                            :: 0x7000 /* 3COM Corp. */
WAVE_FORMAT_OPUS                                :: 0x704F /* Opus */
WAVE_FORMAT_FAAD_AAC                            :: 0x706D
WAVE_FORMAT_AMR_NB                              :: 0x7361 /* AMR Narrowband */
WAVE_FORMAT_AMR_WB                              :: 0x7362 /* AMR Wideband */
WAVE_FORMAT_AMR_WP                              :: 0x7363 /* AMR Wideband Plus */
WAVE_FORMAT_GSM_AMR_CBR                         :: 0x7A21 /* GSMA/3GPP */
WAVE_FORMAT_GSM_AMR_VBR_SID                     :: 0x7A22 /* GSMA/3GPP */
WAVE_FORMAT_COMVERSE_INFOSYS_G723_1             :: 0xA100 /* Comverse Infosys */
WAVE_FORMAT_COMVERSE_INFOSYS_AVQSBC             :: 0xA101 /* Comverse Infosys */
WAVE_FORMAT_COMVERSE_INFOSYS_SBC                :: 0xA102 /* Comverse Infosys */
WAVE_FORMAT_SYMBOL_G729_A                       :: 0xA103 /* Symbol Technologies */
WAVE_FORMAT_VOICEAGE_AMR_WB                     :: 0xA104 /* VoiceAge Corp. */
WAVE_FORMAT_INGENIENT_G726                      :: 0xA105 /* Ingenient Technologies, Inc. */
WAVE_FORMAT_MPEG4_AAC                           :: 0xA106 /* ISO/MPEG-4 */
WAVE_FORMAT_ENCORE_G726                         :: 0xA107 /* Encore Software */
WAVE_FORMAT_ZOLL_ASAO                           :: 0xA108 /* ZOLL Medical Corp. */
WAVE_FORMAT_SPEEX_VOICE                         :: 0xA109 /* xiph.org */
WAVE_FORMAT_VIANIX_MASC                         :: 0xA10A /* Vianix LLC */
WAVE_FORMAT_WM9_SPECTRUM_ANALYZER               :: 0xA10B /* Microsoft */
WAVE_FORMAT_WMF_SPECTRUM_ANAYZER                :: 0xA10C /* Microsoft */
WAVE_FORMAT_GSM_610                             :: 0xA10D
WAVE_FORMAT_GSM_620                             :: 0xA10E
WAVE_FORMAT_GSM_660                             :: 0xA10F
WAVE_FORMAT_GSM_690                             :: 0xA110
WAVE_FORMAT_GSM_ADAPTIVE_MULTIRATE_WB           :: 0xA111
WAVE_FORMAT_POLYCOM_G722                        :: 0xA112 /* Polycom */
WAVE_FORMAT_POLYCOM_G728                        :: 0xA113 /* Polycom */
WAVE_FORMAT_POLYCOM_G729_A                      :: 0xA114 /* Polycom */
WAVE_FORMAT_POLYCOM_SIREN                       :: 0xA115 /* Polycom */
WAVE_FORMAT_GLOBAL_IP_ILBC                      :: 0xA116 /* Global IP */
WAVE_FORMAT_RADIOTIME_TIME_SHIFT_RADIO          :: 0xA117 /* RadioTime */
WAVE_FORMAT_NICE_ACA                            :: 0xA118 /* Nice Systems */
WAVE_FORMAT_NICE_ADPCM                          :: 0xA119 /* Nice Systems */
WAVE_FORMAT_VOCORD_G721                         :: 0xA11A /* Vocord Telecom */
WAVE_FORMAT_VOCORD_G726                         :: 0xA11B /* Vocord Telecom */
WAVE_FORMAT_VOCORD_G722_1                       :: 0xA11C /* Vocord Telecom */
WAVE_FORMAT_VOCORD_G728                         :: 0xA11D /* Vocord Telecom */
WAVE_FORMAT_VOCORD_G729                         :: 0xA11E /* Vocord Telecom */
WAVE_FORMAT_VOCORD_G729_A                       :: 0xA11F /* Vocord Telecom */
WAVE_FORMAT_VOCORD_G723_1                       :: 0xA120 /* Vocord Telecom */
WAVE_FORMAT_VOCORD_LBC                          :: 0xA121 /* Vocord Telecom */
WAVE_FORMAT_NICE_G728                           :: 0xA122 /* Nice Systems */
WAVE_FORMAT_FRACE_TELECOM_G729                  :: 0xA123 /* France Telecom */
WAVE_FORMAT_CODIAN                              :: 0xA124 /* CODIAN */
WAVE_FORMAT_FLAC                                :: 0xF1AC /* flac.sourceforge.net */

///////////////////////////////////////////////
// GUIDS
///////////////////////////////////////////////
// Interfaces
//
GUID_NULL                               := win32.GUID{0, 0, 0, {0, 0, 0, 0, 0, 0, 0, 0}}
GUID_All_Objects                        := win32.GUID{0xaa114de5, 0xc262, 0x4169, {0xa1, 0xc8, 0x23, 0xd6, 0x98, 0xcc, 0x73, 0xb5}}
IID_IDirectSoundBuffer                  := win32.GUID{0x279AFA85, 0x4981, 0x11CE, {0xA5, 0x21, 0x00, 0x20, 0xAF, 0x0B, 0xE5, 0x60}}
IID_IDirectSoundBuffer8                 := win32.GUID{0x6825a449, 0x7524, 0x4d82, {0x92, 0x0f, 0x50, 0xe3, 0x6a, 0xb3, 0xab, 0x1e}}
IID_IDirectSoundCapture                 := win32.GUID{0xb0210781, 0x89cd, 0x11d0, {0xaf, 0x8, 0x0, 0xa0, 0xc9, 0x25, 0xcd, 0x16}}
IID_IDirectSoundCapture8                := IID_IDirectSoundCapture
IID_IDirectSound3DListener              := win32.GUID{0x279AFA84, 0x4981, 0x11CE, {0xA5, 0x21, 0x00, 0x20, 0xAF, 0x0B, 0xE5, 0x60}}
IID_IDirectSound3DListener8             := IID_IDirectSound3DListener
IID_IDirectSound3DBuffer                := win32.GUID{0x279AFA86, 0x4981, 0x11CE, {0xA5, 0x21, 0x00, 0x20, 0xAF, 0x0B, 0xE5, 0x60}}
IID_IDirectSound3DBuffer8               := IID_IDirectSound3DBuffer
IID_IDirectSoundNotify                  := win32.GUID{0xb0210783, 0x89cd, 0x11d0, {0xaf, 0x8, 0x0, 0xa0, 0xc9, 0x25, 0xcd, 0x16}}
IID_IDirectSoundNotify8                 := IID_IDirectSoundNotify
IID_IDirectSoundFXGargle                := win32.GUID{0xd616f352, 0xd622, 0x11ce, {0xaa, 0xc5, 0x00, 0x20, 0xaf, 0x0b, 0x99, 0xa3}}
IID_IDirectSoundFXGargle8               := IID_IDirectSoundFXGargle
IID_IDirectSoundFXChorus                := win32.GUID{0x880842e3, 0x145f, 0x43e6, {0xa9, 0x34, 0xa7, 0x18, 0x06, 0xe5, 0x05, 0x47}}
IID_IDirectSoundFXChorus8               := IID_IDirectSoundFXChorus
IID_IDirectSoundFXFlanger               := win32.GUID{0x903e9878, 0x2c92, 0x4072, {0x9b, 0x2c, 0xea, 0x68, 0xf5, 0x39, 0x67, 0x83}}
IID_IDirectSoundFXFlanger8              := IID_IDirectSoundFXFlanger
IID_IDirectSoundFXEcho                  := win32.GUID{0x8bd28edf, 0x50db, 0x4e92, {0xa2, 0xbd, 0x44, 0x54, 0x88, 0xd1, 0xed, 0x42}}
IID_IDirectSoundFXEcho8                 := IID_IDirectSoundFXEcho
IID_IDirectSoundFXDistortion            := win32.GUID{0x8ecf4326, 0x455f, 0x4d8b, {0xbd, 0xa9, 0x8d, 0x5d, 0x3e, 0x9e, 0x3e, 0x0b}}
IID_IDirectSoundFXDistortion8           := IID_IDirectSoundFXDistortion
IID_IDirectSoundFXCompressor            := win32.GUID{0x4bbd1154, 0x62f6, 0x4e2c, {0xa1, 0x5c, 0xd3, 0xb6, 0xc4, 0x17, 0xf7, 0xa0}}
IID_IDirectSoundFXCompressor8           := IID_IDirectSoundFXCompressor
IID_IDirectSoundFXParamEq               := win32.GUID{0xc03ca9fe, 0xfe90, 0x4204, {0x80, 0x78, 0x82, 0x33, 0x4c, 0xd1, 0x77, 0xda}}
IID_IDirectSoundFXParamEq8              := IID_IDirectSoundFXParamEq
IID_IDirectSoundFXWavesReverb           := win32.GUID{0x46858c3a, 0x0dc6, 0x45e3, {0xb7, 0x60, 0xd4, 0xee, 0xf1, 0x6c, 0xb3, 0x25}}
IID_IDirectSoundFXWavesReverb8          := IID_IDirectSoundFXWavesReverb
IID_IDirectSoundFXI3DL2Reverb           := win32.GUID{0x4b166a6a, 0x0d66, 0x43f3, {0x80, 0xe3, 0xee, 0x62, 0x80, 0xde, 0xe1, 0xa4}}
IID_IDirectSoundFXI3DL2Reverb8          := IID_IDirectSoundFXI3DL2Reverb
IID_IDirectSoundCaptureFXAec            := win32.GUID{0xad74143d, 0x903d, 0x4ab7, {0x80, 0x66, 0x28, 0xd3, 0x63, 0x03, 0x6d, 0x65}}
IID_IDirectSoundCaptureFXAec8           := IID_IDirectSoundCaptureFXAec
IID_IDirectSoundCaptureFXNoiseSuppress  := win32.GUID{0xed311e41, 0xfbae, 0x4175, {0x96, 0x25, 0xcd, 0x8, 0x54, 0xf6, 0x93, 0xca}}
IID_IDirectSoundCaptureFXNoiseSuppress8 := IID_IDirectSoundCaptureFXNoiseSuppress
IID_IDirectSoundFullDuplex              := win32.GUID{0xedcb4c7a, 0xdaab, 0x4216, {0xa4, 0x2e, 0x6c, 0x50, 0x59, 0x6d, 0xdc, 0x1d}}
IID_IDirectSoundFullDuplex8             := IID_IDirectSoundFullDuplex

// Components
//
// DirectSound Component GUID {47D4D946-62E8-11CF-93BC-444553540000}
CLSID_DirectSound                       := win32.GUID{0x47d4d946, 0x62e8, 0x11cf, {0x93, 0xbc, 0x44, 0x45, 0x53, 0x54, 0x0, 0x0}}
// DirectSound 8.0 Component GUID {3901CC3F-84B5-4FA4-BA35-AA8172B8A09B}
CLSID_DirectSound8                      := win32.GUID{0x3901cc3f, 0x84b5, 0x4fa4, {0xba, 0x35, 0xaa, 0x81, 0x72, 0xb8, 0xa0, 0x9b}}
// DirectSound Capture Component GUID {B0210780-89CD-11D0-AF08-00A0C925CD16}
CLSID_DirectSoundCapture                := win32.GUID{0xb0210780, 0x89cd, 0x11d0, {0xaf, 0x8, 0x0, 0xa0, 0xc9, 0x25, 0xcd, 0x16}}
// DirectSound 8.0 Capture Component GUID {E4BCAC13-7F99-4908-9A8E-74E3BF24B6E1}
CLSID_DirectSoundCapture8               := win32.GUID{0xe4bcac13, 0x7f99, 0x4908, {0x9a, 0x8e, 0x74, 0xe3, 0xbf, 0x24, 0xb6, 0xe1}}
// DirectSound Full Duplex Component GUID {FEA4300C-7959-4147-B26A-2377B9E7A91D}
CLSID_DirectSoundFullDuplex             := win32.GUID{0xfea4300c, 0x7959, 0x4147, {0xb2, 0x6a, 0x23, 0x77, 0xb9, 0xe7, 0xa9, 0x1d}}

// Defaults
//
// DirectSound default playback device GUID {DEF00000-9C6D-47ED-AAF1-4DDA8F2B5C03}
DSDEVID_DefaultPlayback                 := win32.GUID{0xdef00000, 0x9c6d, 0x47ed, {0xaa, 0xf1, 0x4d, 0xda, 0x8f, 0x2b, 0x5c, 0x03}}
// DirectSound default capture device GUID {DEF00001-9C6D-47ED-AAF1-4DDA8F2B5C03}
DSDEVID_DefaultCapture                  := win32.GUID{0xdef00001, 0x9c6d, 0x47ed, {0xaa, 0xf1, 0x4d, 0xda, 0x8f, 0x2b, 0x5c, 0x03}}
// DirectSound default device for voice playback {DEF00002-9C6D-47ED-AAF1-4DDA8F2B5C03}
DSDEVID_DefaultVoicePlayback            := win32.GUID{0xdef00002, 0x9c6d, 0x47ed, {0xaa, 0xf1, 0x4d, 0xda, 0x8f, 0x2b, 0x5c, 0x03}}
// DirectSound default device for voice capture {DEF00003-9C6D-47ED-AAF1-4DDA8F2B5C03}
DSDEVID_DefaultVoiceCapture             := win32.GUID{0xdef00003, 0x9c6d, 0x47ed, {0xaa, 0xf1, 0x4d, 0xda, 0x8f, 0x2b, 0x5c, 0x03}}

// D3D Algorithms
//
// No virtualization (Pan3D) {C241333F-1C1B-11d2-94F5-00C04FC28ACA}
DS3DALG_NO_VIRTUALIZATION               := win32.GUID{0xc241333f, 0x1c1b, 0x11d2, {0x94, 0xf5, 0x0, 0xc0, 0x4f, 0xc2, 0x8a, 0xca}}
// High-quality HRTF algorithm {C2413340-1C1B-11d2-94F5-00C04FC28ACA}
DS3DALG_HRTF_FULL                       := win32.GUID{0xc2413340, 0x1c1b, 0x11d2, {0x94, 0xf5, 0x0, 0xc0, 0x4f, 0xc2, 0x8a, 0xca}}
// Lower-quality HRTF algorithm {C2413342-1C1B-11d2-94F5-00C04FC28ACA}
DS3DALG_HRTF_LIGHT                      := win32.GUID{0xc2413342, 0x1c1b, 0x11d2, {0x94, 0xf5, 0x0, 0xc0, 0x4f, 0xc2, 0x8a, 0xca}}
// Gargle {DAFD8210-5711-4B91-9FE3-F75B7AE279BF}
GUID_DSFX_STANDARD_GARGLE               := win32.GUID{0xdafd8210, 0x5711, 0x4b91, {0x9f, 0xe3, 0xf7, 0x5b, 0x7a, 0xe2, 0x79, 0xbf}}
// Chorus {EFE6629C-81F7-4281-BD91-C9D604A95AF6}
GUID_DSFX_STANDARD_CHORUS               := win32.GUID{0xefe6629c, 0x81f7, 0x4281, {0xbd, 0x91, 0xc9, 0xd6, 0x04, 0xa9, 0x5a, 0xf6}}
// Flanger {EFCA3D92-DFD8-4672-A603-7420894BAD98}
GUID_DSFX_STANDARD_FLANGER              := win32.GUID{0xefca3d92, 0xdfd8, 0x4672, {0xa6, 0x03, 0x74, 0x20, 0x89, 0x4b, 0xad, 0x98}}
// Echo/Delay {EF3E932C-D40B-4F51-8CCF-3F98F1B29D5D}
GUID_DSFX_STANDARD_ECHO                 := win32.GUID{0xef3e932c, 0xd40b, 0x4f51, {0x8c, 0xcf, 0x3f, 0x98, 0xf1, 0xb2, 0x9d, 0x5d}}
// Distortion {EF114C90-CD1D-484E-96E5-09CFAF912A21}
GUID_DSFX_STANDARD_DISTORTION           := win32.GUID{0xef114c90, 0xcd1d, 0x484e, {0x96, 0xe5, 0x09, 0xcf, 0xaf, 0x91, 0x2a, 0x21}}
// Compressor/Limiter {EF011F79-4000-406D-87AF-BFFB3FC39D57}
GUID_DSFX_STANDARD_COMPRESSOR           := win32.GUID{0xef011f79, 0x4000, 0x406d, {0x87, 0xaf, 0xbf, 0xfb, 0x3f, 0xc3, 0x9d, 0x57}}
// Parametric Equalization {120CED89-3BF4-4173-A132-3CB406CF3231}
GUID_DSFX_STANDARD_PARAMEQ              := win32.GUID{0x120ced89, 0x3bf4, 0x4173, {0xa1, 0x32, 0x3c, 0xb4, 0x06, 0xcf, 0x32, 0x31}}
// I3DL2 Environmental Reverberation: Reverb (Listener) Effect {EF985E71-D5C7-42D4-BA4D-2D073E2E96F4}
GUID_DSFX_STANDARD_I3DL2REVERB          := win32.GUID{0xef985e71, 0xd5c7, 0x42d4, {0xba, 0x4d, 0x2d, 0x07, 0x3e, 0x2e, 0x96, 0xf4}}
// Waves Reverberation {87FC0268-9A55-4360-95AA-004A1D9DE26C}
GUID_DSFX_WAVES_REVERB                  := win32.GUID{0x87fc0268, 0x9a55, 0x4360, {0x95, 0xaa, 0x00, 0x4a, 0x1d, 0x9d, 0xe2, 0x6c}}

// Capture Effect Algorithms
//
// Acoustic Echo Canceller {BF963D80-C559-11D0-8A2B-00A0C9255AC1}
// Matches KSNODETYPE_ACOUSTIC_ECHO_CANCEL in ksmedia.h
GUID_DSCFX_CLASS_AEC                    := win32.GUID{0xBF963D80, 0xC559, 0x11D0, {0x8A, 0x2B, 0x00, 0xA0, 0xC9, 0x25, 0x5A, 0xC1}}
// Microsoft AEC {CDEBB919-379A-488a-8765-F53CFD36DE40}
GUID_DSCFX_MS_AEC                       := win32.GUID{0xcdebb919, 0x379a, 0x488a, {0x87, 0x65, 0xf5, 0x3c, 0xfd, 0x36, 0xde, 0x40}}
// System AEC {1C22C56D-9879-4f5b-A389-27996DDC2810}
GUID_DSCFX_SYSTEM_AEC                   := win32.GUID{0x1c22c56d, 0x9879, 0x4f5b, {0xa3, 0x89, 0x27, 0x99, 0x6d, 0xdc, 0x28, 0x10}}
// Noise Supression {E07F903F-62FD-4e60-8CDD-DEA7236665B5}
// Matches KSNODETYPE_NOISE_SUPPRESS in post Windows ME DDK's ksmedia.h
GUID_DSCFX_CLASS_NS                     := win32.GUID{0xe07f903f, 0x62fd, 0x4e60, {0x8c, 0xdd, 0xde, 0xa7, 0x23, 0x66, 0x65, 0xb5}}
// Microsoft Noise Suppresion {11C5C73B-66E9-4ba1-A0BA-E814C6EED92D}
GUID_DSCFX_MS_NS                        := win32.GUID{0x11c5c73b, 0x66e9, 0x4ba1, {0xa0, 0xba, 0xe8, 0x14, 0xc6, 0xee, 0xd9, 0x2d}}
// System Noise Suppresion {5AB0882E-7274-4516-877D-4EEE99BA4FD0}
GUID_DSCFX_SYSTEM_NS                    := win32.GUID{0x5ab0882e, 0x7274, 0x4516, {0x87, 0x7d, 0x4e, 0xee, 0x99, 0xba, 0x4f, 0xd0}}

///////////////////////////////////////////////
// Structs
///////////////////////////////////////////////
D3DVECTOR :: struct {
	x, y, z: c.float,
}

DS3DBUFFER :: struct {
	dwSize:             win32.DWORD,
	vPosition:          D3DVECTOR,
	vVelocity:          D3DVECTOR,
	dwInsideConeAngle:  win32.DWORD,
	dwOutsideConeAngle: win32.DWORD,
	vConeOrientation:   D3DVECTOR,
	lConeOutsideVolume: win32.LONG,
	flMinDistance:      D3DVALUE,
	flMaxDistance:      D3DVALUE,
	dwMode:             win32.DWORD,
}
LPDS3DBUFFER  :: ^DS3DBUFFER
LPCDS3DBUFFER :: ^DS3DBUFFER

DS3DLISTENER :: struct {
	dwSize:           win32.DWORD,
	vPosition:        D3DVECTOR,
	vVelocity:        D3DVECTOR,
	vOrientFront:     D3DVECTOR,
	vOrientTop:       D3DVECTOR,
	flDistanceFactor: D3DVALUE,
	flRolloffFactor:  D3DVALUE,
	flDopplerFactor:  D3DVALUE,
}
LPDS3DLISTENER  :: ^DS3DLISTENER
LPCDS3DLISTENER :: ^DS3DLISTENER

DSBCAPS :: struct {
	dwSize:               win32.DWORD,
	dwFlags:              win32.DWORD,
	dwBufferBytes:        win32.DWORD,
	dwUnlockTransferRate: win32.DWORD,
	dwPlayCpuOverhead:    win32.DWORD,
}
LPDSBCAPS  :: ^DSBCAPS
LPCDSBCAPS :: ^DSBCAPS

DSBPOSITIONNOTIFY :: struct {
	dwOffset:     win32.DWORD,
	hEventNotify: win32.HANDLE,
}
LPDSBPOSITIONNOTIFY  :: ^DSBPOSITIONNOTIFY
LPCDSBPOSITIONNOTIFY :: ^DSBPOSITIONNOTIFY

WAVEFORMATEX :: struct {
	wFormatTag:      win32.WORD,
	nChannels:       win32.WORD,
	nSamplesPerSec:  win32.DWORD,
	nAvgBytesPerSec: win32.DWORD,
	nBlockAlign:     win32.WORD,
	wBitsPerSample:  win32.WORD,
	cbSize:          win32.WORD,
}
LPWAVEFORMATEX  :: ^WAVEFORMATEX
LPCWAVEFORMATEX :: ^WAVEFORMATEX

WAVEFORMATEXTENSIBLE :: struct {
	Format:              WAVEFORMATEX,
	wValidBitsPerSample: win32.WORD,
	wSamplesPerBlock:    win32.WORD,
	wReserved:           win32.WORD,
	dwChannelMask:       win32.DWORD,
	SubFormat:           win32.DWORD,
}

DSBUFFERDESC :: struct {
	dwSize:          win32.DWORD,
	dwFlags:         win32.DWORD,
	dwBufferBytes:   win32.DWORD,
	dwReserved:      win32.DWORD,
	lpwfxFormat:     LPWAVEFORMATEX,
	guid3DAlgorithm: win32.GUID,
}
LPDSBUFFERDESC  :: ^DSBUFFERDESC
LPCDSBUFFERDESC :: ^DSBUFFERDESC

DSCAPS :: struct {
	dwSize:                         win32.DWORD,
	dwFlags:                        win32.DWORD,
	dwMinSecondarySampleRate:       win32.DWORD,
	dwMaxSecondarySampleRate:       win32.DWORD,
	dwPrimaryBuffers:               win32.DWORD,
	dwMaxHwMixingAllBuffers:        win32.DWORD,
	dwMaxHwMixingStaticBuffers:     win32.DWORD,
	dwMaxHwMixingStreamingBuffers:  win32.DWORD,
	dwFreeHwMixingAllBuffers:       win32.DWORD,
	dwFreeHwMixingStaticBuffers:    win32.DWORD,
	dwFreeHwMixingStreamingBuffers: win32.DWORD,
	dwMaxHw3DAllBuffers:            win32.DWORD,
	dwMaxHw3DStaticBuffers:         win32.DWORD,
	dwMaxHw3DStreamingBuffers:      win32.DWORD,
	dwFreeHw3DAllBuffers:           win32.DWORD,
	dwFreeHw3DStaticBuffers:        win32.DWORD,
	dwFreeHw3DStreamingBuffers:     win32.DWORD,
	dwTotalHwMemBytes:              win32.DWORD,
	dwFreeHwMemBytes:               win32.DWORD,
	dwMaxContigFreeHwMemBytes:      win32.DWORD,
	dwUnlockTransferRateHwBuffers:  win32.DWORD,
	dwPlayCpuOverheadSwBuffers:     win32.DWORD,
	dwReserved1:                    win32.DWORD,
	dwReserved2:                    win32.DWORD,
}
LPDSCAPS  :: ^DSCAPS
LPCDSCAPS :: ^DSCAPS

DSCBCAPS :: struct {
	dwSize:        win32.DWORD,
	dwFlags:       win32.DWORD,
	dwBufferBytes: win32.DWORD,
	dwReserved:    win32.DWORD,
}
LPDSCBCAPS  :: ^DSCBCAPS
LPCDSCBCAPS :: ^DSCBCAPS

DSCEFFECTDESC :: struct {
	dwSize:            win32.DWORD,
	dwFlags:           win32.DWORD,
	guidDSCFXClass:    win32.GUID,
	guidDSCFXInstance: win32.GUID,
	dwReserved1:       win32.DWORD,
	dwReserved2:       win32.DWORD,
}
LPDSCEFFECTDESC  :: ^DSCEFFECTDESC
LPCDSCEFFECTDESC :: ^DSCEFFECTDESC

DSCBUFFERDESC :: struct {
	dwSize:        win32.DWORD,
	dwFlags:       win32.DWORD,
	dwBufferBytes: win32.DWORD,
	dwReserved:    win32.DWORD,
	lpwfxFormat:   LPWAVEFORMATEX,
	dwFXCount:     win32.DWORD,
	lpDSCFXDesc:   LPDSCEFFECTDESC,
}
LPDSCBUFFERDESC  :: ^DSCBUFFERDESC
LPCDSCBUFFERDESC :: ^DSCBUFFERDESC

DSCCAPS :: struct {
	dwSize:     win32.DWORD,
	dwFlags:    win32.DWORD,
	dwFormats:  win32.DWORD,
	dwChannels: win32.DWORD,
}
LPDSCCAPS  :: ^DSCCAPS
LPCDSCCAPS :: ^DSCCAPS

DSCFXAec :: struct {
	fEnable:    win32.BOOL,
	fNoiseFill: win32.BOOL,
	dwMode:     win32.DWORD,
}
LPDSCFXAec  :: ^DSCFXAec
LPCDSCFXAec :: ^DSCFXAec

DSCFXNoiseSuppress :: struct {
	fEnable: win32.BOOL,
}
LPDSCFXNoiseSuppress  :: ^DSCFXNoiseSuppress
LPCDSCFXNoiseSuppress :: ^DSCFXNoiseSuppress

DSEFFECTDESC :: struct {
	dwSize:        win32.DWORD,
	dwFlags:       win32.DWORD,
	guidDSFXClass: win32.GUID,
	dwReserved1:   win32.DWORD_PTR,
	dwReserved2:   win32.DWORD_PTR,
}
LPDSEFFECTDESC  :: ^DSEFFECTDESC
LPCDSEFFECTDESC :: ^DSEFFECTDESC

DSFXI3DL2Reverb :: struct {
	lRoom:               win32.LONG,
	lRoomHF:             win32.LONG,
	flRoomRolloffFactor: c.float,
	flDecayTime:         c.float,
	flDecayHFRatio:      c.float,
	lReflections:        win32.LONG,
	flReflectionsDelay:  c.float,
	lReverb:             win32.LONG,
	flReverbDelay:       c.float,
	flDiffusion:         c.float,
	flDensity:           c.float,
	flHFReference:       c.float,
}
LPDSFXI3DL2Reverb  :: ^DSFXI3DL2Reverb
LPCDSFXI3DL2Reverb :: ^DSFXI3DL2Reverb

DSFXChorus :: struct {
	fWetDryMix: c.float,
	fDepth:     c.float,
	fFeedback:  c.float,
	fFrequency: c.float,
	lWaveform:  win32.LONG,
	fDelay:     c.float,
	lPhase:     win32.LONG,
}
LPDSFXChorus  :: ^DSFXChorus
LPCDSFXChorus :: ^DSFXChorus

DSFXCompressor :: struct {
	fGain:      c.float,
	fAttack:    c.float,
	fRelease:   c.float,
	fThreshold: c.float,
	fRatio:     c.float,
	fPredelay:  c.float,
}
LPDSFXCompressor  :: ^DSFXCompressor
LPCDSFXCompressor :: ^DSFXCompressor

DSFXDistortion :: struct {
	fGain:                  win32.DWORD,
	fEdge:                  win32.DWORD,
	fPostEQCenterFrequency: win32.DWORD,
	fPostEQBandwidth:       win32.DWORD,
	fPreLowpassCutoff:      win32.DWORD,
}
LPDSFXDistortion  :: ^DSFXDistortion
LPCDSFXDistortion :: ^DSFXDistortion

DSFXEcho :: struct {
	fWetDryMix:  c.float,
	fFeedback:   c.float,
	fLeftDelay:  c.float,
	fRightDelay: c.float,
	lPanDelay:   win32.LONG,
}
LPDSFXEcho  :: ^DSFXEcho
LPCDSFXEcho :: ^DSFXEcho

DSFXFlanger :: struct {
	fWetDryMix: c.float,
	fDepth:     c.float,
	fFeedback:  c.float,
	fFrequency: c.float,
	lWaveform:  win32.LONG,
	fDelay:     c.float,
	lPhase:     win32.LONG,
}
LPDSFXFlanger  :: ^DSFXFlanger
LPCDSFXFlanger :: ^DSFXFlanger

DSFXGargle :: struct {
	dwRateHz:    win32.DWORD,
	dwWaveShape: win32.DWORD,
}
LPDSFXGargle  :: ^DSFXGargle
LPCDSFXGargle :: ^DSFXGargle

DSFXParamEq :: struct {
	fCenter:    c.float,
	fBandwidth: c.float,
	fGain:      c.float,
}
LPDSFXParamEq  :: ^DSFXParamEq
LPCDSFXParamEq :: ^DSFXParamEq

DSFXWavesReverb :: struct {
	fInGain:          c.float,
	fReverbMix:       c.float,
	fReverbTime:      c.float,
	fHighFreqRTRatio: c.float,
}
LPDSFXWavesReverb  :: ^DSFXWavesReverb
LPCDSFXWavesReverb :: ^DSFXWavesReverb

///////////////////////////////////////////////
// Callbacks
///////////////////////////////////////////////
DSEnumCallbackA :: proc "std" (
	lpGuid: win32.LPGUID,
	lpcstrDescription: win32.LPCSTR,
	lpcstrModule: win32.LPCSTR,
	lpContext: win32.LPVOID,
) -> win32.BOOL
DSEnumCallbackW :: proc "std" (
	lpGuid: win32.LPGUID,
	lpcstrDescription: win32.LPCWSTR,
	lpcstrModule: win32.LPCWSTR,
	lpContext: win32.LPVOID,
) -> win32.BOOL
LPDSENUMCALLBACKA :: ^DSEnumCallbackA
LPDSENUMCALLBACKW :: ^DSEnumCallbackW

///////////////////////////////////////////////
// Interfaces
///////////////////////////////////////////////
IUnknown :: struct {
	using Vtbl: ^IUnknownVtbl,
}
IUnknownVtbl :: struct {
	QueryInterface : proc "std" (This: ^IUnknown, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef         : proc "std" (This: ^IUnknown) -> win32.ULONG,
	Release        : proc "std" (This: ^IUnknown) -> win32.ULONG,
}
LPUNKNOWN :: ^IUnknown

IDirectSound :: struct {
	using Vtbl: ^IDirectSoundVtbl,
}
IDirectSoundVtbl :: struct {
	QueryInterface       : proc "std" (This: ^IDirectSound, riid: REFIID, ppvObject: rawptr) -> win32.HRESULT,
	AddRef               : proc "std" (This: ^IDirectSound) -> win32.ULONG,
	Release              : proc "std" (This: ^IDirectSound) -> win32.ULONG,
	CreateSoundBuffer    : proc "std" (This: ^IDirectSound, pcDSBufferDesc: LPCDSBUFFERDESC,
									   ppDSBuffer: ^LPDIRECTSOUNDBUFFER, pUnkOuter: LPUNKNOWN) -> win32.HRESULT,
	GetCaps              : proc "std" (This: ^IDirectSound, pDSCaps: LPDSCAPS) -> win32.HRESULT,
	DuplicateSoundBuffer : proc "std" (This: ^IDirectSound, pDSBufferOriginal: LPDIRECTSOUNDBUFFER,
									   ppDSBufferDuplicate: ^LPDIRECTSOUNDBUFFER) -> win32.HRESULT,
	SetCooperativeLevel  : proc "std" (This: ^IDirectSound, hwnd: win32.HWND, dwLevel: win32.DWORD) -> win32.HRESULT,
	Compact              : proc "std" (This: ^IDirectSound) -> win32.HRESULT,
	GetSpeakerConfig     : proc "std" (This: ^IDirectSound, pdwSpeakerConfig: win32.LPDWORD) -> win32.HRESULT,
	SetSpeakerConfig     : proc "std" (This: ^IDirectSound, dwSpeakerConfig: win32.DWORD) -> win32.HRESULT,
	Initialize           : proc "std" (This: ^IDirectSound, pcGuidDevice: win32.LPCGUID) -> win32.HRESULT,
}
LPDIRECTSOUND  :: ^IDirectSound

IDirectSound8 :: struct {
	using Vtbl: ^IDirectSound8Vtbl,
}
IDirectSound8Vtbl :: struct {
	QueryInterface       : proc "std" (This: ^IDirectSound8, riid: REFIID, ppvObject: rawptr) -> win32.HRESULT,
	AddRef               : proc "std" (This: ^IDirectSound8) -> win32.ULONG,
	Release              : proc "std" (This: ^IDirectSound8) -> win32.ULONG,
	CreateSoundBuffer    : proc "std" (This: ^IDirectSound8, pcDSBufferDesc: LPCDSBUFFERDESC,
									   ppDSBuffer: ^LPDIRECTSOUNDBUFFER, pUnkOuter: LPUNKNOWN) -> win32.HRESULT,
	GetCaps              : proc "std" (This: ^IDirectSound8, pDSCaps: LPDSCAPS) -> win32.HRESULT,
	DuplicateSoundBuffer : proc "std" (This: ^IDirectSound8, pDSBufferOriginal: LPDIRECTSOUNDBUFFER,
									   ppDSBufferDuplicate: ^LPDIRECTSOUNDBUFFER) -> win32.HRESULT,
	SetCooperativeLevel  : proc "std" (This: ^IDirectSound8, hwnd: win32.HWND, dwLevel: win32.DWORD) -> win32.HRESULT,
	Compact              : proc "std" (This: ^IDirectSound8) -> win32.HRESULT,
	GetSpeakerConfig     : proc "std" (This: ^IDirectSound8, pdwSpeakerConfig: win32.LPDWORD) -> win32.HRESULT,
	SetSpeakerConfig     : proc "std" (This: ^IDirectSound8, dwSpeakerConfig: win32.DWORD) -> win32.HRESULT,
	Initialize           : proc "std" (This: ^IDirectSound8, pcGuidDevice: win32.LPCGUID) -> win32.HRESULT,
	VerifyCertification  : proc "std" (This: ^IDirectSound8, pdwCertified: win32.LPDWORD) -> win32.HRESULT,
}
LPDIRECTSOUND8 :: ^IDirectSound8

IDirectSound3DBuffer8 :: struct {
	using Vtbl: ^IDirectSound3DBuffer8Vtbl,
}
IDirectSound3DBuffer8Vtbl :: struct {
	QueryInterface       : proc "std" (This: ^IDirectSound3DBuffer8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef               : proc "std" (This: ^IDirectSound3DBuffer8) -> win32.ULONG,
	Release              : proc "std" (This: ^IDirectSound3DBuffer8) -> win32.ULONG,
	GetAllParameters     : proc "std" (This: ^IDirectSound3DBuffer8, pDs3dBuffer: LPDS3DBUFFER) -> win32.HRESULT,
	GetConeAngles        : proc "std" (This: ^IDirectSound3DBuffer8, pdwInsideConeAngle, pdwOutsideConeAngle: win32.LPDWORD) -> win32.HRESULT,
	GetConeOrientation   : proc "std" (This: ^IDirectSound3DBuffer8, pvOrientation: ^D3DVECTOR) -> win32.HRESULT,
	GetConeOutsideVolume : proc "std" (This: ^IDirectSound3DBuffer8, plConeOutsideVolume: LPLONG) -> win32.HRESULT,
	GetMaxDistance       : proc "std" (This: ^IDirectSound3DBuffer8, pflMaxDistance: ^D3DVALUE) -> win32.HRESULT,
	GetMinDistance       : proc "std" (This: ^IDirectSound3DBuffer8, pflMinDistance: ^D3DVALUE) -> win32.HRESULT,
	GetMode              : proc "std" (This: ^IDirectSound3DBuffer8, pdwMode: win32.LPDWORD) -> win32.HRESULT,
	GetPosition          : proc "std" (This: ^IDirectSound3DBuffer8, pflMaxDistance: ^D3DVALUE) -> win32.HRESULT,
	GetVelocity          : proc "std" (This: ^IDirectSound3DBuffer8, pvVelocity: ^D3DVECTOR) -> win32.HRESULT,
	SetAllParameters     : proc "std" (This: ^IDirectSound3DBuffer8, pcDs3dBuffer: LPCDS3DBUFFER, dwApply: win32.DWORD) -> win32.HRESULT,
	SetConeAngles        : proc "std" (This: ^IDirectSound3DBuffer8, dwInsideConeAngle, dwOutsideConeAngle, dwApply: win32.DWORD) -> win32.HRESULT,
	SetConeOrientation   : proc "std" (This: ^IDirectSound3DBuffer8, x, y, z: D3DVALUE, dwApply: win32.DWORD) -> win32.HRESULT,
	SetConeOutsideVolume : proc "std" (This: ^IDirectSound3DBuffer8, lConeOutsideVolume: win32.LONG, dwApply: win32.DWORD) -> win32.HRESULT,
	SetMaxDistance       : proc "std" (This: ^IDirectSound3DBuffer8, flMaxDistance: D3DVALUE, dwApply: win32.DWORD) -> win32.HRESULT,
	SetMinDistance       : proc "std" (This: ^IDirectSound3DBuffer8, flMinDistance: D3DVALUE, dwApply: win32.DWORD) -> win32.HRESULT,
	SetMode              : proc "std" (This: ^IDirectSound3DBuffer8, dwMode, dwApply: win32.DWORD) -> win32.HRESULT,
	SetPosition          : proc "std" (This: ^IDirectSound3DBuffer8, x, y, z: D3DVALUE, dwApply: win32.DWORD) -> win32.HRESULT,
	SetVelocity          : proc "std" (This: ^IDirectSound3DBuffer8, x, y, z: D3DVALUE, dwApply: win32.DWORD) -> win32.HRESULT,
}
IDirectSound3DBuffer   :: IDirectSound3DBuffer8
LPDIRECTSOUND3DBUFFER  :: ^IDirectSound3DBuffer
LPDIRECTSOUND3DBUFFER8 :: ^IDirectSound3DBuffer8

IDirectSound3DListener8 :: struct {
	using Vtbl: ^IDirectSound3DListener8Vtbl,
}
IDirectSound3DListener8Vtbl :: struct {
	QueryInterface         : proc "std" (This: ^IDirectSound3DListener8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef                 : proc "std" (This: ^IDirectSound3DListener8) -> win32.ULONG,
	Release                : proc "std" (This: ^IDirectSound3DListener8) -> win32.ULONG,
	GetAllParameters       : proc "std" (This: ^IDirectSound3DListener8, pListener: LPDS3DLISTENER) -> win32.HRESULT,
	GetDistanceFactor      : proc "std" (This: ^IDirectSound3DListener8, pflDistanceFactor: ^D3DVALUE) -> win32.HRESULT,
	GetDopplerFactor       : proc "std" (This: ^IDirectSound3DListener8, pflDopplerFactor: ^D3DVALUE) -> win32.HRESULT,
	GetOrientation         : proc "std" (This: ^IDirectSound3DListener8, pvOrientFront, pvOrientTop: ^D3DVECTOR) -> win32.HRESULT,
	GetPosition            : proc "std" (This: ^IDirectSound3DListener8, pvPosition: ^D3DVECTOR) -> win32.HRESULT,
	GetRolloffFactor       : proc "std" (This: ^IDirectSound3DListener8, pflRolloffFactor: ^D3DVALUE) -> win32.HRESULT,
	GetVelocity            : proc "std" (This: ^IDirectSound3DListener8, pvVelocity: ^D3DVECTOR) -> win32.HRESULT,
	SetAllParameters       : proc "std" (This: ^IDirectSound3DListener8, pListener: LPDS3DLISTENER, dwApply: win32.DWORD) -> win32.HRESULT,
	SetDistanceFactor      : proc "std" (This: ^IDirectSound3DListener8, flDistanceFactor: D3DVALUE, dwApply: win32.DWORD) -> win32.HRESULT,
	SetDopplerFactor       : proc "std" (This: ^IDirectSound3DListener8, flDopplerFactor: D3DVALUE, dwApply: win32.DWORD) -> win32.HRESULT,
	SetOrientation         : proc "std" (This: ^IDirectSound3DListener8, xFront, yFront, zFront, xTop, yTop, zTop: D3DVALUE,
										 dwApply: win32.DWORD) -> win32.HRESULT,
	SetPosition            : proc "std" (This: ^IDirectSound3DListener8, x, y, z: D3DVALUE, dwApply: win32.DWORD) -> win32.HRESULT,
	SetRolloffFactor       : proc "std" (This: ^IDirectSound3DListener8, flRolloffFactor: D3DVALUE, dwApply: win32.DWORD) -> win32.HRESULT,
	SetVelocity            : proc "std" (This: ^IDirectSound3DListener8, x, y, z: D3DVALUE, dwApply: win32.DWORD) -> win32.HRESULT,
	CommitDeferredSettings : proc "std" (This: ^IDirectSound3DListener8) -> win32.HRESULT,
}
IDirectSound3DListener   :: IDirectSound3DListener8
LPDIRECTSOUND3DLISTENER  :: ^IDirectSound3DListener
LPDIRECTSOUND3DLISTENER8 :: ^IDirectSound3DListener8

IDirectSoundBuffer :: struct {
	using Vtbl: ^IDirectSoundBufferVtbl,
}
IDirectSoundBufferVtbl :: struct {
	QueryInterface     : proc "std" (This: ^IDirectSoundBuffer, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef             : proc "std" (This: ^IDirectSoundBuffer) -> win32.ULONG,
	Release            : proc "std" (This: ^IDirectSoundBuffer) -> win32.ULONG,
	GetCaps            : proc "std" (This: ^IDirectSoundBuffer, pDSBufferCaps: LPDSBCAPS) -> win32.HRESULT,
	GetCurrentPosition : proc "std" (This: ^IDirectSoundBuffer, pdwCurrentPlayCursor, pdwCurrentWriteCursor: win32.LPDWORD) -> win32.HRESULT,
	GetFormat          : proc "std" (This: ^IDirectSoundBuffer, pwfxFormat: LPWAVEFORMATEX, dwSizeAllocated: win32.DWORD,
									 pdwSizeWritten: win32.LPDWORD) -> win32.HRESULT,
	GetVolume          : proc "std" (This: ^IDirectSoundBuffer, plVolume: LPLONG) -> win32.HRESULT,
	GetPan             : proc "std" (This: ^IDirectSoundBuffer, plPan: LPLONG) -> win32.HRESULT,
	GetFrequency       : proc "std" (This: ^IDirectSoundBuffer, pdwFrequency: win32.LPDWORD) -> win32.HRESULT,
	GetStatus          : proc "std" (This: ^IDirectSoundBuffer, pdwStatus: win32.LPDWORD) -> win32.HRESULT,
	Initialize         : proc "std" (This: ^IDirectSoundBuffer, pDirectSound: LPDIRECTSOUND, pcDSBufferDesc: LPCDSBUFFERDESC) -> win32.HRESULT,
	Lock               : proc "std" (This: ^IDirectSoundBuffer, dwOffset, dwBytes: win32.DWORD, ppvAudioPtr1: ^win32.LPVOID,
									 pdwAudioBytes1: win32.LPDWORD, ppvAudioPtr2: ^win32.LPVOID, pdwAudioBytes2: win32.LPDWORD, dwFlags: win32.DWORD) -> win32.HRESULT,
	Play               : proc "std" (This: ^IDirectSoundBuffer, dwReserved1, dwPriority, dwFlags: win32.DWORD) -> win32.HRESULT,
	SetCurrentPosition : proc "std" (This: ^IDirectSoundBuffer, dwNewPosition: win32.DWORD) -> win32.HRESULT,
	SetFormat          : proc "std" (This: ^IDirectSoundBuffer, pcfxFormat: LPCWAVEFORMATEX) -> win32.HRESULT,
	SetVolume          : proc "std" (This: ^IDirectSoundBuffer, lVolume: win32.LONG) -> win32.HRESULT,
	SetPan             : proc "std" (This: ^IDirectSoundBuffer, lPan: win32.LONG) -> win32.HRESULT,
	SetFrequency       : proc "std" (This: ^IDirectSoundBuffer, dwFrequency: win32.DWORD) -> win32.HRESULT,
	Stop               : proc "std" (This: ^IDirectSoundBuffer) -> win32.HRESULT,
	Unlock             : proc "std" (This: ^IDirectSoundBuffer, pvAudioPtr1: win32.LPVOID, dwAudioBytes1: win32.DWORD,
									 pvAudioPtr2: win32.LPVOID, dwAudioBytes2: win32.DWORD) -> win32.HRESULT,
	Restore            : proc "std" (This: ^IDirectSoundBuffer) -> win32.HRESULT,
}
LPDIRECTSOUNDBUFFER    :: ^IDirectSoundBuffer
LPLPDIRECTSOUNDBUFFER  :: ^LPDIRECTSOUNDBUFFER

IDirectSoundBuffer8 :: struct {
	using Vtbl: ^IDirectSoundBuffer8Vtbl,
}
IDirectSoundBuffer8Vtbl :: struct {
	QueryInterface     : proc "std" (This: ^IDirectSoundBuffer8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef             : proc "std" (This: ^IDirectSoundBuffer8) -> win32.ULONG,
	Release            : proc "std" (This: ^IDirectSoundBuffer8) -> win32.ULONG,
	GetCaps            : proc "std" (This: ^IDirectSoundBuffer8, pDSBufferCaps: LPDSBCAPS) -> win32.HRESULT,
	GetCurrentPosition : proc "std" (This: ^IDirectSoundBuffer8, pdwCurrentPlayCursor, pdwCurrentWriteCursor: win32.LPDWORD) -> win32.HRESULT,
	GetFormat          : proc "std" (This: ^IDirectSoundBuffer8, pwfxFormat: LPWAVEFORMATEX, dwSizeAllocated: win32.DWORD,
									 pdwSizeWritten: win32.LPDWORD) -> win32.HRESULT,
	GetVolume          : proc "std" (This: ^IDirectSoundBuffer8, plVolume: LPLONG) -> win32.HRESULT,
	GetPan             : proc "std" (This: ^IDirectSoundBuffer8, plPan: LPLONG) -> win32.HRESULT,
	GetFrequency       : proc "std" (This: ^IDirectSoundBuffer8, pdwFrequency: win32.LPDWORD) -> win32.HRESULT,
	GetStatus          : proc "std" (This: ^IDirectSoundBuffer8, pdwStatus: win32.LPDWORD) -> win32.HRESULT,
	Initialize         : proc "std" (This: ^IDirectSoundBuffer8, pDirectSound: LPDIRECTSOUND, pcDSBufferDesc: LPCDSBUFFERDESC) -> win32.HRESULT,
	Lock               : proc "std" (This: ^IDirectSoundBuffer8, dwOffset, dwBytes: win32.DWORD, ppvAudioPtr1: ^win32.LPVOID,
									 pdwAudioBytes1: win32.LPDWORD, ppvAudioPtr2: ^win32.LPVOID, pdwAudioBytes2: win32.LPDWORD, dwFlags: win32.DWORD) -> win32.HRESULT,
	Play               : proc "std" (This: ^IDirectSoundBuffer8, dwReserved1, dwPriority, dwFlags: win32.DWORD) -> win32.HRESULT,
	SetCurrentPosition : proc "std" (This: ^IDirectSoundBuffer8, dwNewPosition: win32.DWORD) -> win32.HRESULT,
	SetFormat          : proc "std" (This: ^IDirectSoundBuffer8, pcfxFormat: LPCWAVEFORMATEX) -> win32.HRESULT,
	SetVolume          : proc "std" (This: ^IDirectSoundBuffer8, lVolume: win32.LONG) -> win32.HRESULT,
	SetPan             : proc "std" (This: ^IDirectSoundBuffer8, lPan: win32.LONG) -> win32.HRESULT,
	SetFrequency       : proc "std" (This: ^IDirectSoundBuffer8, dwFrequency: win32.DWORD) -> win32.HRESULT,
	Stop               : proc "std" (This: ^IDirectSoundBuffer8) -> win32.HRESULT,
	Unlock             : proc "std" (This: ^IDirectSoundBuffer8, pvAudioPtr1: win32.LPVOID, dwAudioBytes1: win32.DWORD,
									 pvAudioPtr2: win32.LPVOID, dwAudioBytes2: win32.DWORD) -> win32.HRESULT,
	Restore            : proc "std" (This: ^IDirectSoundBuffer8) -> win32.HRESULT,
	SetFX              : proc "std" (This: ^IDirectSoundBuffer8, dwEffectsCount: win32.DWORD, pDSFXDesc: LPDSEFFECTDESC,
									 pdwResultCodes: win32.LPDWORD) -> win32.HRESULT,
	AcquireResources   : proc "std" (This: ^IDirectSoundBuffer8, dwFlags: win32.DWORD, dwEffectsCount: win32.DWORD, pdwResultCodes: win32.LPDWORD) -> win32.HRESULT,
	GetObjectInPath    : proc "std" (This: ^IDirectSoundBuffer8, rguidObject: REFGUID, dwIndex: win32.DWORD,
									 rguidInterface: REFGUID, ppObject: ^win32.LPVOID) -> win32.HRESULT,
}
LPDIRECTSOUNDBUFFER8   :: ^IDirectSoundBuffer8
LPLPDIRECTSOUNDBUFFER8 :: ^LPDIRECTSOUNDBUFFER8

IDirectSoundCapture8 :: struct {
	using Vtbl: ^IDirectSoundCapture8Vtbl,
}
IDirectSoundCapture8Vtbl :: struct {
	QueryInterface      : proc "std" (This: ^IDirectSoundCapture8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef              : proc "std" (This: ^IDirectSoundCapture8) -> win32.ULONG,
	Release             : proc "std" (This: ^IDirectSoundCapture8) -> win32.ULONG,
	CreateCaptureBuffer : proc "std" (This: ^IDirectSoundCapture8, pcDSCBufferDesc: LPCDSCBUFFERDESC, ppDSCBuffer: ^LPDIRECTSOUNDCAPTUREBUFFER,
									  pUnkOuter: LPUNKNOWN) -> win32.HRESULT,
	GetCaps             : proc "std" (This: ^IDirectSoundCapture8, pDSCCaps: LPDSCCAPS) -> win32.HRESULT,
	Initialize          : proc "std" (This: ^IDirectSoundCapture8, pcGuidDevice: win32.LPCGUID) -> win32.HRESULT,

}
IDirectSoundCapture   :: IDirectSoundBuffer8
LPDIRECTSOUNDCAPTURE  :: ^IDirectSoundBuffer
LPDIRECTSOUNDCAPTURE8 :: ^IDirectSoundBuffer8

IDirectSoundCaptureBuffer8 :: struct {
	using Vtbl: ^IDirectSoundCaptureBuffer8Vtbl,
}
IDirectSoundCaptureBuffer8Vtbl :: struct {
	QueryInterface     : proc "std" (This: ^IDirectSoundCaptureBuffer8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef             : proc "std" (This: ^IDirectSoundCaptureBuffer8) -> win32.ULONG,
	Release            : proc "std" (This: ^IDirectSoundCaptureBuffer8) -> win32.ULONG,
	GetCaps            : proc "std" (This: ^IDirectSoundCaptureBuffer8, pDSCBCaps: LPDSCBCAPS) -> win32.HRESULT,
	GetCurrentPosition : proc "std" (This: ^IDirectSoundCaptureBuffer8, pdwCapturePosition, pdwReadPosition: win32.LPDWORD) -> win32.HRESULT,
	GetFormat          : proc "std" (This: ^IDirectSoundCaptureBuffer8, pwfxFormat: LPWAVEFORMATEX, dwSizeAllocated: win32.DWORD,
									 pdwSizeWritten: win32.LPDWORD) -> win32.HRESULT,
	GetStatus          : proc "std" (This: ^IDirectSoundCaptureBuffer8, pdwStatus: win32.LPDWORD) -> win32.HRESULT,
	Initialize         : proc "std" (This: ^IDirectSoundCaptureBuffer8, pDirectSoundCapture: LPDIRECTSOUNDCAPTURE,
									 pcDSCBufferDesc: LPCDSCBUFFERDESC) -> win32.HRESULT,
	Lock               : proc "std" (This: ^IDirectSoundCaptureBuffer8, dwOffset, dwBytes: win32.DWORD, ppvAudioPtr1: ^win32.LPVOID,
									 pdwAudioBytes1: win32.LPDWORD, ppvAudioPtr2: ^win32.LPVOID, pdwAudioBytes2: win32.LPDWORD, dwFlags: win32.DWORD) -> win32.HRESULT,
	Start              : proc "std" (This: ^IDirectSoundCaptureBuffer8, dwFlags: win32.DWORD) -> win32.HRESULT,
	Stop               : proc "std" (This: ^IDirectSoundCaptureBuffer8) -> win32.HRESULT,
	Unlock             : proc "std" (This: ^IDirectSoundCaptureBuffer8, pvAudioPtr1: win32.LPVOID, dwAudioBytes1: win32.DWORD,
									 pvAudioPtr2: win32.LPVOID, dwAudioBytes2: win32.DWORD) -> win32.HRESULT,
	GetObjectInPath    : proc "std" (This: ^IDirectSoundCaptureBuffer8, rguidObject: REFGUID, dwIndex: win32.DWORD, rguidInterface: REFGUID,
									 ppObject: ^win32.LPVOID) -> win32.HRESULT,
	GetFXStatus        : proc "std" (This: ^IDirectSoundCaptureBuffer8, dwFXCount: win32.DWORD, pdwFXStatus: win32.LPDWORD) -> win32.HRESULT,
}
IDirectSoundCaptureBuffer     :: IDirectSoundCaptureBuffer8
LPDIRECTSOUNDCAPTUREBUFFER    :: ^IDirectSoundCaptureBuffer
LPDIRECTSOUNDCAPTUREBUFFER8   :: ^IDirectSoundCaptureBuffer8
LPLPDIRECTSOUNDCAPTUREBUFFER  :: ^LPDIRECTSOUNDCAPTUREBUFFER
LPLPDIRECTSOUNDCAPTUREBUFFER8 :: ^LPDIRECTSOUNDCAPTUREBUFFER8

IDirectSoundCaptureFXAec8 :: struct {
	using Vtbl: ^IDirectSoundCaptureFXAec8Vtbl,
}
IDirectSoundCaptureFXAec8Vtbl :: struct {
	QueryInterface   : proc "std" (This: ^IDirectSoundCaptureFXAec8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef           : proc "std" (This: ^IDirectSoundCaptureFXAec8) -> win32.ULONG,
	Release          : proc "std" (This: ^IDirectSoundCaptureFXAec8) -> win32.ULONG,
	SetAllParameters : proc "std" (This: ^IDirectSoundCaptureFXAec8, pcDscFxAec: LPCDSCFXAec) -> win32.HRESULT,
	GetAllParameters : proc "std" (This: ^IDirectSoundCaptureFXAec8, pDscFxAec: LPDSCFXAec) -> win32.HRESULT,
	GetStatus        : proc "std" (This: ^IDirectSoundCaptureFXAec8, pdwStatus: win32.PDWORD) -> win32.HRESULT,
	Reset            : proc "std" (This: ^IDirectSoundCaptureFXAec8) -> win32.HRESULT,
}
IDirectSoundCaptureFXAec   :: IDirectSoundCaptureFXAec8
LPDIRECTSOUNDCAPTUREFXAEC  :: ^IDirectSoundCaptureFXAec
LPDIRECTSOUNDCAPTUREFXAEC8 :: ^IDirectSoundCaptureFXAec8

IDirectSoundCaptureFXNoiseSuppress8 :: struct {
	using Vtbl: ^IDirectSoundCaptureFXNoiseSuppress8Vtbl,
}
IDirectSoundCaptureFXNoiseSuppress8Vtbl :: struct {
	QueryInterface   : proc "std" (This: ^IDirectSoundCaptureFXNoiseSuppress8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef           : proc "std" (This: ^IDirectSoundCaptureFXNoiseSuppress8) -> win32.ULONG,
	Release          : proc "std" (This: ^IDirectSoundCaptureFXNoiseSuppress8) -> win32.ULONG,
	SetAllParameters : proc "std" (This: ^IDirectSoundCaptureFXNoiseSuppress8, pcDscFxNoiseSuppress: LPDSCFXNoiseSuppress) -> win32.HRESULT,
	GetAllParameters : proc "std" (This: ^IDirectSoundCaptureFXNoiseSuppress8, pDscFxNoiseSuppress: LPDSCFXNoiseSuppress) -> win32.HRESULT,
	Reset            : proc "std" (This: ^IDirectSoundCaptureFXNoiseSuppress8) -> win32.HRESULT,
}
IDirectSoundCaptureFXNoiseSuppress   :: IDirectSoundCaptureFXNoiseSuppress8
LPDIRECTSOUNDCAPTUREFXNOISESUPPRESS  :: ^IDirectSoundCaptureFXNoiseSuppress
LPDIRECTSOUNDCAPTUREFXNOISESUPPRESS8 :: ^IDirectSoundCaptureFXNoiseSuppress8

IDirectSoundFullDuplex8 :: struct {
	using Vtbl: ^IDirectSoundFullDuplex8Vtbl,
}
IDirectSoundFullDuplex8Vtbl :: struct {
	QueryInterface : proc "std" (This: ^IDirectSoundFullDuplex8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef         : proc "std" (This: ^IDirectSoundFullDuplex8) -> win32.ULONG,
	Release        : proc "std" (This: ^IDirectSoundFullDuplex8) -> win32.ULONG,
	Initialize     : proc "std" (This: ^IDirectSoundFullDuplex8, pCaptureGuid, pRenderGuid: win32.LPCGUID, lpDscBufferDesc: LPCDSCBUFFERDESC,
								 lpDsBufferDesc: LPCDSBUFFERDESC, hWnd: win32.HWND, dwLevel: win32.DWORD,
								 lplpDirectSoundCaptureBuffer8: LPLPDIRECTSOUNDCAPTUREBUFFER8, lplpDirectSoundBuffer8: LPLPDIRECTSOUNDBUFFER8) -> win32.HRESULT,
}
IDirectSoundFullDuplex   :: IDirectSoundFullDuplex8
LPDIRECTSOUNDFULLDUPLEX  :: ^IDirectSoundFullDuplex
LPDIRECTSOUNDFULLDUPLEX8 :: ^IDirectSoundFullDuplex8

IDirectSoundFXChorus8 :: struct {
	using Vtbl: ^IDirectSoundFXChorus8Vtbl,
}
IDirectSoundFXChorus8Vtbl :: struct {
	QueryInterface   : proc "std" (This: ^IDirectSoundFXChorus8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef           : proc "std" (This: ^IDirectSoundFXChorus8) -> win32.ULONG,
	Release          : proc "std" (This: ^IDirectSoundFXChorus8) -> win32.ULONG,
	SetAllParameters : proc "std" (This: ^IDirectSoundFXChorus8, pcDsFxChorus: LPCDSFXChorus) -> win32.HRESULT,
	GetAllParameters : proc "std" (This: ^IDirectSoundFXChorus8, pDsFxChorus: LPDSFXChorus) -> win32.HRESULT,
}
IDirectSoundFXChorus   :: IDirectSoundFXChorus8
LPDIRECTSOUNDFXCHORUS  :: ^IDirectSoundFXChorus
LPDIRECTSOUNDFXCHORUS8 :: ^IDirectSoundFXChorus8

IDirectSoundFXCompressor8 :: struct {
	using Vtbl: ^IDirectSoundFXCompressor8Vtbl,
}
IDirectSoundFXCompressor8Vtbl :: struct {
	QueryInterface   : proc "std" (This: ^IDirectSoundFXCompressor8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef           : proc "std" (This: ^IDirectSoundFXCompressor8) -> win32.ULONG,
	Release          : proc "std" (This: ^IDirectSoundFXCompressor8) -> win32.ULONG,
	SetAllParameters : proc "std" (This: ^IDirectSoundFXCompressor8, pcDsFxCompressor: LPCDSFXCompressor) -> win32.HRESULT,
	GetAllParameters : proc "std" (This: ^IDirectSoundFXCompressor8, pDsFxCompressor: LPDSFXCompressor) -> win32.HRESULT,
}
IDirectSoundFXCompressor   :: IDirectSoundFXCompressor8
LPDIRECTSOUNDFXCOMPRESSOR  :: ^IDirectSoundFXCompressor
LPDIRECTSOUNDFXCOMPRESSOR8 :: ^IDirectSoundFXCompressor8

IDirectSoundFXDistortion8 :: struct {
	using Vtbl: ^IDirectSoundFXDistortion8Vtbl,
}
IDirectSoundFXDistortion8Vtbl :: struct {
	QueryInterface   : proc "std" (This: ^IDirectSoundFXDistortion8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef           : proc "std" (This: ^IDirectSoundFXDistortion8) -> win32.ULONG,
	Release          : proc "std" (This: ^IDirectSoundFXDistortion8) -> win32.ULONG,
	SetAllParameters : proc "std" (This: ^IDirectSoundFXDistortion8, pcDsFxDistortion: LPCDSFXDistortion) -> win32.HRESULT,
	GetAllParameters : proc "std" (This: ^IDirectSoundFXDistortion8, pDsFxDistortion: LPDSFXDistortion) -> win32.HRESULT,
}
IDirectSoundFXDistortion   :: IDirectSoundFXDistortion8
LPDIRECTSOUNDFXDISTORTION  :: ^IDirectSoundFXDistortion
LPDIRECTSOUNDFXDISTORTION8 :: ^IDirectSoundFXDistortion8

IDirectSoundFXEcho8 :: struct {
	using Vtbl: ^IDirectSoundFXEcho8Vtbl,
}
IDirectSoundFXEcho8Vtbl :: struct {
	QueryInterface   : proc "std" (This: ^IDirectSoundFXEcho8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef           : proc "std" (This: ^IDirectSoundFXEcho8) -> win32.ULONG,
	Release          : proc "std" (This: ^IDirectSoundFXEcho8) -> win32.ULONG,
	SetAllParameters : proc "std" (This: ^IDirectSoundFXEcho8, pcDsFxEcho: LPCDSFXEcho) -> win32.HRESULT,
	GetAllParameters : proc "std" (This: ^IDirectSoundFXEcho8, pDsFxEcho: LPDSFXEcho) -> win32.HRESULT,
}
IDirectSoundFXEcho   :: IDirectSoundFXEcho8
LPDIRECTSOUNDFXECHO  :: ^IDirectSoundFXEcho
LPDIRECTSOUNDFXECHO8 :: ^IDirectSoundFXEcho8

IDirectSoundFXFlanger8 :: struct {
	using Vtbl: ^IDirectSoundFXFlanger8Vtbl,
}
IDirectSoundFXFlanger8Vtbl :: struct {
	QueryInterface   : proc "std" (This: ^IDirectSoundFXFlanger8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef           : proc "std" (This: ^IDirectSoundFXFlanger8) -> win32.ULONG,
	Release          : proc "std" (This: ^IDirectSoundFXFlanger8) -> win32.ULONG,
	SetAllParameters : proc "std" (This: ^IDirectSoundFXFlanger8, pcDsFxFlanger: LPCDSFXFlanger) -> win32.HRESULT,
	GetAllParameters : proc "std" (This: ^IDirectSoundFXFlanger8, pDsFxFlanger: LPDSFXFlanger) -> win32.HRESULT,
}
IDirectSoundFXFlanger   :: IDirectSoundFXFlanger8
LPDIRECTSOUNDFXFLANGER  :: ^IDirectSoundFXFlanger
LPDIRECTSOUNDFXFLANGER8 :: ^IDirectSoundFXFlanger8

IDirectSoundFXGargle8 :: struct {
	using Vtbl: ^IDirectSoundFXGargle8Vtbl,
}
IDirectSoundFXGargle8Vtbl :: struct {
	QueryInterface   : proc "std" (This: ^IDirectSoundFXGargle8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef           : proc "std" (This: ^IDirectSoundFXGargle8) -> win32.ULONG,
	Release          : proc "std" (This: ^IDirectSoundFXGargle8) -> win32.ULONG,
	SetAllParameters : proc "std" (This: ^IDirectSoundFXGargle8, pcDsFxGargle: LPCDSFXGargle) -> win32.HRESULT,
	GetAllParameters : proc "std" (This: ^IDirectSoundFXGargle8, pDsFxGargle: LPDSFXGargle) -> win32.HRESULT,
}
IDirectSoundFXGargle   :: IDirectSoundFXGargle8
LPDIRECTSOUNDFXGARGLE  :: ^IDirectSoundFXGargle
LPDIRECTSOUNDFXGARGLE8 :: ^IDirectSoundFXGargle8

IDirectSoundFXI3DL2Reverb8 :: struct {
	using Vtbl: ^IDirectSoundFXI3DL2Reverb8Vtbl,
}
IDirectSoundFXI3DL2Reverb8Vtbl :: struct {
	QueryInterface   : proc "std" (This: ^IDirectSoundFXI3DL2Reverb8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef           : proc "std" (This: ^IDirectSoundFXI3DL2Reverb8) -> win32.ULONG,
	Release          : proc "std" (This: ^IDirectSoundFXI3DL2Reverb8) -> win32.ULONG,
	SetAllParameters : proc "std" (This: ^IDirectSoundFXI3DL2Reverb8, pcDsFxI3DL2Reverb: LPCDSFXI3DL2Reverb) -> win32.HRESULT,
	GetAllParameters : proc "std" (This: ^IDirectSoundFXI3DL2Reverb8, pDsFxI3DL2Reverb: LPDSFXI3DL2Reverb) -> win32.HRESULT,
	SetPreset        : proc "std" (This: ^IDirectSoundFXI3DL2Reverb8, dwPreset: win32.DWORD) -> win32.HRESULT,
	GetPreset        : proc "std" (This: ^IDirectSoundFXI3DL2Reverb8, pdwPreset: win32.LPDWORD) -> win32.HRESULT,
	SetQuality       : proc "std" (This: ^IDirectSoundFXI3DL2Reverb8, lQuality: win32.LONG) -> win32.HRESULT,
	GetQuality       : proc "std" (This: ^IDirectSoundFXI3DL2Reverb8, plQuality: ^win32.LONG) -> win32.HRESULT,
}
IDirectSoundFXI3DL2Reverb   :: IDirectSoundFXI3DL2Reverb8
LPDIRECTSOUNDFXI3DL2REVERB  :: ^IDirectSoundFXI3DL2Reverb
LPDIRECTSOUNDFXI3DL2REVERB8 :: ^IDirectSoundFXI3DL2Reverb8

IDirectSoundFXParamEq8 :: struct {
	using Vtbl: ^IDirectSoundFXParamEq8Vtbl,
}
IDirectSoundFXParamEq8Vtbl :: struct {
	QueryInterface   : proc "std" (This: ^IDirectSound3DBuffer8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef           : proc "std" (This: ^IDirectSound3DBuffer8) -> win32.ULONG,
	Release          : proc "std" (This: ^IDirectSound3DBuffer8) -> win32.ULONG,
	SetAllParameters : proc "std" (This: ^IDirectSoundFXParamEq8, pcDsFxParamEq: LPCDSFXParamEq) -> win32.HRESULT,
	GetAllParameters : proc "std" (This: ^IDirectSoundFXParamEq8, pDsFxParamEq: LPDSFXParamEq) -> win32.HRESULT,
}
IDirectSoundFXParamEq   :: IDirectSoundFXParamEq8
LPDIRECTSOUNDFXPARAMEQ  :: ^IDirectSoundFXParamEq
LPDIRECTSOUNDFXPARAMEQ8 :: ^IDirectSoundFXParamEq8

IDirectSoundFXWavesReverb8 :: struct {
	using Vtbl: ^IDirectSoundFXWavesReverb8Vtbl,
}
IDirectSoundFXWavesReverb8Vtbl :: struct {
	QueryInterface   : proc "std" (This: ^IDirectSoundFXWavesReverb8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef           : proc "std" (This: ^IDirectSoundFXWavesReverb8) -> win32.ULONG,
	Release          : proc "std" (This: ^IDirectSoundFXWavesReverb8) -> win32.ULONG,
	SetAllParameters : proc "std" (This: ^IDirectSoundFXWavesReverb8, pcDsFXWavesReverb: LPCDSFXWavesReverb) -> win32.HRESULT,
	GetAllParameters : proc "std" (This: ^IDirectSoundFXWavesReverb8, pDsFXWavesReverb: LPDSFXWavesReverb) -> win32.HRESULT,
}
IDirectSoundFXWavesReverb   :: IDirectSoundFXWavesReverb8
LPDIRECTSOUNDFXWAVESREVERB  :: ^IDirectSoundFXWavesReverb
LPDIRECTSOUNDFXWAVESREVERB8 :: ^IDirectSoundFXWavesReverb8

IDirectSoundNotify8 :: struct {
	using Vtbl: ^IDirectSoundNotify8Vtbl,
}
IDirectSoundNotify8Vtbl :: struct {
	QueryInterface           : proc "std" (This: ^IDirectSoundNotify8, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef                   : proc "std" (This: ^IDirectSoundNotify8) -> win32.ULONG,
	Release                  : proc "std" (This: ^IDirectSoundNotify8) -> win32.ULONG,
	SetNotificationPositions : proc "std" (This: ^IDirectSoundNotify8, dwPositionNotifies: win32.DWORD,
										   pcPositionNotifies: LPCDSBPOSITIONNOTIFY) -> win32.HRESULT,
}
IDirectSoundNotify   :: IDirectSoundNotify8
LPDIRECTSOUNDNOTIFY  :: ^IDirectSoundNotify
LPDIRECTSOUNDNOTIFY8 :: ^IDirectSoundNotify8

IKsPropertySet :: struct {
	using Vtbl: ^IKsPropertySetVtbl,
}
IKsPropertySetVtbl :: struct {
	QueryInterface : proc "std" (This: ^IKsPropertySet, riid: REFIID, ppvObject: ^rawptr) -> win32.HRESULT,
	AddRef         : proc "std" (This: ^IKsPropertySet) -> win32.ULONG,
	Release        : proc "std" (This: ^IKsPropertySet) -> win32.ULONG,
	Get            : proc "std" (This: ^IKsPropertySet, rguidPropSet: REFGUID, ulId: win32.ULONG, pInstanceData: win32.LPVOID,
								 ulInstanceLength: win32.ULONG, pPropertyData: win32.LPVOID, ulDataLength: win32.ULONG, pulBytesReturned: win32.PULONG) -> win32.HRESULT,
	Set            : proc "std" (This: ^IKsPropertySet, rguidPropSet: REFGUID, ulId: win32.ULONG, pInstanceData: win32.LPVOID,
								 ulInstanceLength: win32.ULONG, pPropertyData: win32.LPVOID, ulDataLength: win32.ULONG) -> win32.HRESULT,
	QuerySupport   : proc "std" (This: ^IKsPropertySet, rguidPropSet: REFGUID, ulId: win32.ULONG, pulTypeSupport: win32.PULONG) -> win32.HRESULT,
}

DSC :: proc(lpcGuidDevice: win32.LPCGUID, ppDS: ^LPDIRECTSOUND, pUnkOuter: LPUNKNOWN) -> win32.HRESULT
