#!/bin/bash
# Normalizes all bgm*.mp3 files to the same perceived loudness level.
# Uses ffmpeg's loudnorm filter (EBU R128 standard).
# Requires ffmpeg: brew install ffmpeg

AUDIO_DIR="$(dirname "$0")/../assets/audio"
TARGET_LUFS="-16" # Target loudness in LUFS

for file in "$AUDIO_DIR"/bgm*.mp3; do
  if [ ! -f "$file" ]; then
    continue
  fi

  filename=$(basename "$file")
  normalized="$AUDIO_DIR/norm_$filename"

  echo "Normalizing: $filename"
  ffmpeg -y -i "$file" \
    -af "loudnorm=I=$TARGET_LUFS:TP=-1.5:LRA=11" \
    -ar 44100 \
    "$normalized" 2>/dev/null

  if [ $? -eq 0 ]; then
    mv "$normalized" "$file"
    echo "  Done: $filename"
  else
    rm -f "$normalized"
    echo "  Failed: $filename"
  fi
done

echo "All bgm files normalized to ${TARGET_LUFS} LUFS."
