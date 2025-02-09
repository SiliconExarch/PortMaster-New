#!/bin/bash
if [ -d "/opt/system/Tools/PortMaster/" ]; then
  controlfolder="/opt/system/Tools/PortMaster"
elif [ -d "/opt/tools/PortMaster/" ]; then
  controlfolder="/opt/tools/PortMaster"
else
  controlfolder="/roms/ports/PortMaster"
fi

source $controlfolder/control.txt
source $controlfolder/device_info.txt

get_controls

GAMEDIR=/$directory/ports/worldofgoo
CONFDIR="$GAMEDIR/conf/"

CUR_TTY=/dev/tty0
$ESUDO chmod 666 $CUR_TTY

exec > >(tee "$GAMEDIR/log.txt") 2>&1

cd $GAMEDIR

# Ensure the conf directory exists
mkdir -p "$GAMEDIR/conf"

# Set the XDG environment variables for config & savefiles
export XDG_CONFIG_HOME="$CONFDIR"
export XDG_DATA_HOME="$CONFDIR"

# Setup GL4ES
export LIBGL_FB=4
export LIBGL_ES=2
export LIBGL_GL=21

# Setup Box64
export LD_LIBRARY_PATH="$GAMEDIR/box64/native":"/usr/lib":"/usr/lib/aarch64-linux-gnu/":"$GAMEDIR/libs/":"$LD_LIBRARY_PATH"
export BOX64_LD_LIBRARY_PATH="$GAMEDIR/box64/x64":"$GAMEDIR/box64/native":"$GAMEDIR/libs/x64"

export SDL_VIDEO_GL_DRIVER="$GAMEDIR/box64/native/libGL.so.1"
export SDL_GAMECONTROLLERCONFIG="$sdl_controllerconfig"

export TEXTINPUTINTERACTIVE="Y"

# Extract and organize game files if the installer exists
WOG_FILE=$(ls *.sh 2> /dev/null | head -n 1)

if [ -f "$WOG_FILE" ]; then
    unzip -o "$WOG_FILE" > "$CUR_TTY"
    # Handle game directory movement based on structure
    if [ -d "data/noarch/game/game" ]; then
        $ESUDO mv -f data/noarch/game/game "$GAMEDIR/gamedata/"
    elif [ -d "data/noarch/game" ]; then
        $ESUDO mv -f data/noarch/game "$GAMEDIR/gamedata/"
    else
        echo "Game directory not found after extraction." > "$CUR_TTY"
        sleep 5
        exit 1
    fi
    # Directly search and move WorldOfGoo.bin.x86_64
    if $ESUDO mv -f $(find . -name "WorldOfGoo.bin.x86_64" -print -quit) "$GAMEDIR/gamedata/WorldOfGoo.bin" 2>/dev/null; then
        $ESUDO chmod +x "$GAMEDIR/gamedata/WorldOfGoo.bin"
    else
        echo "WorldOfGoo.bin.x86_64 not found after extraction." > "$CUR_TTY"
        sleep 5
        exit 1
    fi

    rm -rf data/ meta/ scripts/
    rm -f "$WOG_FILE"
    echo "Setup complete. Have fun playing!" > "$CUR_TTY"
fi

$GPTOKEYB "WorldOfGoo.bin" -c "./worldofgoo.gptk" &
$GAMEDIR/box64/box64 gamedata/WorldOfGoo.bin

$ESUDO kill -9 $(pidof gptokeyb)
$ESUDO systemctl restart oga_events &
printf "\033c" > /dev/tty0