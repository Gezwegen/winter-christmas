#!/usr/bin/env bash
# ==============================================================================
# winter_christmas.sh - Full-Terminal Animated ASCII Winter & Christmas Scene
#
# Usage:
#   ./winter_christmas.sh [-m "CUSTOM MESSAGE"] [-s SNOW_COUNT] [-h]
#
# Interactive Controls while running:
#   [L] Cycle Tree Light Modes (Rainbow Wave / Warm Classic / Ice Blue / Disco)
#   [B] Toggle Blizzard Mode (High wind & fast snow)
#   [F] Launch Firework Burst
#   [H] Toggle Bottom Controls HUD
#   [Q] Quit cleanly
# ==============================================================================

export LC_ALL=C

# Generate special characters via octal so clipboards/parsers never corrupt them
E=$(printf '\033')
V=$(printf '\174')
B=$(printf '\134')

RST="${E}[0m"
DIM="${E}[2m"
RED="${E}[1;31m"
GRN="${E}[0;32m"
BGRN="${E}[1;32m"
YEL="${E}[1;33m"
BRN="${E}[0;33m"
BLU="${E}[1;34m"
MAG="${E}[1;35m"
CYN="${E}[1;36m"
WHT="${E}[1;37m"

COLORS=("${RED}" "${YEL}" "${CYN}" "${MAG}" "${BLU}" "${WHT}")
WARM_COLORS=("${RED}" "${YEL}" "${WHT}" "${RED}" "${YEL}" "${BRN}")
ICE_COLORS=("${CYN}" "${BLU}" "${WHT}" "${CYN}" "${WHT}" "${BLU}")
ORNS=("o" "O" "@" "*" "+")
SNOW_CH=("*" "." "+" "o")
AURORA_C=("${BGRN}" "${CYN}" "${MAG}" "${BLU}")
TREE_HW=(1 2 3 4 5 3 5 7 9 11 8 10 12 14 16 18)
MODE_NAMES=("Rainbow" "Classic" "Frozen" "Sparkle")

# Default settings & CLI argument parsing
CUSTOM_MSG="MERRY CHRISTMAS & HAPPY HOLIDAYS!"
NUM_SNOW=85

while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--message)
            CUSTOM_MSG="$2"
            shift 2
            ;;
        -s|--snow)
            NUM_SNOW="$2"
            shift 2
            ;;
        -h|--help)
            printf "Usage: %s [-m \"MESSAGE\"] [-s SNOW_COUNT]\n" "$0"
            printf "Interactive Keys: [L] Lights  [B] Blizzard  [F] Firework  [H] HUD  [Q] Quit\n"
            exit 0
            ;;
        *)
            shift
            ;;
    esac
done

running=1
need_resize=1
light_mode=0
blizzard=0
show_hud=1
tick=0

trap 'running=0' INT TERM
trap 'need_resize=1' WINCH

declare -a sr sc sch sdr

is_obstacle() {
    local r=$1 c=$2
    (( r <= 2 )) && return 0
    (( r >= GROUND_R )) && return 0
    (( r >= 3 && r <= 7 && c >= MOON_C - 1 && c <= MOON_C + 10 )) && return 0
    if (( r >= TREE_TOP - 3 && r <= TREE_TOP - 1 )); then
        (( c >= TREE_C - 5 && c <= TREE_C + 5 )) && return 0
    fi
    if (( r >= TREE_TOP && r <= TREE_TOP + 15 )); then
        local idx=$(( r - TREE_TOP ))
        local hw=$(( ${TREE_HW[$idx]} + 1 ))
        (( c >= TREE_C - hw && c <= TREE_C + hw )) && return 0
    fi
    if (( r >= TREE_TOP + 16 && r <= BASE_R )); then
        (( c >= TREE_C - 19 && c <= TREE_C + 19 )) && return 0
    fi
    (( r >= BASE_R - 8 && r <= BASE_R && c >= LAMP_C - 1 && c <= LAMP_C + 7 )) && return 0
    (( r >= BASE_R - 7 && r <= BASE_R && c >= SNOW_C - 1 && c <= SNOW_C + 15 )) && return 0
    (( r >= BASE_R - 15 && r <= BASE_R && c >= CABIN_C && c <= CABIN_C + 29 )) && return 0
    return 1
}

init_scene() {
    need_resize=0
    read -r ROWS COLS < <(stty size < /dev/tty 2>/dev/null)
    [[ -z "$COLS" ]] && COLS=$(tput cols < /dev/tty 2>/dev/tty)
    [[ -z "$ROWS" ]] && ROWS=$(tput lines < /dev/tty 2>/dev/tty)
    [[ -z "$COLS" ]] && COLS=120
    (( COLS < 100 )) && COLS=100
    [[ -z "$ROWS" ]] && ROWS=34
    (( ROWS < 28 )) && ROWS=28

    GROUND_R=$(( ROWS - 3 ))
    BASE_R=$(( GROUND_R - 1 ))

    TREE_C=$(( COLS * 20 / 100 ))
    (( TREE_C < 22 )) && TREE_C=22
    LAMP_C=$(( COLS * 41 / 100 ))
    SNOW_C=$(( COLS * 50 / 100 ))
    CABIN_C=$(( COLS * 67 / 100 ))
    (( CABIN_C > COLS - 31 )) && CABIN_C=$(( COLS - 31 ))
    MOON_C=$(( COLS - 13 ))
    TREE_TOP=$(( BASE_R - 18 ))

    max_sx=$(( COLS - 56 ))
    (( max_sx < 28 )) && max_sx=28
    sx=2
    drop_r=0
    drop_c=$(( COLS * 34 / 100 ))
    fw_state=0

    printf "%s" "${E}[?25l${E}[2J"
    local buf=""

    # 3-Tiered Giant Pine Tree
    local i r hw c k fill
    for (( i=0; i<16; i++ )); do
        r=$(( TREE_TOP + i ))
        hw=${TREE_HW[$i]}
        c=$(( TREE_C - hw ))
        fill=""
        for (( k=0; k<hw*2-1; k++ )); do
            if (( k % 2 == 0 )); then
                fill+="."
            else
                fill+="'"
            fi
        done
        if (( i == 4 )); then
            buf+="${E}[${r};${c}H${WHT}/${BGRN}${fill}${WHT}${B}${RST}"
        elif (( i == 9 )); then
            buf+="${E}[${r};${c}H${WHT}/${BGRN}${fill}${WHT}${B}${RST}"
        else
            buf+="${E}[${r};${c}H${GRN}/${fill}${B}${RST}"
        fi
    done

    # Tree skirt, trunk, and 4 two-row wrapped gifts
    local sc_skirt=$(( TREE_C - 18 ))
    buf+="${E}[$(( TREE_TOP + 16 ));${sc_skirt}H${BGRN}^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^~^${RST}"

    local g_c=$(( TREE_C - 16 ))
    buf+="${E}[$(( BASE_R - 1 ));${g_c}H??${YEL}_~_????${MAG}_o_???${BRN}[${V}???${V}]???${CYN}_@_????${RED}_*_??${RST}"
    buf+="${E}[${BASE_R};${g_c}H?${RED}[${YEL}+*+${RED}]??${CYN}[${MAG}#%#${CYN}]??${BRN}[${V}???${V}]??${MAG}[${YEL}@*@${MAG}]??${BGRN}[${RED}=!=${BGRN}]?${RST}"

    # Antique Streetlamp (9 rows tall)
    buf+="${E}[$(( BASE_R - 8 ));${LAMP_C}H??${WHT}_n_${RST}??"
    buf+="${E}[$(( BASE_R - 7 ));${LAMP_C}H?${BRN}/?*?${B}?${RST}"
    buf+="${E}[$(( BASE_R - 6 ));${LAMP_C}H?${BRN}${B}___/?${RST}"
    buf+="${E}[$(( BASE_R - 5 ));${LAMP_C}H???${BRN}${V}${RST}???"
    buf+="${E}[$(( BASE_R - 4 ));${LAMP_C}H?${RED}~(${BGRN}@${RED})~${RST}?"
    buf+="${E}[$(( BASE_R - 3 ));${LAMP_C}H???${BRN}${V}${RST}???"
    buf+="${E}[$(( BASE_R - 2 ));${LAMP_C}H???${BRN}${V}${RST}???"
    buf+="${E}[$(( BASE_R - 1 ));${LAMP_C}H???${BRN}${V}${RST}???"
    buf+="${E}[${BASE_R};${LAMP_C}H??${BRN}_L_${RST}??"

    # Grand 2-Story Winter Lodge (12 rows tall, 28 cols wide)
    buf+="${E}[$(( BASE_R - 10 ));${CABIN_C}H??????????${WHT}_.-^-._????${RED}[===]${RST}"
    buf+="${E}[$(( BASE_R - 9 ));${CABIN_C}H???????${WHT}.-'???_???'-.??${RED}${V}?${V}${RST}"
    buf+="${E}[$(( BASE_R - 8 ));${CABIN_C}H?????${WHT}.'????_(+)_????'.${RED}${V}_${V}${RST}"
    buf+="${E}[$(( BASE_R - 7 ));${CABIN_C}H???${WHT}.'_________________'.${RST}"
    buf+="${E}[$(( BASE_R - 6 ));${CABIN_C}H??${CYN}/vvvvvvvvvvvvvvvvvvvvv${B}${RST}"
    buf+="${E}[$(( BASE_R - 5 ));${CABIN_C}H??${BRN}${V}??.---.?.---.?.---.??${V}${RST}"
    buf+="${E}[$(( BASE_R - 4 ));${CABIN_C}H??${BRN}${V}??${V}*${V}*${V}?${V}${BGRN}(@)${BRN}${V}?${V}.${V}.${V}??${V}${RST}"
    buf+="${E}[$(( BASE_R - 3 ));${CABIN_C}H??${BRN}${V}??${V}---${V}?${V}???${V}?${V}---${V}??${V}${RST}"
    buf+="${E}[$(( BASE_R - 2 ));${CABIN_C}H??${BRN}${V}??${V}#${V}#${V}?${V}??${YEL}o${BRN}${V}?${V}+${V}*${V}??${V}${RST}"
    buf+="${E}[$(( BASE_R - 1 ));${CABIN_C}H??${BRN}${V}??'---'?.---.?'---'??${V}(o)${RST}"
    buf+="${E}[${BASE_R};${CABIN_C}H?_${BRN}${V}________${V}___${V}________${V}(o)(o)${RST}"

    # Full-Width Snowy Ground & Bottom Border
    local ground_line=""
    local bottom_line=""
    for (( c=1; c<COLS; c++ )); do
        if (( c % 4 == 0 )); then
            ground_line+="^"
        else
            ground_line+="~"
        fi
        bottom_line+="_"
    done
    buf+="${E}[${GROUND_R};1H${WHT}${ground_line}${RST}"
    buf+="${E}[$(( GROUND_R + 2 ));1H${WHT}${bottom_line}${RST}"

    buf="${buf//\?/ }"
    printf "%s" "$buf"

    for (( i=0; i<NUM_SNOW; i++ )); do
        sr[i]=$(( (RANDOM % (GROUND_R - 3)) + 3 ))
        sc[i]=$(( (RANDOM % (COLS - 4)) + 2 ))
        sch[i]=${SNOW_CH[$(( RANDOM % 4 ))]}
        sdr[i]=0
    done
}

trigger_firework() {
    fw_state=1
    local min_c=$(( TREE_C + 18 ))
    local max_c=$(( CABIN_C - 8 ))
    (( max_c <= min_c )) && max_c=$(( min_c + 10 ))
    fw_c=$(( (RANDOM % (max_c - min_c)) + min_c ))
    fw_r=$(( (RANDOM % 5) + 8 ))
    fw_col=${COLORS[$(( RANDOM % 6 ))]}
}

while (( running )); do
    (( need_resize )) && init_scene

    frame=""
    (( tick++ ))

    # 1. Full-Width 2-Row Northern Lights (Aurora Borealis)
    ac1=${AURORA_C[$(( tick % 4 ))]}
    ac2=${AURORA_C[$(( (tick + 1) % 4 ))]}
    ac3=${AURORA_C[$(( (tick + 2) % 4 ))]}
    aurora1=""
    aurora2=""
    for (( c=2; c<COLS-12; c+=14 )); do
        if (( (c + tick) % 2 == 0 )); then
            aurora1+="${E}[1;${c}H${ac1}~^~.~^~??${ac2}.~^~"
            aurora2+="${E}[2;${c}H??${ac2}.~^~^~.??${ac3}~^"
        else
            aurora1+="${E}[1;${c}H${ac2}.~^~^~.??${ac3}~^~."
            aurora2+="${E}[2;${c}H??${ac1}~^~.~^~??${ac2}.~"
        fi
    done
    frame+="${aurora1}${aurora2}${RST}"

    # 2. Erase previous snowflakes & falling parachute gift
    for (( i=0; i<NUM_SNOW; i++ )); do
        if (( sdr[i] == 1 )); then
            frame+="${E}[${sr[i]};${sc[i]}H?"
            sdr[i]=0
        fi
    done
    if (( drop_r > 0 )); then
        frame+="${E}[${drop_r};${drop_c}H?????"
        frame+="${E}[$(( drop_r + 1 ));${drop_c}H?????"
        frame+="${E}[$(( drop_r + 2 ));${drop_c}H?????"
    fi

    # 3. Update & draw falling snow (supports normal and Blizzard wind mode)
    for (( i=0; i<NUM_SNOW; i++ )); do
        sr[i]=$(( sr[i] + 1 ))
        if (( blizzard )); then
            sc[i]=$(( sc[i] + 2 + (RANDOM % 2) ))
        else
            sc[i]=$(( sc[i] + (RANDOM % 3) - 1 ))
        fi
        (( sc[i] < 2 )) && sc[i]=$(( COLS - 3 ))
        (( sc[i] > COLS - 3 )) && sc[i]=2
        if (( sr[i] >= GROUND_R )); then
            sr[i]=3
            sc[i]=$(( (RANDOM % (COLS - 4)) + 2 ))
        fi
        r=${sr[i]}
        c=${sc[i]}
        if ! is_obstacle "$r" "$c"; then
            if ! (( r >= 3 && r <= 6 && c >= sx && c <= sx + 54 )); then
                frame+="${E}[${r};${c}H${WHT}${sch[i]}${RST}"
                sdr[i]=1
            fi
        fi
    done

    # 4. Redraw Crescent Moon (so the sleigh passes smoothly in front of it)
    frame+="${E}[3;${MOON_C}H${YEL}???_.._??${RST}"
    frame+="${E}[4;${MOON_C}H${YEL}?.'?.-'??${RST}"
    frame+="${E}[5;${MOON_C}H${YEL}/??/?????${RST}"
    frame+="${E}[6;${MOON_C}H${YEL}${B}??${B}?????${RST}"
    frame+="${E}[7;${MOON_C}H${YEL}?'._'-._?${RST}"

    # 5. Large 4-Row Santa Sleigh & Team of 3 Reindeer (Rows 3-6)
    if (( tick % 2 == 0 )); then
        nose="${RED}*>"
        rein="${YEL}~~~~~"
        d1="${YEL}*?.?+?.?"
        d2="${CYN}.???*???"
    else
        nose="${YEL}o>"
        rein="${YEL}^^^^^"
        d1="${CYN}.?+?.?*?"
        d2="${YEL}??*???.?"
    fi

    case $(( tick % 4 )) in
        0) leg="${BRN}//??${B}${B}" ;;
        1) leg="${BRN}${V}${V}??${V}${V}" ;;
        2) leg="${BRN}${B}${B}??//" ;;
        3) leg="${BRN}/${V}??${V}${B}" ;;
    esac

    frame+="${E}[3;${sx}H?????????????${RED}_[_]_${RST}???????????${BRN}${B}_/?????${B}_/?????${B}_/?${RST}"
    frame+="${E}[4;${sx}H?${d1}${RED}_/${WHT}(###)${RED}${B}??_${RST}?${rein}?${BRN}(*>?????(*>?????(*${nose}${RST}"
    frame+="${E}[5;${sx}H?${d2}${RED}${B}_________${V}${YEL}--'${RST}????${BRN}.~'??${V}??.~'??${V}??.~'??${V}?${RST}"
    frame+="${E}[6;${sx}H???????????${YEL}?O======O'--'${RST}????${leg}??${leg}??${leg}?${RST}"

    # Parachuting Gift Dropped from Sleigh
    if (( drop_r == 0 && sx == drop_c - 6 )); then
        drop_r=7
    elif (( drop_r > 0 )); then
        (( drop_r++ ))
        if (( drop_r + 2 >= GROUND_R )); then
            drop_r=0
        elif ! is_obstacle "$(( drop_r + 2 ))" "$(( drop_c + 2 ))"; then
            frame+="${E}[${drop_r};${drop_c}H${WHT}.---.${RST}"
            frame+="${E}[$(( drop_r + 1 ));${drop_c}H${WHT}?${B}?/?${RST}"
            frame+="${E}[$(( drop_r + 2 ));${drop_c}H?${RED}[${YEL}+${RED}]?${RST}"
        fi
    fi

    (( sx++ ))
    if (( sx > max_sx )); then
        clr="??????????????????????????????????????????????????????"
        frame+="${E}[3;${max_sx}H${clr}${E}[4;${max_sx}H${clr}${E}[5;${max_sx}H${clr}${E}[6;${max_sx}H${clr}"
        sx=2
    fi

    # 6. Night Sky Fireworks (auto-launches periodically or via [F] key)
    (( fw_state == 0 && tick % 45 == 0 )) && trigger_firework
    if (( fw_state > 0 )); then
        case $fw_state in
            1)
                frame+="${E}[$(( fw_r + 2 ));${fw_c}H${YEL}^${RST}"
                ;;
            2)
                frame+="${E}[$(( fw_r + 2 ));${fw_c}H?${E}[$(( fw_r + 1 ));${fw_c}H${YEL}*${RST}"
                ;;
            3)
                frame+="${E}[$(( fw_r + 1 ));${fw_c}H?"
                frame+="${E}[$(( fw_r - 1 ));$(( fw_c - 2 ))H${fw_col}?.?*.?${RST}"
                frame+="${E}[${fw_r};$(( fw_c - 2 ))H${fw_col}?*${WHT}O${fw_col}*?${RST}"
                frame+="${E}[$(( fw_r + 1 ));$(( fw_c - 2 ))H${fw_col}?.?*.?${RST}"
                ;;
            4)
                frame+="${E}[$(( fw_r - 2 ));$(( fw_c - 4 ))H${fw_col}??*?.?*??${RST}"
                frame+="${E}[$(( fw_r - 1 ));$(( fw_c - 4 ))H${WHT}?.?.?.?.?${RST}"
                frame+="${E}[${fw_r};$(( fw_c - 4 ))H${fw_col}*?.???.*?${RST}"
                frame+="${E}[$(( fw_r + 1 ));$(( fw_c - 4 ))H${WHT}?.?.?.?.?${RST}"
                frame+="${E}[$(( fw_r + 2 ));$(( fw_c - 4 ))H${fw_col}??*?.?*??${RST}"
                ;;
            5)
                frame+="${E}[$(( fw_r - 2 ));$(( fw_c - 4 ))H${DIM}${fw_col}??.???.??${RST}"
                frame+="${E}[$(( fw_r - 1 ));$(( fw_c - 4 ))H?????????"
                frame+="${E}[${fw_r};$(( fw_c - 4 ))H${DIM}${fw_col}.???????.${RST}"
                frame+="${E}[$(( fw_r + 1 ));$(( fw_c - 4 ))H?????????"
                frame+="${E}[$(( fw_r + 2 ));$(( fw_c - 4 ))H${DIM}${fw_col}??.???.??${RST}"
                ;;
            6)
                for (( fr=fw_r-2; fr<=fw_r+2; fr++ )); do
                    frame+="${E}[${fr};$(( fw_c - 4 ))H?????????"
                done
                fw_state=-1
                ;;
        esac
        (( fw_state++ ))
    fi

    # 7. Large 3-Row Radiant Tree Star
    st_r=$(( TREE_TOP - 3 ))
    st_c=$(( TREE_C - 4 ))
    case $(( tick % 4 )) in
        0)
            frame+="${E}[${st_r};${st_c}H??${YEL}.?${V}?.??${RST}"
            frame+="${E}[$(( st_r + 1 ));${st_c}H${YEL}--?${WHT}*O*${YEL}?--${RST}"
            frame+="${E}[$(( st_r + 2 ));${st_c}H??${YEL}'/${V}${B}'??${RST}"
            ;;
        1)
            frame+="${E}[${st_r};${st_c}H??${WHT}${B}?${V}?/${RST}??"
            frame+="${E}[$(( st_r + 1 ));${st_c}H${WHT}.-?${YEL}+@+${WHT}?-.${RST}"
            frame+="${E}[$(( st_r + 2 ));${st_c}H??${WHT}/?${V}?${B}??${RST}"
            ;;
        2)
            frame+="${E}[${st_r};${st_c}H??${CYN}*?${V}?*??${RST}"
            frame+="${E}[$(( st_r + 1 ));${st_c}H${YEL}--?${WHT}+O+${YEL}?--${RST}"
            frame+="${E}[$(( st_r + 2 ));${st_c}H??${CYN}*?${V}?*??${RST}"
            ;;
        3)
            frame+="${E}[${st_r};${st_c}H??${YEL}${B}?${V}?/${RST}??"
            frame+="${E}[$(( st_r + 1 ));${st_c}H${WHT}--?${YEL}*O*${WHT}?--${RST}"
            frame+="${E}[$(( st_r + 2 ));${st_c}H??${YEL}/?${V}?${B}??${RST}"
            ;;
    esac

    # 8. 4 Selectable Tree Lighting & Garland Modes
    for (( i=0; i<16; i++ )); do
        r=$(( TREE_TOP + i ))
        hw=${TREE_HW[$i]}
        for (( c=TREE_C-hw+1; c<=TREE_C+hw-1; c+=2 )); do
            case $light_mode in
                0) # Rainbow Spiral Wave
                    if (( (i + c + tick) % 5 == 0 )); then
                        col=${COLORS[$(( (i + tick) % 6 ))]}
                        frame+="${E}[${r};${c}H${col}@${RST}"
                    else
                        col=${COLORS[$(( RANDOM % 6 ))]}
                        ch=${ORNS[$(( RANDOM % 5 ))]}
                        frame+="${E}[${r};${c}H${col}${ch}${RST}"
                    fi
                    ;;
                1) # Classic Warm Gold & Red
                    col=${WARM_COLORS[$(( (i + c + tick) % 6 ))]}
                    ch=${ORNS[$(( (i + c) % 5 ))]}
                    frame+="${E}[${r};${c}H${col}${ch}${RST}"
                    ;;
                2) # Frozen Ice Blue & White
                    col=${ICE_COLORS[$(( (i + tick) % 6 ))]}
                    ch=${ORNS[$(( (c + tick) % 5 ))]}
                    frame+="${E}[${r};${c}H${col}${ch}${RST}"
                    ;;
                3) # Disco Fast Sparkle
                    col=${COLORS[$(( RANDOM % 6 ))]}
                    frame+="${E}[${r};${c}H${col}*${RST}"
                    ;;
            esac
        done
    done

    # Twinkle Gift Bows & Streetlamp Lantern
    gc1=${COLORS[$(( tick % 6 ))]}
    gc2=${COLORS[$(( (tick + 2) % 6 ))]}
    gc3=${COLORS[$(( (tick + 4) % 6 ))]}
    frame+="${E}[$(( BASE_R - 1 ));$(( TREE_C - 14 ))H${gc1}_~_${RST}"
    frame+="${E}[$(( BASE_R - 1 ));$(( TREE_C - 7 ))H${gc2}_o_${RST}"
    frame+="${E}[$(( BASE_R - 1 ));$(( TREE_C + 5 ))H${gc3}_@_${RST}"
    frame+="${E}[$(( BASE_R - 1 ));$(( TREE_C + 12 ))H${gc1}_*_${RST}"

    if (( tick % 2 == 0 )); then
        frame+="${E}[$(( BASE_R - 7 ));$(( LAMP_C + 3 ))H${YEL}*${RST}"
    else
        frame+="${E}[$(( BASE_R - 7 ));$(( LAMP_C + 3 ))H${WHT}@${RST}"
    fi

    # 9. Detailed 8-Row Animated Waving Snowman
    frame+="${E}[$(( BASE_R - 7 ));${SNOW_C}H????${BLU}.-----.${RST}????"
    frame+="${E}[$(( BASE_R - 6 ));${SNOW_C}H??${BLU}__${V}${RED}=====${BLU}${V}__${RST}??"
    if (( tick % 7 == 0 )); then
        frame+="${E}[$(( BASE_R - 5 ));${SNOW_C}H???${WHT}(?-???-?)${RST}???"
    else
        frame+="${E}[$(( BASE_R - 5 ));${SNOW_C}H???${WHT}(?o???o?)${RST}???"
    fi
    frame+="${E}[$(( BASE_R - 4 ));${SNOW_C}H???${WHT}(??${RED}'>>'${WHT}?)${RST}???"
    if (( tick % 2 == 0 )); then
        frame+="${E}[$(( BASE_R - 3 ));${SNOW_C}H???${RED}/[##${YEL}*${RED}##]${B}~~${RST}?"
        frame+="${E}[$(( BASE_R - 2 ));${SNOW_C}H?${BRN}${B}/?${WHT}(??o??)${BRN}?${B}/?${RST}"
    else
        frame+="${E}[$(( BASE_R - 3 ));${SNOW_C}H???${RED}/[##${YEL}*${RED}##]${B}^^${RST}?"
        frame+="${E}[$(( BASE_R - 2 ));${SNOW_C}H?${BRN}/${B}?${WHT}(??o??)${BRN}?/${B}?${RST}"
    fi
    frame+="${E}[$(( BASE_R - 1 ));${SNOW_C}H????${WHT}(??o??)${RST}????"
    frame+="${E}[${BASE_R};${SNOW_C}H???${WHT}(_______)${RST}???"

    # 10. Flickering Lodge Fireplace, Attic Window, Wreath & 4-Row Chimney Smoke
    sm_c=$(( CABIN_C + 22 ))
    if (( tick % 2 == 0 )); then
        frame+="${E}[$(( BASE_R - 8 ));$(( CABIN_C + 12 ))H${YEL}+${RST}"
        frame+="${E}[$(( BASE_R - 4 ));$(( CABIN_C + 6 ))H${YEL}*${BRN}${V}${RED}#${RST}"
        frame+="${E}[$(( BASE_R - 2 ));$(( CABIN_C + 6 ))H${RED}#${BRN}${V}${YEL}*${RST}"
        frame+="${E}[$(( BASE_R - 4 ));$(( CABIN_C + 13 ))H${RED}@${RST}"
        frame+="${E}[$(( BASE_R - 2 ));$(( CABIN_C + 18 ))H${YEL}+${BRN}${V}${WHT}*${RST}"
        frame+="${E}[$(( BASE_R - 11 ));${sm_c}H${DIM}${WHT}?(??${RST}"
        frame+="${E}[$(( BASE_R - 12 ));${sm_c}H${DIM}${WHT}??)?${RST}"
        frame+="${E}[$(( BASE_R - 13 ));${sm_c}H${DIM}${WHT}?(??${RST}"
        frame+="${E}[$(( BASE_R - 14 ));${sm_c}H${DIM}${WHT}??.?${RST}"
    else
        frame+="${E}[$(( BASE_R - 8 ));$(( CABIN_C + 12 ))H${WHT}*${RST}"
        frame+="${E}[$(( BASE_R - 4 ));$(( CABIN_C + 6 ))H${RED}#${BRN}${V}${YEL}*${RST}"
        frame+="${E}[$(( BASE_R - 2 ));$(( CABIN_C + 6 ))H${YEL}*${BRN}${V}${RED}#${RST}"
        frame+="${E}[$(( BASE_R - 4 ));$(( CABIN_C + 13 ))H${YEL}*${RST}"
        frame+="${E}[$(( BASE_R - 2 ));$(( CABIN_C + 18 ))H${WHT}*${BRN}${V}${YEL}+${RST}"
        frame+="${E}[$(( BASE_R - 11 ));${sm_c}H${DIM}${WHT}??)?${RST}"
        frame+="${E}[$(( BASE_R - 12 ));${sm_c}H${DIM}${WHT}?(??${RST}"
        frame+="${E}[$(( BASE_R - 13 ));${sm_c}H${DIM}${WHT}??)?${RST}"
        frame+="${E}[$(( BASE_R - 14 ));${sm_c}H${DIM}${WHT}?.??${RST}"
    fi

    # 11. Full-Width Chasing Holiday Lights Marquee & Optional Interactive HUD
    msg_len=${#CUSTOM_MSG}
    msg_c=$(( (COLS - msg_len) / 2 ))
    lights=""
    for (( c=3; c<COLS-3; c+=4 )); do
        if (( c < msg_c - 3 )); then
            lc=${COLORS[$(( (c + tick) % 6 ))]}
            if (( (c / 4 + tick) % 2 == 0 )); then
                lights+="${E}[$(( GROUND_R + 1 ));${c}H${lc}*"
            else
                lights+="${E}[$(( GROUND_R + 1 ));${c}H${lc}o"
            fi
        elif (( c > msg_c + msg_len + 2 )); then
            lc=${COLORS[$(( (c + tick) % 6 ))]}
            if (( (c / 4 + tick) % 2 == 0 )); then
                lights+="${E}[$(( GROUND_R + 1 ));${c}H${lc}*"
            else
                lights+="${E}[$(( GROUND_R + 1 ));${c}H${lc}o"
            fi
        fi
    done
    safe_msg="${CUSTOM_MSG// /?}"
    frame+="${lights}${E}[$(( GROUND_R + 1 ));${msg_c}H${WHT}${safe_msg}${RST}"

    if (( show_hud )); then
        (( blizzard )) && b_txt="ON" || b_txt="OFF"
        hud="?[L]?Lights:?${MODE_NAMES[$light_mode]}???[B]?Blizzard:?${b_txt}???[F]?Firework???[H]?Hide?HUD???[Q]?Quit?"
        hud_c=$(( (COLS - ${#hud}) / 2 ))
        (( hud_c < 2 )) && hud_c=2
        frame+="${E}[$(( GROUND_R + 2 ));${hud_c}H${CYN}${hud}${RST}"
    fi

    frame="${frame//\?/ }"
    printf "%s" "$frame"

    # Non-blocking key read doubles as the frame timer (0.07s)
    key=""
    if [[ -r /dev/tty ]]; then read -rsn1 -t 0.07 key < /dev/tty 2>/dev/null; else sleep 0.07; fi
    case "$key" in
        q|Q) running=0 ;;
        l|L) light_mode=$(( (light_mode + 1) % 4 )); need_resize=1 ;;
        b|B) blizzard=$(( 1 - blizzard )); need_resize=1 ;;
        f|F) trigger_firework ;;
        h|H) show_hud=$(( 1 - show_hud )); need_resize=1 ;;
    esac
done

printf "%s\n" "${E}[?25h${E}[${ROWS};1H${RST}"
