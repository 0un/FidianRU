#/bin/bash

CFGFILES="$(curl -sqL https://fido.de/fidosetup.sh |grep '^CFGFILES' |cut -d'=' -f2- |tr -d '"')"
declare -A CFG

function readfidoconfig() {
  while read line
  do
    local k=$( echo "$line" |cut -d' ' -f1 )
    local v=$( echo "$line" |cut -d' ' -f2- )
    CFG[$k]="$v"
  done </home/fido/.fidoconfig
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

echo "*** Fidian updater"
echo ""

if [ "$(whoami)" != "root" ]
then
	echo "Please run as root:"
	echo "  sudo bash fidosetup.sh"
	echo ""
	exit 1
fi

echo "  This will update the Fidian scripts. It won't update binary packages."
echo "  Please use apt udpdate and apt upgrade for that."
echo ""

if [ -e /home/fido/.fidoconfig ]
then
	echo "  - Reading existing configuration"
	readfidoconfig
	echo "  - Downloading update"
	TMP=$( mktemp -d )
	wget --quiet -O ${TMP}/templates.zip https://gitlab.ambhost.net/stimpy/scripts_fidian/-/archive/master/scripts_fidian-master.zip
	unzip -qqo ${TMP}/templates.zip -d ${TMP}/

	echo "  - Configuring and installing update"
	for c in ${CFGFILES}
	do
		if [ $( echo "$c" |grep -c '.sh$' ) -gt 0 ]
		then
			f=$( basename "$c" )
			echo "    . ${f}"
			sed -i "s|@LINK_NAME@|${CFG[LINK_NAME]}|g" ${TMP}/scripts_fidian-master/cfgs/${f}
			sed -i "s|@LINK_DOMAIN@|${CFG[LINK_DOMAIN]}|g" ${TMP}/scripts_fidian-master/cfgs/${f}
			sed -i "s|@YOUR_NAME@|${CFG[YOUR_NAME]}|g" ${TMP}/scripts_fidian-master/cfgs/${f}
			sed -i "s|@YOUR_AKA@|${CFG[YOUR_AKA]}|g" ${TMP}/scripts_fidian-master/cfgs/${f}
			sed -i "s|@YOUR_SYSTEM@|${CFG[YOUR_SYSTEM]}|g" ${TMP}/scripts_fidian-master/cfgs/${f}
			sed -i "s|@YOUR_LOCATION@|${CFG[YOUR_LOCATION]}|g" ${TMP}/scripts_fidian-master/cfgs/${f}
			sed -i "s|@YOUR_HOSTNAME@|${CFG[YOUR_HOSTNAME]}|g" ${TMP}/scripts_fidian-master/cfgs/${f}
			sed -i "s|@UPLINK_HOST@|${CFG[UPLINK_HOST]}|g" ${TMP}/scripts_fidian-master/cfgs/${f}
			sed -i "s|@UPLINK_PORT@|${CFG[UPLINK_PORT]}|g" ${TMP}/scripts_fidian-master/cfgs/${f}
			sed -i "s|@UPLINK_AKA@|${CFG[UPLINK_AKA]}|g" ${TMP}/scripts_fidian-master/cfgs/${f}
			sed -i "s|@SESSION_PASSWORD@|${CFG[SESSION_PASSWORD]}|g" ${TMP}/scripts_fidian-master/cfgs/${f}
			sed -i "s|@PACKET_PASSWORD@|${CFG[PACKET_PASSWORD]}|g" ${TMP}/scripts_fidian-master/cfgs/${f}
			sed -i "s|@AREAFIX_PASSWORD@|${CFG[AREAFIX_PASSWORD]}|g" ${TMP}/scripts_fidian-master/cfgs/${f}
			sed -i "s|@FILEFIX_PASSWORD@|${CFG[FILEFIX_PASSWORD]}|g" ${TMP}/scripts_fidian-master/cfgs/${f}

			install -D -o ftn -g ftn -m 750 ${TMP}/scripts_fidian-master/cfgs/${f} ${c}
		fi
	done
	echo "    . fidosetup.sh" 
	install -D -o ftn -g ftn -m 750 ${TMP}/scripts_fidian-master/fidosetup.sh /usr/local/sbin/fidosetup.sh
	echo "    . fidoconfig.sh" 
	install -D -o ftn -g ftn -m 750 ${TMP}/scripts_fidian-master/fidoconfig.sh /usr/local/sbin/fidoconfig.sh
	echo ""
	echo "  - Fixing permissions"
	chown -f root:root /usr/local/sbin/semacheck.sh
	chmod -f 750 /usr/local/sbin/semacheck.sh
	echo ""
	echo "  - Done."
else
  echo "  - No existing installation found. Please use fidosetup.sh"
  echo "    for fresh installations."
  echo "    Get it at:"
  echo "      https://fido.de/fidosetup.sh"
	echo ""	
fi
