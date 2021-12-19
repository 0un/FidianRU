#!/bin/bash

declare -A CFG

function readfidoconfig() {
  if [ -e /home/fido/.fidoconfig${1} ]
  then
    while read line
    do
      local k=$( echo "$line" |cut -d' ' -f1 )
      local v=$( echo "$line" |cut -d' ' -f2- )
      CFG[$k]="$v"
    done </home/fido/.fidoconfig${1}
    if [ "${CFG[UPLINK_PORT]}" == "UPLINK_PORT" ]
    then
      CFG[UPLINK_PORT]="24554"
    fi
    if [ "${CFG[PACKET_PASSWORD]}" == "PACKET_PASSWORD" ]
    then
      CFG[PACKET_PASSWORD]=${CFG[SESSION_PASSWORD]}
    fi
    if [ "${CFG[AREAFIX_PASSWORD]}" == "AREAFIX_PASSWORD" ]
    then
      CFG[AREAFIX_PASSWORD]=${CFG[PACKET_PASSWORD]}
    fi
    if [ "${CFG[FILEFIX_PASSWORD]}" == "FILEFIX_PASSWORD" ]
    then
      CFG[FILEFIX_PASSWORD]=${CFG[AREAFIX_PASSWORD]}
    fi
  else
    CFG[LINK_NAME]=""
    CFG[LINK_DOMAIN]=""
    CFG[YOUR_NAME]=""
    CFG[YOUR_AKA]=""
    CFG[YOUR_SYSTEM]=""
    CFG[YOUR_LOCATION]=""
    CFG[YOUR_HOSTNAME]=""
    CFG[UPLINK_HOST]=""
    CFG[UPLINK_PORT]=""
    CFG[UPLINK_AKA]=""
    CFG[SESSION_PASSWORD]=""
    CFG[PACKET_PASSWORD]=""
    CFG[AREAFIX_PASSWORD]=""
    CFG[FILEFIX_PASSWORD]=""
  fi
}

function form() {
  if [ "$1" != '' ]
  then
    u=$1
  else
    u=1
  fi
  if [ "$2" == "last" ]
  then
    t="Please edit your configuration for Uplink #${u}\n(leave empty to skip)"
  else
    t="Please edit your configuration for Uplink #${u}"
  fi
  while [ ${returncode:-99} -ne 1 -a ${returncode:-99} -ne 250 ]
  do
    exec 3>&1
    value=`dialog --clear --default-button extra --cancel-label "Skip" --extra-label "Change" --ok-label "Save" --backtitle "Fidian configuration" --inputmenu "${t}" 19 64 15 \
      "Link Name:" "${CFG[LINK_NAME]}" \
      "Link Domain:" "${CFG[LINK_DOMAIN]}" \
      "Your Name:" "${CFG[YOUR_NAME]}" \
      "Your AKA:" "${CFG[YOUR_AKA]}" \
      "Your System:" "${CFG[YOUR_SYSTEM]}" \
      "Your Location:" "${CFG[YOUR_LOCATION]}" \
      "Your Hostname:" "${CFG[YOUR_HOSTNAME]}" \
      "Uplink Host:" "${CFG[UPLINK_HOST]}" \
      "Uplink Port:" "${CFG[UPLINK_PORT]}" \
      "Uplink AKA:" "${CFG[UPLINK_AKA]}" \
      "Session Password:" "${CFG[SESSION_PASSWORD]}" \
      "Packet Password:" "${CFG[PACKET_PASSWORD]}" \
      "Areafix Password:" "${CFG[AREAFIX_PASSWORD]}" \
      "Filefix Password:" "${CFG[FILEFIX_PASSWORD]}" 2>&1 1>&3 `
    returncode=$?
    exec 3>&-
    case $returncode in
      1)
        # skip/quit
        dialog --clear --backtitle "Fidian configuration" --yesno "Really skip this link?" 5 40
        case $? in
          0)
            returncode=99
            break
          ;;
        esac
      ;;
			255)
				# ESC pressed
        dialog --clear --backtitle "Fidian configuration" --yesno "Really quit without saving current link?" 5 40
        case $? in
          0)
            returncode=99
						clear
            exit 99
          ;;
        esac
			;;
      0)
        # saved
        if  [ "${CFG[LINK_NAME]}" != "" ] &&
            [ "${CFG[LINK_DOMAIN]}" != "" ] &&
            [ "${CFG[YOUR_NAME]}" != "" ] &&
            [ "${CFG[YOUR_AKA]}" != "" ] &&
            [ "${CFG[YOUR_SYSTEM]}" != "" ] &&
            [ "${CFG[YOUR_LOCATION]}" != "" ] &&
            [ "${CFG[YOUR_HOSTNAME]}" != "" ] &&
            [ "${CFG[UPLINK_HOST]}" != "" ] &&
            [ "${CFG[UPLINK_AKA]}" != "" ] &&
            [ "${CFG[SESSION_PASSWORD]}" != "" ]
        then
          echo "LINK_NAME ${CFG[LINK_NAME]}" >/home/fido/.fidoconfig${1}
          echo "LINK_DOMAIN ${CFG[LINK_DOMAIN]}" >>/home/fido/.fidoconfig${1}
          echo "YOUR_NAME ${CFG[YOUR_NAME]}" >>/home/fido/.fidoconfig${1}
          echo "YOUR_AKA ${CFG[YOUR_AKA]}" >>/home/fido/.fidoconfig${1}
          echo "YOUR_SYSTEM ${CFG[YOUR_SYSTEM]}" >>/home/fido/.fidoconfig${1}
          echo "YOUR_LOCATION ${CFG[YOUR_LOCATION]}" >>/home/fido/.fidoconfig${1}
          echo "YOUR_HOSTNAME ${CFG[YOUR_HOSTNAME]}" >>/home/fido/.fidoconfig${1}
          echo "UPLINK_HOST ${CFG[UPLINK_HOST]}" >>/home/fido/.fidoconfig${1}
          echo "UPLINK_PORT ${CFG[UPLINK_PORT]}" >>/home/fido/.fidoconfig${1}
          echo "UPLINK_AKA ${CFG[UPLINK_AKA]}" >>/home/fido/.fidoconfig${1}
          echo "SESSION_PASSWORD ${CFG[SESSION_PASSWORD]}" >>/home/fido/.fidoconfig${1}
          echo "PACKET_PASSWORD ${CFG[PACKET_PASSWORD]}" >>/home/fido/.fidoconfig${1}
          echo "AREAFIX_PASSWORD ${CFG[AREAFIX_PASSWORD]}" >>/home/fido/.fidoconfig${1}
          echo "FILEFIX_PASSWORD ${CFG[FILEFIX_PASSWORD]}" >>/home/fido/.fidoconfig${1}
        fi
        break
      ;;
      3)
        # changed
        value=`echo "$value" | sed -e 's/^RENAMED //'`
        tag=`echo "$value" | cut -d':' -f1`
				item=`echo "$value" | sed -e 's/^[^:]*:[    ][  ]*//'`
        case "$tag" in
          "Link Name")
            CFG[LINK_NAME]="$item"
          ;;
          "Link Domain")
            CFG[LINK_DOMAIN]="$item"
          ;;
          "Your Name")
            CFG[YOUR_NAME]="$item"
          ;;
          "Your AKA")
            CFG[YOUR_AKA]="$item"
          ;;
          "Your System")
            CFG[YOUR_SYSTEM]="$item"
          ;;
          "Your Location")
            CFG[YOUR_LOCATION]="$item"
          ;;
          "Your Hostname")
            CFG[YOUR_HOSTNAME]="$item"
          ;;
          "Uplink Host")
            CFG[UPLINK_HOST]="$item"
          ;;
          "Uplink Port")
            CFG[UPLINK_PORT]="$item"
          ;;
          "Uplink AKA")
            CFG[UPLINK_AKA]="$item"
          ;;
          "Session Password")
            CFG[SESSION_PASSWORD]="$item"
          ;;
          "Packet Password")
            CFG[PACKET_PASSWORD]="$item"
          ;;
          "Areafix Password")
            CFG[AREAFIX_PASSWORD]="$item"
          ;;
          "Filefix Password")
            CFG[FILEFIX_PASSWORD]="$item"
          ;;
        esac
      ;;
    esac
  done
}
j=1
for i in '' 2 3 4 5 6 7 8 9 10
do
  if [ -e /home/fido/.fidoconfig${i} ]
  then
    readfidoconfig ${i}
    form ${i}
    if [ "$i" != "" ]
    then
      j=i
    fi
  fi
done
j=$((j+1))
readfidoconfig $j
form $j last

dialog --clear --backtitle "Fidian configuration" --yesno "Reconfigure BinkD, Husky and GoldED?" 5 40
case $? in
	0)
    clear
    echo "Starting setup script. You need to be root for this."
    echo "Please enter your password when asked..."
    sudo fidosetup.sh
	;;
esac
