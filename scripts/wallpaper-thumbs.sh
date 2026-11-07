#!/bin/sh
# Builds 448x252 JPEG thumbnails in $1 for each image argument, printing "<source>\t<thumb>" as each
# finishes so the UI can swap in cached thumbnails progressively.
cache_dir=$1
shift
mkdir -p "$cache_dir" || exit 1

for src do
    [ -f "$src" ] || continue
    key=$(printf '%s' "$src" | sha1sum | cut -d' ' -f1)
    out="$cache_dir/$key.jpg"
    if [ ! -s "$out" ] || [ "$src" -nt "$out" ]; then
        tmp="$cache_dir/.$key.$$.jpg"
        if command -v vipsthumbnail >/dev/null 2>&1; then
            vipsthumbnail "$src" -s 448x252 -m centre -o "$tmp[Q=85,strip]" 2>/dev/null
        elif command -v ffmpeg >/dev/null 2>&1; then
            ffmpeg -y -loglevel error -i "$src" \
                -vf "scale=448:252:force_original_aspect_ratio=increase,crop=448:252" \
                -frames:v 1 -q:v 4 "$tmp" 2>/dev/null
        fi
        if [ -s "$tmp" ]; then
            mv -f "$tmp" "$out"
        else
            rm -f "$tmp"
            continue
        fi
    fi
    printf '%s\t%s\n' "$src" "$out"
done
