#!/bin/bash
usage() { echo "Usage: $0 -r <time: Nh, Nm, or raw count> -n <white|pink|brown> -v <1-100> -e <element_id> [-l]"; exit 1; }

for cmd in amixer play ffmpeg; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: Required command '$cmd' not found. Please install it." >&2
    exit 1
  fi
done

wavpath="$HOME"
log_file="$HOME/sleepnoise.log"
volatile="$XDG_RUNTIME_DIR"
VOLUME=""
ELEMENT=""
LOGGING=false

for color in white pink brown; do
  if [[ ! -f "$wavpath"/"$color"_noise_192k_32bit.wav ]]; then
    ffmpeg -f lavfi -i "anoisesrc=color=$color:sample_rate=192000:duration=30" -acodec pcm_f32le -ar 192000 "$wavpath"/"$color"_noise_192k_32bit.wav &>/dev/null || exit 1
  fi
done

while getopts ":r:n:v:e:l" opt; do
  case "$opt" in
    r)
      if [[ $OPTARG =~ ^([0-9]+)([hHmM])$ ]]; then
        time_value="${BASH_REMATCH[1]}"
        time_unit="${BASH_REMATCH[2]}"

        time_unit="${time_unit,,}"

        if [[ $time_value -lt 1 ]]; then
          echo "ERROR: Time value must be at least 1m!"
          exit 1
        fi

        max_hours=8760
        if [[ $time_unit == "h" && $time_value -gt $max_hours ]]; then
          echo "ERROR: Hours value too large (max: $max_hours hours)!"
          exit 1
        elif [[ $time_unit == "m" && $time_value -gt $((max_hours * 60)) ]]; then
          echo "ERROR: Minutes value too large (max: $((max_hours * 60)) minutes)!"
          exit 1
        fi

        # Calculate repeats based on 30-second clips
        # Note: 'repeat N' plays audio N+1 times total (initial + N repeats)
        # So for 2 minutes we need repeat 3 (plays 4 times = 2 min)
        if [[ $time_unit == "h" ]]; then
          # hours * 60 min/hr * 60 sec/min / 30 sec/clip = hours * 120 total plays
          # repeat parameter is total_plays - 1
          REPEATS=$((time_value * 120 - 1))
          time_input="${time_value}h"
        elif [[ $time_unit == "m" ]]; then
          # minutes * 60 sec/min / 30 sec/clip = minutes * 2 total plays
          # repeat parameter is total_plays - 1
          REPEATS=$((time_value * 2 - 1))
          time_input="${time_value}m"
        fi
      elif [[ $OPTARG =~ ^[0-9]+$ ]]; then
        if [[ $OPTARG -lt 1 ]]; then
          echo "ERROR: Repeat count must be at least 1!"
          exit 1
        fi
        if [[ $OPTARG -gt $((max_hours * 120)) ]]; then
          echo "ERROR: Repeat count too large (max: $((max_hours * 120)))!"
          exit 1
        fi
        REPEATS=$OPTARG
        time_input="${REPEATS} repeats"
      else
        echo "ERROR: -r must be a positive integer, or time format like '2h' or '45m'!"
        exit 1
      fi
      ;;
    n)
      case $OPTARG in
        white|White|WHITE|w|W)
          NOISE="$wavpath/white_noise_192k_32bit.wav"
          ;;
        pink|Pink|PINK|p|P)
          NOISE="$wavpath/pink_noise_192k_32bit.wav"
          ;;
        brown|Brown|BROWN|b|B)
          NOISE="$wavpath/brown_noise_192k_32bit.wav"
          ;;
        *)
          # default to white if none specified or something else specified
          echo "ERROR: -n is either white, pink, or brown"
          exit 1
          ;;
      esac
      ;;
    v)
      if [[ $OPTARG =~ ^[0-9]+$ ]] && [[ $OPTARG -ge 1 ]] && [[ $OPTARG -le 100 ]]; then
        VOLUME=$OPTARG
      else
        echo "ERROR: -v must be an integer between 1 and 100 (volume % of the sound card)!"
        exit 1
      fi
      ;;
    e)
      if [[ $OPTARG =~ ^[0-9]+$ ]]; then
        ELEMENT=$OPTARG
      else
        echo "ERROR: -e must be an integer (sound card element ID discovered by running 'amixer controls')!"
        exit 1
      fi
      ;;
    l)
      LOGGING=true
      ;;
    *)
      usage ;;
  esac
done
shift $((OPTIND-1))
# Check all required parameters and collect missing ones
missing=()
[[ -z "$REPEATS" ]] && missing+=("-r <time: Nh, Nm, or raw count>")
[[ -z "$NOISE" ]] && missing+=("-n <white|pink|brown> (noise color)")
[[ -z "$VOLUME" ]] && missing+=("-v <1-100> (volume % of sound card)")
[[ -z "$ELEMENT" ]] && missing+=("-e <element_id> (from 'amixer controls')")

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "Usage: $0 -r <time: Nh, Nm, or raw count> -n <white|pink|brown> -v <1-100> -e <element_id> [-l]"
  echo ""
  echo "ERROR: Missing required parameter(s):"
  for param in "${missing[@]}"; do
    echo "  $param"
  done
  echo ""
  echo "Optional:"
  echo "  -l (enable logging to $HOME/sleepnoise.log)"
  exit 1
fi
[[ -f "$NOISE" ]] || {
  echo "$NOISE not found. Aborting." >&2
  exit 1; }
  # copy wav to tmpfs for 0 disk usage
  if [[ -f "$volatile/${NOISE##*/}" ]]; then
    echo "Audio file already in volatile storage, reusing..."
  else
    echo "Copying audio file to volatile storage..."
    if ! cp "$NOISE" "$volatile"; then
      echo "ERROR: Failed to copy $NOISE to $volatile (disk full or permissions issue)" >&2
      exit 1
    fi
  fi

  now=$(date "+%Y-%m-%d %H:%M:%S")
  if [[ "$LOGGING" == true ]]; then
    echo "$now ${NOISE##*/} ${time_input} (${REPEATS} repeats)" >> $log_file
  fi
  # 20% --> 51 dB
  # 15% --> 37 dB
  # 10% --> 35 dB
  amixer -c 0 cset numid=$ELEMENT ${VOLUME}% 2>/dev/null

# trap to handle only interruption signals (not normal EXIT)
cleanup() {
  if [[ -n "$play_pid" ]] && kill -0 "$play_pid" 2>/dev/null; then
    if [[ "$LOGGING" == true ]]; then
      echo "$(date '+%Y-%m-%d %H:%M:%S') ${NOISE##*/} INTERRUPTED" >> "$log_file"
    fi
    kill "$play_pid" 2>/dev/null
  fi
}
trap cleanup INT TERM

(
  play -q "$volatile/${NOISE##*/}" repeat $REPEATS &>/dev/null
  rc=$?
  if [[ "$LOGGING" == true ]]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') ${NOISE##*/} FINISHED"  >> "$log_file"
  fi
  exit $rc
  ) &
  play_pid=$!
  # vim:set ts=2 sw=2 et:
