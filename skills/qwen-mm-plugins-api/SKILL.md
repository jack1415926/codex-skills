---
name: qwen-mm-plugins-api
description: Cloud MCP tools for understanding media, by model family. VL model: vision_chat (caption/VQA), ocr, grounding. Omni model (video frames + audio together): omni_asr / omni_asr_timestamped / omni_multi_speaker_asr, omni_av_caption / omni_av_grounding / omni_av_counting, omni_music_caption. Others: transcribe_audio (Qwen3-ASR), segmentation (needs a SAM3 server via SAM3_SERVER_URL). Use when a question about an image/video/audio needs an external model.
---

# Qwen-MM-Plugins API

These MCP tools call external models, grouped by family.
Check the `qwen-mm-plugins-api` tools in your tool list for full schemas and parameters.

## When to Use Which Tool

### VL model (images, video frames — no audio)
- `vision_chat` — VLM Q&A, captioning, free-form prompts on one or more images/video frames.
- `ocr` — Extract text from an image.
- `grounding` — Detect/locate objects in an image (bounding boxes, spatial WHERE).

### Omni model (short clips up to a few minutes — reads video frames AND audio together)
- `omni_asr` — Plain transcription, one continuous string, no timestamps.
- `omni_asr_timestamped` — Transcription at word/sentence granularity, also returns SRT.
- `omni_multi_speaker_asr` — Diarization: speaker labels + timestamps + SRT.
- `omni_av_caption` — Splits into spans, one description + start/end per span.
- `omni_av_grounding` — Temporal grounding: locate spans via natural-language query.
- `omni_av_counting` — Count events/objects/actions: total + per-occurrence timestamps.
- `omni_music_caption` — Music analysis: genre, moods, instruments, key, time signature, vocal profile, dense English caption. Audio-only, no timestamps.

### Other services
- `segmentation` — Segment objects in an image (masks). Needs SAM3_SERVER_URL.
- `transcribe_audio` — Fast, long-file friendly ASR from audio or video. Qwen3-ASR.

## Tips

- **Vision chat**: accepts `images`/`videos` + `text`, default model `qwen3.7-plus`, supports `dry_run=true`.
- **Grounding**: returns normalized boxes (0–1000). Set `return_img=true` for annotated results. Needs `DASHSCOPE_API_KEY`.
- **ASR**: `transcribe_audio` works with audio or video, auto-chunks long files. Output: `srt` (default), `text`, `json`. Needs `DASHSCOPE_API_KEY` and ffmpeg for pulling audio from video.
- **Segmentation**: requires `SAM3_SERVER_URL`.
- **Omni tools**: every tool accepts local `file_path` or URL, supports `dry_run=true`. AV tools take `fps` and `max_pixels` to trade temporal/spatial detail against token cost. Default model `qwen3.5-omni-plus`. Timestamps are seconds from start. Accepts `language` hint.
- **Video delivery**: local video uploaded and server-side sampled when OSS configured; otherwise sampled inline.

## Choosing between the families (do NOT overlap)

1. `transcribe_audio` vs `omni_asr*`: former is dedicated Qwen3-ASR, fast, chunks long files, 27 languages — cheapest for straight long transcription. Choose Omni ASR for diarization, granularity control, or transcription fused with visual context.
2. Spatial `grounding` vs temporal `omni_av_grounding`: different axes — bounding box in a single image vs locates a span in time. Don't substitute.
3. `vision_chat` vs Omni AV tools: VL is general VLM over video frames (no audio); Omni fuses frames with audio track and returns structured, timestamped output. Use Omni when audio or timing matters.

## Relationship to Other Capabilities (do NOT overlap)

- Local file reading/visualization (images, video frames, PDF, Office, 3D) → `qwen-mm-plugins-core` tools
- Confirm a fact or identify an entity → `qwen-mm-plugins-search` tools
- Long videos (30 min+) → use `qwen-mm-plugins-video-memory` skill instead of feeding whole files to per-call tools
