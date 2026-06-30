#!/bin/bash
# Trims silence from start and end of all bgm*.mp3 files in assets/audio/
# Requires ffmpeg: brew install ffmpeg

AUDIO_DIR="$(dirname "$0")/../assets/audio"

for file in "$AUDIO_DIR"/bgm*.mp3; do
  if [ ! -f "$file" ]; then
    continue
  fi

  filename=$(basename "$file")
  trimmed="$AUDIO_DIR/trimmed_$filename"

  echo "Trimming: $filename"
  ffmpeg -y -i "$file" \
    -af "silenceremove=start_periods=1:start_silence=0.01:start_threshold=-50dB,areverse,silenceremove=start_periods=1:start_silence=0.01:start_threshold=-50dB,areverse" \
    "$trimmed" 2>/dev/null

  if [ $? -eq 0 ]; then
    mv "$trimmed" "$file"
    echo "  Done: $filename"
  else
    rm -f "$trimmed"
    echo "  Failed: $filename"
  fi
done

echo "All bgm files trimmed."
