# FFmpeg Configuration for AWS Lambda

This configuration creates a minimal, optimized FFmpeg binary specifically tailored for audio processing in AWS Lambda environments. The build is focused on producing a small binary size (around 3.6MB) while maintaining essential audio processing capabilities.

## Key Features

- **Base Image**: Amazon Linux 2023 for Lambda (`al2023-arm64` and `al2023-x86_64`)
- **Minimal Size**: Optimized to be as small as possible while maintaining essential functionality
- **Audio-Focused**: Configured primarily for audio processing tasks

## Included Libraries

- **libfdk_aac**: High-quality AAC audio encoder/decoder
- **libmp3lame**: MP3 audio encoder/decoder
- **libopus**: Opus audio codec for excellent compression

## Enabled Functionality

### Filters

- `aresample`: Audio resampling
- `atempo`: Audio tempo/speed adjustment
- `format`: Format conversion
- `silencedetect`: Silence detection in audio streams
- `volume`: Volume adjustment

### Muxers (Output Formats)

- MP3
- AAC
- WAV

### Encoders

- libmp3lame (MP3)
- libfdk_aac (AAC)
- aac (native AAC)

### Protocols

- file (local file access only)

### Demuxers (Input Formats)

- AAC
- MP3
- MOV
- MP4
- Matroska
- WAV

### Decoders

- AAC
- MP3
- Opus
- FLAC
- PCM formats
- Vorbis
- WavPack

### Bitstream Filters

- aac_adtstoasc: AAC ADTS to ASC conversion
- extract_extradata: Extract extradata from stream

## Disabled Features

To minimize binary size, the following components are disabled:

- Debug information
- Documentation
- FFplay
- Network protocols
- Hardware acceleration
- Most filters
- Most muxers/demuxers
- Most encoders/decoders
- Input/output devices

## Use Cases

This FFmpeg build is ideal for AWS Lambda functions that need to:

- Convert between audio formats (MP3, AAC, WAV)
- Adjust audio volume or speed
- Detect silence in audio files
- Extract audio from video files
- Process basic audio transformations

## License Notice

This build includes components under GPL and other licenses. The FDK-AAC codec is covered by a non-free license. Please review the [FFmpeg License](https://ffmpeg.org/legal.html) for details about licensing requirements if you distribute this binary.
