#!/bin/bash

CFGFILES="/etc/husky/areas /etc/binkd/binkd.cfg /etc/binkd/binkd.inc /home/fido/.golded/charsets.cfg /etc/husky/config /etc/husky/fileareas /home/fido/.golded/golded.cfg /home/fido/.golded/local.cfg /home/fido/.golded/goldkeys.cfg /etc/husky/links /etc/husky/route /usr/local/sbin/poll.sh /usr/local/sbin/toss.sh /usr/local/sbin/tick.sh /usr/local/sbin/echoscan.sh /usr/local/sbin/netscan.sh /usr/local/sbin/fidocomplete.sh /etc/logrotate.d/husky /usr/local/sbin/semacheck.sh /usr/local/sbin/fidoupdate.sh"
VERSION="0.2.4 RU"
declare -A CFG

function readfidoconfig() {
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
}
function helptext() {
  echo ""
  echo "If you want to override the OS autodetection, append \"debian\" or"
  echo "\"raspbian\" as a parameter to ${0}."
  echo "  eg: ${0} debian"
  echo ""
  exit 0
}
function d_inputbox() {
  echo -n '' >${TMP}/dialog.tmp
  d=""
  if [ "$6" == "required" ]
  then
    while [ "$d" == "" ]
    do
      dialog --backtitle "$2" --no-cancel --max-input $5 --inputbox "$3" $4 $5 2>${TMP}/dialog.tmp
      d="$(cat ${TMP}/dialog.tmp)"
    done
  else
    dialog --backtitle "$2" --no-cancel --max-input $5 --inputbox "$3" $4 $5 2>${TMP}/dialog.tmp
    d="$(cat ${TMP}/dialog.tmp)"
  fi
  echo "$1 $d">>/home/fido/.fidoconfig
}
function interactive() {
  dialog --backtitle "Fidian interactive setup" --extra-button --extra-label Cancel --msgbox "No /home/fido/.fidoconf found.\nStarting interactive mode. Please answer the following questions.\nIf you need help, check https://kuehlbox.wtf/fidian" 10 40
  if [ $? -lt 1 ]
  then
    echo -n "" >/home/fido/.fidoconfig
    d_inputbox "LINK_NAME" "Fidian interactive setup" "Link name:\n(eg: FidoNet)" 10 32 required
    d_inputbox "LINK_DOMAIN" "Fidian interactive setup" "Link domain:\n(eg: fidonet)" 10 32 required
    d_inputbox "YOUR_NAME" "Fidian interactive setup" "Your full name:\n(eg: John Doe)" 10 64 required
    d_inputbox "YOUR_AKA" "Fidian interactive setup" "Your full AKA:\n(eg: 2:240/5853.1)" 10 32 required
    d_inputbox "YOUR_SYSTEM" "Fidian interactive setup" "Your system name:\n(eg: Johnny's FidoMailer)" 10 64 required
    d_inputbox "YOUR_LOCATION" "Fidian interactive setup" "Your geographical location:\n(eg: Frankfurt, germany)" 10 64 required
    d_inputbox "YOUR_HOSTNAME" "Fidian interactive setup" "Your hostname (may be imaginary, but FQDN): \n(eg: john.kennmer.net)" 10 64 required
    d_inputbox "UPLINK_HOST" "Fidian interactive setup" "Your Uplink's hostname or IP:\n(eg: kuehlbox.wtf)" 10 64 required
    d_inputbox "UPLINK_PORT" "Fidian interactive setup" "Your Uplink's binkp port:\n(leave empty for default)" 10 32
    d_inputbox "UPLINK_AKA" "Fidian interactive setup" "Your Uplink's AKA:\n(eg: 2:240/5853)" 10 32 required
    d_inputbox "SESSION_PASSWORD" "Fidian interactive setup" "Your Session password:" 10 32 required
    d_inputbox "PACKET_PASSWORD" "Fidian interactive setup" "Your Packet password:\n(leave empty to use Session password)" 10 32
    d_inputbox "AREAFIX_PASSWORD" "Fidian interactive setup" "Your Areafix password:\n(leave empty to use Packet password)" 10 32
    d_inputbox "FILEFIX_PASSWORD" "Fidian interactive setup" "Your Filefix password:\n(leave empty to use Areafix password)" 10 32
    dialog --backtitle "Fidian interactive setup" --msgbox "All done.\nContinuing with non-interactive installation." 10 40
  else
    rm -rf ${TMP}
    exit 10
  fi
}

if [ "$(whoami)" != "root" ]
then
  echo "You need to run this as root."
  echo "eg: sudo $0"
  exit 1
fi

echo "Fidian v${VERSION} (c) 2021 by Philipp Giebel <stimpy@kuehlbox.wtf>"

if [ "$1" != "" ] && [ "$1" != "debian" ] && [ "$1" != "raspbian" ]
then
  helptext
fi

if [ "$1" == "debian" ]
then
  os="debian"
elif [ "$1" == "raspbian" ]
then
  os="raspbian"
else
  os="$( cat /etc/os-release |grep '^ID=' |cut -d'=' -f2 )"
  if [ "$os" != "debian" ] && [ "$os" != "raspbian" ]
  then
    echo "Unknown OS: ${os}"
    echo "Only Debian and Raspbian are supported at the moment"
    echo "Use parameter to override autodetection at your own risk:"
    echo "${0} <debian|raspbian>"
    echo ""
    exit 2
  fi
fi

osversion="$( cat /etc/os-release |grep '^VERSION_ID=' |cut -d'"' -f2 )"

if [ "$osversion" != "10" ] && [ "$osversion" != "11" ]
then
  echo "Wrong OS version: ${osversion}"
  echo "Only buster and stretch are supported at the moment."
  echo "Use second parameter to override autodetection at your own risk:"
  echo "eg: ${0} ${os} 11"
  echo ""
  exit 3
fi

echo ""
echo "  * Installing dependencies"
apt-get -qqy install apt-transport-https sudo gnupg x11-utils

if [ "$( grep -c fido /etc/passwd)" -eq 0 ]
then
  echo ""
  echo "  * Adding Fido user"
  adduser --quiet --disabled-password --gecos "" fido
fi

echo ""
if [ ! -e /etc/apt/sources.list.d/fido.list ]
then
  echo "  * Adding Husky and GoldED Repository from fido.de"

  if [ -e /etc/apt/sources.list.d/kuehlbox.list ]
  then
    echo "    ! Removing old repository and replacing with repo.fido.de"
    rm -f /etc/apt/sources.list.d/kuehlbox.list
  fi
else
  echo "  * Husky and GoldED Repository from fido.de already added"
fi

if [ "$os" == "debian" ]
then
	if [ "$osversion" == "11" ]
	then
		wget --quiet -O /etc/apt/sources.list.d/fido.list https://repo.fido.de/debian/fido.bullseye.list
	else
		wget --quiet -O /etc/apt/sources.list.d/fido.list https://repo.fido.de/debian/fido.buster.list
	fi
	echo -ne "  * Installing / updating Fidian repo gpg key\n "
	wget --quiet -O - https://repo.fido.de/debian/gpg.key |apt-key add -
else
	if [ "$osversion" == "11" ]
	then
		wget --quiet -O /etc/apt/sources.list.d/fido.list https://repo.fido.de/raspbian/fido.bullseye.list
	else
		wget --quiet -O /etc/apt/sources.list.d/fido.list https://repo.fido.de/raspbian/fido.buster.list
	fi
	echo -ne "  * Installing / updating Fidian repo gpg key\n "
	wget --quiet -O - https://repo.fido.de/raspbian/gpg.key |apt-key add -
fi

echo "  * Updating package cache"
apt-get -qq update

echo ""
echo "  * Installing packages:"
echo "    - sudo dialog wget unzip zip binkd hpt htick nltools sqpack goldedplus"
echo ""
apt-get -qqy install sudo dialog wget unzip zip binkd hpt htick nltools sqpack goldedplus

echo ""
echo "  * creating temp dir"
TMP=$( mktemp -d )

if [ "$(grep -c fido /etc/sudoers)" == "0" ]
then
  echo ""
  echo "  * allowing \"sudo ftn nopasswd\" and \"sudo all\" with pw for user \"fido\""
  echo 'fido  ALL=(ALL) ALL' | (EDITOR="tee -a" visudo)
  echo 'fido  ALL=(ftn) NOPASSWD: /usr/sbin/binkd, /usr/bin/hpt, /usr/bin/htick, /usr/bin/sqpack, /usr/bin/nlupd' | (EDITOR="tee -a" visudo)
fi

echo ""
echo "  * adding fido user to group ftn"
adduser --quiet fido ftn

if [ $(echo $PATH |grep -c '/usr/local/sbin') -eq 0 ]
then
  echo "    - fixing PATH"
  echo 'PATH="$PATH:/usr/local/sbin"' >> /home/fido/.profile
fi

if [ -e /etc/inetd.conf ]
then
	if [ $( grep -c 'binkd' /etc/inetd.conf ) -gt 0 ]
	then
		echo ""
		echo "  * Disabling inetd start of binkd, running as daemon"
		/usr/sbin/service openbsd-inetd stop
		sed -i "/binkd/d" /etc/inetd.conf
		sleep 5
		/usr/sbin/service openbsd-inetd start
	fi
fi

if [ -e ./fidoconfig.txt ] && [ ! -e /home/fido/.fidoconfig ]
then
  echo ""
  echo "  * Automatic configuration found. Copying to /home/fido/"
  cp ./fidoconfig.txt /home/fido/.fidoconfig
fi

if [ ! -e /home/fido/.fidoconfig ]
then
  echo ""
  echo "  ! No .fidoconfig found. Entering interactive mode..."
  interactive
fi


echo ""
echo "  * Generating configuration files"
echo "    - downloading templates"
#wget --quiet -O ${TMP}/templates.zip https://gitlab.ambhost.net/stimpy/scripts_fidian/-/archive/master/scripts_fidian-master.zip
#unzip -qqo ${TMP}/templates.zip -d ${TMP}/
#mv ${TMP}/scripts_fidian-master/cfgs/* ${TMP}/
cp $(dirname $(readlink -f $0))/cfgs/* ${TMP}/

for i in '' 2 3 4 5 6 7 8 9 10
do
	if [ -e /home/fido/.fidoconfig${i} ]
	then
    readfidoconfig ${i}
    echo "    - Setting up link: ${CFG[LINK_NAME]}"
    for f in ${CFGFILES}
    do
      c=$( basename "$f" )
      sed -i "s|@LINK_NAME@|${CFG[LINK_NAME]}|g" ${TMP}/${c}
      sed -i "s|@LINK_DOMAIN@|${CFG[LINK_DOMAIN]}|g" ${TMP}/${c}
      sed -i "s|@YOUR_NAME@|${CFG[YOUR_NAME]}|g" ${TMP}/${c}
      sed -i "s|@YOUR_AKA@|${CFG[YOUR_AKA]}|g" ${TMP}/${c}
      sed -i "s|@YOUR_SYSTEM@|${CFG[YOUR_SYSTEM]}|g" ${TMP}/${c}
      sed -i "s|@YOUR_LOCATION@|${CFG[YOUR_LOCATION]}|g" ${TMP}/${c}
      sed -i "s|@YOUR_HOSTNAME@|${CFG[YOUR_HOSTNAME]}|g" ${TMP}/${c}
      sed -i "s|@UPLINK_HOST@|${CFG[UPLINK_HOST]}|g" ${TMP}/${c}
      sed -i "s|@UPLINK_PORT@|${CFG[UPLINK_PORT]}|g" ${TMP}/${c}
      sed -i "s|@UPLINK_AKA@|${CFG[UPLINK_AKA]}|g" ${TMP}/${c}
      sed -i "s|@SESSION_PASSWORD@|${CFG[SESSION_PASSWORD]}|g" ${TMP}/${c}
      sed -i "s|@PACKET_PASSWORD@|${CFG[PACKET_PASSWORD]}|g" ${TMP}/${c}
      sed -i "s|@AREAFIX_PASSWORD@|${CFG[AREAFIX_PASSWORD]}|g" ${TMP}/${c}
      sed -i "s|@FILEFIX_PASSWORD@|${CFG[FILEFIX_PASSWORD]}|g" ${TMP}/${c}
    done
    sed -i "s|@ADDRESSES@|${CFG[YOUR_AKA]}@${CFG[LINK_DOMAIN]} @ADDRESSES@|g" ${TMP}/binkd.cfg
    sed -i "s|@ADDRESSES@|address ${CFG[YOUR_AKA]}\n@ADDRESSES@|g" ${TMP}/config
    if [ "$i" != "" ]
    then
      sed -i "s|@OTHER_DOMAINS@|domain ${CFG[LINK_DOMAIN]} /var/spool/ftn/outb 2\n@OTHER_DOMAINS@|g" ${TMP}/binkd.cfg
    fi
    echo "" >>${TMP}/binkd.inc
    echo "node ${CFG[UPLINK_AKA]}@${CFG[LINK_DOMAIN]} ${CFG[UPLINK_HOST]}:${CFG[UPLINK_PORT]} ${CFG[SESSION_PASSWORD]} i" >>${TMP}/binkd.inc

		echo "Link ${CFG[LINK_NAME]} Uplink" >>${TMP}/links
		echo "Aka ${CFG[UPLINK_AKA]}" >>${TMP}/links
    echo "ourAka ${CFG[YOUR_AKA]}" >>${TMP}/links
    echo "Password ${CFG[PACKET_PASSWORD]}" >>${TMP}/links
    echo "EchoMailFlavour Crash" >>${TMP}/links
    echo "areafixAutoCreateDefaults -a ${CFG[YOUR_AKA]} -b Jam -p 3650 -dupeCheck move -dupeHistory 14 -d \"(${CFG[LINK_DOMAIN]}) \" -g ${CFG[LINK_DOMAIN]}" >>${TMP}/links
    echo "linkMsgBaseDir /var/spool/ftn/msgbase/fido" >>${TMP}/links
    echo "filebox /var/spool/ftn/filebase/fido" >>${TMP}/links
    echo "forwardRequests on" >>${TMP}/links
    echo "Packer zip" >>${TMP}/links
    echo "LinkGrp ${CFG[LINK_DOMAIN]}" >>${TMP}/links
    echo "AccessGrp ${CFG[LINK_DOMAIN]}" >>${TMP}/links
		echo "" >>${TMP}/links

		if [ "${CFG[LINK_DOMAIN]}" == "fidonet" ]
		then
			echo "route crash ${CFG[UPLINK_AKA]} 1:* 2:* 3:* 4:* 5:*" >>${TMP}/route
		else
			u=$( echo "${CFG[UPLINK_AKA]}" |cut -d':' -f1 )
			echo "route crash ${CFG[UPLINK_AKA]} ${u}:*" >>${TMP}/route
		fi

		if [ "$i" == "" ]
		then
      sed -i "s|@ADDRESSES@|ADDRESS ${CFG[YOUR_AKA]}        ;${CFG[LINK_DOMAIN]}\n@ADDRESSES@|g" ${TMP}/golded.cfg
		else
      sed -i "s|@ADDRESSES@|AKA ${CFG[YOUR_AKA]}        ;${CFG[LINK_DOMAIN]}\n@ADDRESSES@|g" ${TMP}/golded.cfg
		fi
	fi
done

sed -i "s|@ADDRESSES@||g" ${TMP}/golded.cfg
sed -i "s|@ADDRESSES@||g" ${TMP}/config
sed -i "s|@ADDRESSES@||g" ${TMP}/binkd.cfg
sed -i "s|@OTHER_DOMAINS@||g" ${TMP}/binkd.cfg

echo ""
echo "  * Copying configuration files to their destinations"

for f in ${CFGFILES}
do
  s=$( basename "$f" )
  install -D -o ftn -g ftn -m 660 ${TMP}/${s} ${f}
done

echo ""
echo "  * Creating missing directories"
mkdir -p /var/spool/ftn/outb
mkdir -p /var/spool/ftn/inb/insecure
mkdir -p /var/spool/ftn/outb
mkdir -p /var/spool/ftn/tmp/inb
mkdir -p /var/spool/ftn/tmp/outb
mkdir -p /var/spool/ftn/dupes
mkdir -p /var/spool/ftn/nodelist
mkdir -p /var/spool/ftn/fileboxes
mkdir -p /var/spool/ftn/filebase
mkdir -p /var/spool/ftn/transit
mkdir -p /var/spool/ftn/flags
mkdir -p /var/spool/ftn/msgbase/fido
mkdir -p /var/log/husky
mkdir -p /var/log/binkd
touch /var/spool/ftn/msgbase/netmail.jdt
touch /var/spool/ftn/msgbase/netmail.jdx
touch /var/spool/ftn/msgbase/netmail.jhr
touch /var/spool/ftn/msgbase/netmail.jlr
touch /var/spool/ftn/msgbase/bad.jdt
touch /var/spool/ftn/msgbase/bad.jdx
touch /var/spool/ftn/msgbase/bad.jhr
touch /var/spool/ftn/msgbase/bad.jlr
touch /var/spool/ftn/msgbase/dupe.jdt
touch /var/spool/ftn/msgbase/dupe.jdx
touch /var/spool/ftn/msgbase/dupe.jhr
touch /var/spool/ftn/msgbase/dupe.jlr
touch /var/spool/ftn/msgbase/personal.mail.jdt
touch /var/spool/ftn/msgbase/personal.mail.jdx
touch /var/spool/ftn/msgbase/personal.mail.jhr
touch /var/spool/ftn/msgbase/personal.mail.jlr

if [ ! -e /etc/cron.d/fido ]
then
  echo ""
  echo "  * Installing cronjobs"
  echo "*/1 * * * *   root  /usr/local/sbin/semacheck.sh" >/etc/cron.d/fido
  echo "*/10 * * * *  ftn   touch /var/spool/ftn/flags/poll; touch /var/spool/ftn/flags/echoscan; touch /var/spool/ftn/flags/netscan" >>/etc/cron.d/fido
  echo '8 6 * * 3     ftn   /usr/bin/cronic /usr/bin/sqpack -c /etc/husky/config "*"; chmod -R 770 /var/spool/ftn/msgbase; find /var/spool/ftn/msgbase -type f -exec chmod 660 "{}" \;' >>/etc/cron.d/fido
  echo "    - restarting cron"
  /usr/sbin/service cron restart
fi

echo ""
echo "  * Downloading FidoNet Nodelist"
wget --quiet -O "${TMP}/nl.zip" https://kuehlbox.wtf/nlget/fido/nl
unzip -qqo "${TMP}/nl.zip" -d /var/spool/ftn/nodelist
chown ftn:ftn /var/spool/ftn/nodelist/*
chmod 660 /var/spool/ftn/nodelist/*
echo "    - Downloading unofficial BinkD Nodelist"
wget --quiet -O "${TMP}/btnl.zip" https://kuehlbox.wtf/BT_IBN.zip
unzip -qqo "${TMP}/btnl.zip" -d /etc/binkd/

echo ""
echo "  * Fixing permissions"
chown -fR fido:fido /home/fido/.golded
chown -fR fido:fido /home/fido/.fidoconfig*
chown -fR ftn:ftn /etc/binkd
chown -fR ftn:ftn /etc/husky
chown -fR ftn:ftn /var/spool/ftn
chown -fR ftn:ftn /var/log/binkd
chown -fR ftn:ftn /var/log/husky
chmod -f 770 /home/fido/.golded
chmod -f 660 /home/fido/.golded/*
chmod -f 660 /home/fido/.fidoconfig*
chmod -f 770 /etc/binkd
chmod -f 660 /etc/binkd/*
chmod -f 770 /etc/husky
chmod -f 660 /etc/husky/*
chmod -f 770 /var/log/binkd
chmod -f 660 /var/log/binkd/*
chmod -f 770 /var/log/husky
chmod -f 660 /var/log/husky/*
chmod -fR 770 /var/spool/ftn
find /var/spool/ftn/ -type f -exec chmod -f 660 "{}" \;
chown -f root:ftn /usr/local/sbin/poll.sh
chown -f root:ftn /usr/local/sbin/toss.sh
chown -f root:ftn /usr/local/sbin/tick.sh
chown -f root:ftn /usr/local/sbin/echoscan.sh
chown -f root:ftn /usr/local/sbin/netscan.sh
chown -f root:ftn /usr/local/sbin/fidocomplete.sh
chown -f root:ftn /usr/local/sbin/fidoupdate.sh
chown -f root:root /usr/local/sbin/semacheck.sh
chmod -f 750 /usr/local/sbin/semacheck.sh
chmod -f 750 /usr/local/sbin/poll.sh
chmod -f 750 /usr/local/sbin/toss.sh
chmod -f 750 /usr/local/sbin/tick.sh
chmod -f 750 /usr/local/sbin/echoscan.sh
chmod -f 750 /usr/local/sbin/netscan.sh
chmod -f 750 /usr/local/sbin/fidocomplete.sh
chmod -f 750 /usr/local/sbin/fidoupdate.sh

if  [ ! -e /home/fido/.golded/charsets.cfg ] || 
    [ ! -e /home/fido/.golded/goldkeys.cfg ] || 
    [ ! -e /home/fido/.golded/goldlang.cfg ] || 
    [ ! -e /home/fido/.golded/goldhelp.cfg ]
then
  echo ""
  echo "  * Copying GoldED default cfg files"
  if [ ! -e /home/fido/.golded/charsets.cfg ]
  then
    gunzip -c /usr/share/doc/goldedplus/examples/config/charsets.cfg.gz >/home/fido/.golded/charsets.cfg
  fi
  if [ ! -e /home/fido/.golded/goldkeys.cfg ]
  then
    gunzip -c /usr/share/doc/goldedplus/examples/config/goldkeys.cfg.gz >/home/fido/.golded/goldkeys.cfg
  fi
  if [ ! -e /home/fido/.golded/goldlang.cfg ]
  then
    gunzip -c /usr/share/doc/goldedplus/examples/config/goldlang.cfg.gz >/home/fido/.golded/goldlang.cfg
  fi
  if [ ! -e /home/fido/.golded/goldhelp.cfg ]
  then
    gunzip -c /usr/share/doc/goldedplus/examples/config/goldhelp.cfg.gz >/home/fido/.golded/goldhelp.cfg
  fi
fi

echo ""
echo "  * compiling GoldED Nodelist"
sudo -u fido gnlnx -Q -F /home/fido/.golded/golded.cfg

echo ""
if  [ ! -e /usr/local/sbin/fidoconfig.sh ] ||
    [ ! -e /usr/local/sbin/fidosetup.sh ] ||
    [ ! -e /usr/local/sbin/fidouninstall.sh ]
then
  echo "  * Installing Fidian scripts"
else
  echo "  * Updating Fidian scripts"
fi
  echo "    - fidoconfig.sh"
#  install -D -o fido -g ftn -m 755 ${TMP}/scripts_fidian-master/fidoconfig.sh /usr/local/sbin/fidoconfig.sh
  install -D -o fido -g ftn -m 755 $(dirname $(readlink -f $0))/fidoconfig.sh /usr/local/sbin/fidoconfig.sh
  echo "    - fidosetup.sh"
#  install -D -o root -g ftn -m 755 ${TMP}/scripts_fidian-master/fidosetup.sh /usr/local/sbin/fidosetup.sh
  install -D -o root -g ftn -m 755 $(dirname $(readlink -f $0))/fidosetup.sh /usr/local/sbin/fidosetup.sh
  echo "    - fidouninstall.sh"
#  install -D -o root -g ftn -m 755 ${TMP}/scripts_fidian-master/fidouninstall.sh /usr/local/sbin/fidouninstall.sh
  install -D -o root -g ftn -m 755 $(dirname $(readlink -f $0))/fidouninstall.sh /usr/local/sbin/fidouninstall.sh
  echo "    - ge for run GoldEd"
  install -D -o fido -g ftn -m 755 $(dirname $(readlink -f $0))/cfgs/ge /home/fido/ge

echo ""
echo "  * Setting locales"
if [ $( grep -c '^ru_RU ISO-8859-5' /etc/locale.gen ) -lt 1 ]
then
  echo "    - adding ru_RU ISO-8859-5"
  echo "ru_RU ISO-8859-5" >>/etc/locale.gen
fi
if [ $( grep -c '^ru_RU.KOI8-R KOI8-R' /etc/locale.gen ) -lt 1 ]
then
  echo "    - adding ru_RU.KOI8-R"
  echo "ru_RU.KOI8-R KOI8-R" >>/etc/locale.gen
fi
if [ $( grep -c '^ru_RU.UTF-8 UTF-8' /etc/locale.gen ) -lt 1 ]
then
  echo "    - adding ru_RU.UTF-8"
  echo "ru_RU.UTF-8 UTF-8" >>/etc/locale.gen
fi
echo "    - Running locale-gen"
locale-gen

echo ""
echo "  * (Re-)starting binkd"
/usr/sbin/service binkd stop
sleep 5
/usr/sbin/service binkd start

echo ""
echo "  * Cleaning up temp files"
rm -rf ${TMP}

echo ""
read -r -s -n 1 -t 10 -p '  * Press any key to set a password for user "fido" or wait 10 seconds to skip.' key

if [ "$?" == "0" ]
then
  echo ""
  passwd fido
else
  echo ""
  echo '    ! You chose not to set a password for user "fido", now.'
  echo '    ! So, you need to do this later, yourself, by invocing the following '
  echo '    ! command:'
  echo '    !   sudo passwd fido'
fi

echo ""
echo '  * ALL DONE!'
echo '    You can now login as user "fido" and start reading and writing, using'
echo '    "ge".'
echo ''
echo '    Mail is autoatically polled and tossed every 10 minutes or when you '
echo '    write any of your own.'
echo '    You can also use the convenience scripts "poll.sh", "toss.sh", '
echo '    "tick.sh", "echoscan.sh" and "netscan.sh" to force running the '
echo '    corresponding function or "fidocomplete.sh" to run all of the above.'
echo ''
echo '    Use "fidoconfig.sh" to change your configuration and/or add links.'
echo ''
echo '    Use "fidouninstall.sh" to uninstall everything, you just installed.'
echo ""
