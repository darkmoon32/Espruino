#! /bin/bash
function help(){
    echo "	flashBin -p <path> [-s <device>] [-e]
	-p Path to Espruino binary 
	-e Erase flash before program
	-s Serial device to use or is automaticaly detected
	-h Prints this help";
}

DEVICE=""
ERASE=false
BINPATH=""
UNKNOWN=false

while getopts ":e :p: :d:" opt; do
  case $opt in
    e)
      ERASE=true
      ;;
    d)
      DEVICE=$OPTARG
      ;;
    p)
      BINPATH=$OPTARG
      ;;
    \?)
      UNKNOWN=true
      ;;
  esac
done

if [ "$UNKNOWN" = true -o "$BINPATH" = "" -o ! -f "$BINPATH" ]; then
    help
else
    # erase flash before flashing
    if [ "$ERASE" = true ]; then
        st-flash erase
    fi
    # flash binary
    echo "writing image $BINPATH"
    st-flash write $BINPATH 0x8000000

    # try to detect device automaticaly
    if [ "$DEVICE" = "" ];then
    for path in $(find /sys/bus/usb/devices/usb*/ -name dev | grep ttyACM); do
        #echo ${path/\/[^/]+\/tty\/*/}
        # this solution is a bit hacky but not sure why the regex above does not work
        uevent=`cat ${path/\/[0-9]-[0-9]\.[0-9]:*/}/uevent`
        if [[ $uevent =~ "=483/5740/" ]]; then
            sub=${path/*\/tty\//}
            DEVICE="/dev/${sub/\/*/}"
            echo "Found Espruino device: $DEVICE"
        fi
    done
    
    fi

    if [ "$DEVICE" != "" ];then
        echo "writing startup code"
        minicom -D $DEVICE -S minicomData.txt
    else
        echo "No Espruino device found!"
    fi
fi
