#!/bin/bash

DESTINATION="."
CONFIG_FILE="$HOME/.db_puller_last"

if [ -t 1 ]; then
    C_RESET=$(tput sgr0); C_DIM=$(tput dim); C_BOLD=$(tput bold)
    C_CYAN=$(tput setaf 6); C_GREEN=$(tput setaf 2)
    C_YELLOW=$(tput setaf 3); C_RED=$(tput setaf 1)
else
    C_RESET=""; C_DIM=""; C_BOLD=""; C_CYAN=""; C_GREEN=""; C_YELLOW=""; C_RED=""
fi

WIDTH=68
INNER=$((WIDTH - 2))

# --- Core helpers ---------------------------------------------------------
# Semua box di bawah pakai karakter ASCII murni (+ - |), bukan unicode
# box-drawing/block. Unicode box-drawing/block termasuk kelas "ambiguous
# width" -- sebagian font/terminal merendernya 1 kolom, sebagian 2 kolom,
# jadi padding yang dihitung benar tetap bisa meleset di layar. ASCII selalu
# 1 kolom di semua terminal, jadi ini yang bikin box benar-benar rapi.

visible_len() {
    local s
    s="$(printf '%s' "$1" | sed -E 's/\x1b\[[0-9;]*m//g')"
    printf '%s' "${#s}"
}

pad_to() {
    local text="$1" width="$2"
    local len; len=$(visible_len "$text")
    local pad=$(( width - len ))
    [ "$pad" -lt 0 ] && pad=0
    printf '%s%*s' "$text" "$pad" ""
}

trunc() {
    local str="$1" len="$2"
    if [ ${#str} -gt "$len" ]; then
        echo "${str:0:$((len-2))}.."
    else
        echo "$str"
    fi
}

dashes() { [ "$1" -gt 0 ] 2>/dev/null && printf -- '-%.0s' $(seq 1 "$1"); return 0; }

box_top()    { printf "${C_CYAN}+%s+${C_RESET}\n" "$(dashes "$INNER")"; }
box_bottom() { printf "${C_CYAN}+%s+${C_RESET}\n" "$(dashes "$INNER")"; }
box_line()   { printf "${C_CYAN}|${C_RESET} %s ${C_CYAN}|${C_RESET}\n" "$(pad_to "$1" $((INNER - 2)))"; }
box_blank()  { box_line ""; }
step_header() { printf "\n  ${C_BOLD}[%s/4] %s${C_RESET}\n\n" "$1" "$2"; }

# --- ASCII logo ------------------------------------------------------------

draw_logo() {
    printf "${C_CYAN}"
    cat <<'LOGO'
████  ████    █████ █   █ █     █     █████ ████ 
█   █ █   █   █   █ █   █ █     █     █     █   █
█   █ ████    █████ █   █ █     █     ████  ████ 
█   █ █   █   █     █   █ █     █     █     █ █  
████  ████    █      ███  █████ █████ █████ █  ██
LOGO
    printf "${C_RESET}"
    printf "${C_DIM}                v1.2.0${C_RESET}\n"
    printf "${C_DIM}   Payaman Studio - Arif R.H${C_RESET}\n\n"
}

# --- Two-column device/app box ----------------------------------------------

box_top_titled() {
    local title="$1" width="$2"
    local prefix="-- ${title} "
    local plen=${#prefix}
    local dash=$(( width - plen ))
    [ "$dash" -lt 0 ] && dash=0
    printf "+%s%s+" "$prefix" "$(dashes "$dash")"
}

draw_two_columns() {
    local d_brand="$1" d_model="$2" d_serial="$3"
    local a_app="$4" a_pkg="$5" a_db="$6"
    local col=32   # lebar interior tiap box kecil (antara | dan |)

    d_brand=$(trunc "$d_brand" 22); d_model=$(trunc "$d_model" 22); d_serial=$(trunc "$d_serial" 22)
    a_app=$(trunc "$a_app" 22); a_pkg=$(trunc "$a_pkg" 22); a_db=$(trunc "$a_db" 22)

    printf "\n"
    printf "${C_CYAN}%s  %s${C_RESET}\n" \
        "$(box_top_titled "Device" "$col")" \
        "$(box_top_titled "App & Database" "$col")"
    printf "${C_CYAN}|${C_RESET} %s ${C_CYAN}|  |${C_RESET} %s ${C_CYAN}|${C_RESET}\n" \
        "$(pad_to "Brand : $d_brand" $((col - 2)))" "$(pad_to "App  : $a_app" $((col - 2)))"
    printf "${C_CYAN}|${C_RESET} %s ${C_CYAN}|  |${C_RESET} %s ${C_CYAN}|${C_RESET}\n" \
        "$(pad_to "Model : $d_model" $((col - 2)))" "$(pad_to "Pkg  : $a_pkg" $((col - 2)))"
    printf "${C_CYAN}|${C_RESET} %s ${C_CYAN}|  |${C_RESET} %s ${C_CYAN}|${C_RESET}\n" \
        "$(pad_to "Serial: $d_serial" $((col - 2)))" "$(pad_to "DB   : $a_db" $((col - 2)))"
    printf "${C_CYAN}+%s+  +%s+${C_RESET}\n" "$(dashes "$col")" "$(dashes "$col")"
}

local_size() { stat -c%s "$1" 2>/dev/null || stat -f%z "$1" 2>/dev/null || echo 0; }
human_kb()   { echo "$(( $1 / 1024 )) KB"; }

# Progress bar & prompt backup sengaja TIDAK dikotaki: progress bar redraw
# di baris yang sama (\r) dan lebar teksnya berubah tiap tick (KB/ETA), dan
# prompt backup cuma satu baris tanya-jawab yang langsung hilang -- ngotakin
# keduanya cuma nambah risiko border geser saat redraw, tanpa nilai tambah.
draw_progress() {
    local current=$1 total=$2 elapsed=$3
    local width=28
    local speed=0 eta="--"

    [ "$elapsed" -gt 0 ] 2>/dev/null && speed=$(( current / elapsed ))
    if [ "$speed" -gt 0 ] && [ "$total" -gt 0 ]; then
        eta="$(( (total - current) / speed ))s"
    fi

    local percent=0
    if [ "$total" -gt 0 ] 2>/dev/null; then
        percent=$(( current * 100 / total ))
        [ "$percent" -gt 100 ] && percent=100
    fi

    local filled=$(( width * percent / 100 ))
    local empty=$(( width - filled ))
    local bar_filled="" bar_empty=""
    [ "$filled" -gt 0 ] && bar_filled="$(printf '#%.0s' $(seq 1 $filled))"
    [ "$empty" -gt 0 ] && bar_empty="$(printf '.%.0s' $(seq 1 $empty))"

    printf "\r  ${C_GREEN}[%s${C_DIM}%s${C_RESET}${C_GREEN}]${C_RESET} ${C_BOLD}%3d%%${C_RESET}  %s/%s  %s/s  ETA %-4s" \
        "$bar_filled" "$bar_empty" "$percent" "$(human_kb "$current")" "$(human_kb "$total")" "$(human_kb "$speed")" "$eta"
}

# --- Main Flow ---------------------------------------------------------

clear
draw_logo

step_header 1 "Pilih Device"
DEVICE_LIST=$(adb devices | awk 'NR>1 && $2=="device" {print $1}')
if [ -z "$DEVICE_LIST" ]; then
    printf "  ${C_RED}X${C_RESET}  Tidak ada device terhubung via ADB.\n\n"
    exit 1
fi

COUNT=$(echo "$DEVICE_LIST" | wc -l | tr -d ' ')
if [ "$COUNT" -eq 1 ]; then
    SELECTED="$DEVICE_LIST"
else
    i=1
    while IFS= read -r SERIAL; do
        M=$(adb -s "$SERIAL" shell getprop ro.product.model 2>/dev/null | tr -d '\r')
        B=$(adb -s "$SERIAL" shell getprop ro.product.brand 2>/dev/null | tr -d '\r')
        printf "  %d  %-16s ${C_DIM}%s %s${C_RESET}\n" "$i" "$SERIAL" "$B" "$M"
        i=$((i + 1))
    done <<< "$DEVICE_LIST"
    printf "\n  ${C_DIM}[1-%d]${C_RESET} " "$COUNT"
    read -r CHOICE
    SELECTED=$(echo "$DEVICE_LIST" | sed -n "${CHOICE}p")
fi

BRAND=$(adb -s "$SELECTED" shell getprop ro.product.brand 2>/dev/null | tr -d '\r')
MODEL=$(adb -s "$SELECTED" shell getprop ro.product.model 2>/dev/null | tr -d '\r')

step_header 2 "Pilih App"
RAW_PACKAGES=$(adb -s "$SELECTED" shell pm list packages --user cur -3 2>/dev/null | grep '^package:' | cut -d: -f2 | tr -d '\r')
[ -z "$RAW_PACKAGES" ] && RAW_PACKAGES=$(adb -s "$SELECTED" shell pm list packages -3 2>/dev/null | grep '^package:' | cut -d: -f2 | tr -d '\r')

APP_LIST=""
while IFS= read -r PKG; do
    [ -z "$PKG" ] && continue
    SHORT_NAME=$(echo "$PKG" | awk -F'.' '{print $NF}' | tr '[:lower:]' '[:upper:]')
    APP_LIST="${APP_LIST}${SHORT_NAME} | ${PKG}\n"
done <<< "$RAW_PACKAGES"

SELECTED_ENTRY=$(echo -e "$APP_LIST" | grep -v '^$' | fzf --height 40% --layout=reverse --border --prompt="Cari App / Package: ")
[ -z "$SELECTED_ENTRY" ] && exit 1

PACKAGE_NAME=$(echo "$SELECTED_ENTRY" | awk -F '|' '{print $NF}' | xargs)
APP_LABEL=$(echo "$SELECTED_ENTRY" | awk -F '|' '{print $1}' | xargs)

step_header 3 "Pilih Database"
RAW_DBS=$(adb -s "$SELECTED" shell run-as "$PACKAGE_NAME" ls databases/ 2>/dev/null | tr -d '\r')
VALID_DBS=""
while IFS= read -r DB; do
    [ -z "$DB" ] && continue
    case "$DB" in
        *-journal|*-wal|*-shm|*ls:*|*No\ such*|*Permission\ denied*) continue ;;
        *) VALID_DBS="${VALID_DBS}${DB}\n" ;;
    esac
done <<< "$RAW_DBS"

VALID_DBS=$(echo -e "$VALID_DBS" | grep -v '^$')
DB_COUNT=$(echo "$VALID_DBS" | grep -c '^')

if [ "$DB_COUNT" -eq 1 ]; then
    DB_NAME=$(echo "$VALID_DBS" | head -n 1)
else
    DB_NAME=$(echo "$VALID_DBS" | fzf --height 30% --layout=reverse --border --prompt="Pilih Database: ")
fi
[ -z "$DB_NAME" ] && exit 1

step_header 4 "Download Database"
draw_two_columns "$BRAND" "$MODEL" "$SELECTED" "$APP_LABEL" "$PACKAGE_NAME" "$DB_NAME"

REMOTE_SIZE=$(adb -s "$SELECTED" shell run-as "$PACKAGE_NAME" stat -c%s "databases/$DB_NAME" 2>/dev/null | tr -d '\r\n')
if ! echo "$REMOTE_SIZE" | grep -qE '^[0-9]+$'; then
    REMOTE_SIZE=$(adb -s "$SELECTED" shell run-as "$PACKAGE_NAME" wc -c "databases/$DB_NAME" 2>/dev/null | awk '{print $1}' | tr -d '\r\n')
fi
[ -z "$REMOTE_SIZE" ] || ! echo "$REMOTE_SIZE" | grep -qE '^[0-9]+$' && REMOTE_SIZE=0

FINAL_PATH="$DESTINATION/$DB_NAME"

if [ -f "$FINAL_PATH" ]; then
    printf "\n  ${C_YELLOW}!${C_RESET}  %s sudah ada. Backup dengan timestamp? [y/N] " "$DB_NAME"
    read -r BACKUP_CHOICE
    if echo "$BACKUP_CHOICE" | grep -qiE '^y'; then
        TS=$(date +"%Y%m%d_%H%M%S")
        FINAL_PATH="$DESTINATION/${DB_NAME%.db}_$TS.db"
    fi
fi

printf "\n  ${C_BOLD}Downloading${C_RESET} %s\n\n" "$DB_NAME"

TMP_OUT="${FINAL_PATH}.tmp"
rm -f "$TMP_OUT"

START_TIME=$(date +%s)
adb -s "$SELECTED" exec-out run-as "$PACKAGE_NAME" cat "databases/$DB_NAME" > "$TMP_OUT" &
PULL_PID=$!

while kill -0 "$PULL_PID" 2>/dev/null; do
    CUR=$(local_size "$TMP_OUT")
    NOW=$(date +%s)
    ELAPSED=$((NOW - START_TIME))
    draw_progress "$CUR" "$REMOTE_SIZE" "$ELAPSED"
    sleep 0.2
done

wait "$PULL_PID"
PULL_STATUS=$?

NOW=$(date +%s)
ELAPSED=$((NOW - START_TIME))
CUR=$(local_size "$TMP_OUT")
draw_progress "$CUR" "$REMOTE_SIZE" "$ELAPSED"
echo ""

if [ "$PULL_STATUS" -eq 0 ] && [ -s "$TMP_OUT" ]; then
    mv "$TMP_OUT" "$FINAL_PATH"

    TABLE_COUNT="?"
    INTEGRITY="Unchecked"
    IS_OK=0
    if command -v sqlite3 >/dev/null 2>&1; then
        TABLE_COUNT=$(sqlite3 "$FINAL_PATH" "SELECT count(*) FROM sqlite_master WHERE type='table';" 2>/dev/null)
        INTEGRITY_RAW=$(sqlite3 "$FINAL_PATH" "PRAGMA integrity_check;" 2>/dev/null)
        if [ "$INTEGRITY_RAW" = "ok" ]; then
            INTEGRITY="ok"; IS_OK=1
        else
            INTEGRITY="issue detected"
        fi
    fi

    STR_SIZE="$(human_kb "$(local_size "$FINAL_PATH")")"

    printf "\n"
    box_top
    box_line "${C_GREEN}OK${C_RESET}   Selesai dalam ${ELAPSED}s"
    box_blank
    box_line "     Ukuran      $STR_SIZE"
    box_line "     Tabel       $TABLE_COUNT"
    if [ $IS_OK -eq 1 ]; then
        box_line "     Integrity   ${C_GREEN}${INTEGRITY}${C_RESET}"
    else
        box_line "     Integrity   ${C_YELLOW}${INTEGRITY}${C_RESET}"
    fi
    box_blank
    box_line "     -> $(basename "$FINAL_PATH")"
    box_bottom
    echo ""
else
    printf "\n"
    box_top
    box_line "${C_RED}X${C_RESET}    Gagal menarik database"
    box_line "     $DB_NAME"
    box_bottom
    echo ""
    rm -f "$TMP_OUT"
    exit 1
fi