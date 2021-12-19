#!/bin/bash

FLAGSDIR=/var/spool/ftn/flags
MSGBASE=/var/spool/ftn/msgbase
FILEBASE=/var/spool/ftn/filebase
HUSKYCFG=/etc/husky/config
BINKDCFG=/etc/binkd/binkd.cfg
UPLINK="@UPLINK_AKA@"
USER="ftn"
GROUP="ftn"

HPT=/usr/bin/hpt
HTICK=/usr/bin/htick
BINKD=/usr/sbin/binkd
SUDO=/usr/bin/sudo

if [ -e ${FLAGSDIR}/netscan ]
then
  chown -R ${USER}:${GROUP} ${MSGBASE}/*
  chmod -R 770 ${MSGBASE}/*
  find ${MSGBASE}/ -type f -exec chmod 660 "{}" \;
  ${SUDO} -u ${USER} ${HPT} -c ${HUSKYCFG} pack
  touch ${FLAGSDIR}/poll
  rm -f ${FLAGSDIR}/netscan
fi

if [ -e ${FLAGSDIR}/echoscan ]
then
  chown -R ${USER}:${GROUP} ${MSGBASE}/*
  chmod -R 770 ${MSGBASE}/*
  find ${MSGBASE}/ -type f -exec chmod 660 "{}" \;
  ${SUDO} -u ${USER} ${HPT} -c ${HUSKYCFG} scan
  touch ${FLAGSDIR}/poll
  rm -f ${FLAGSDIR}/echoscan
fi

if [ -e ${FLAGSDIR}/toss ]
then
  if [ ! -e ${FLAGSDIR}/tossing ]
  then
    touch ${FLAGSDIR}/tossing
    rm -f ${FLAGSDIR}/toss
    ${SUDO} -u ${USER} ${HPT} -c ${HUSKYCFG} toss
    chown -R ${USER}:${GROUP} ${MSGBASE}/*
    chmod -R 770 ${MSGBASE}/*
    find ${MSGBASE}/ -type f -exec chmod 660 "{}" \;
    rm -f ${FLAGSDIR}/tossing
  fi
fi

if [ -e ${FLAGSDIR}/tick ]
then
  ${SUDO} -u ${USER} ${HTICK} -c ${HUSKYCFG} toss
  chown -R ${USER}:${GROUP} ${FILEBASE}/*
  chmod -R 770 ${FILEBASE}/*
  find ${FILEBASE}/ -type f -exec chmod 660 "{}" \;
  rm -f ${FLAGSDIR}/tick
fi

if [ -e ${FLAGSDIR}/poll ]
then
  if [ ! -e ${FLAGSDIR}/polling ]
  then
    touch ${FLAGSDIR}/polling
    rm -f ${FLAGSDIR}/poll
    ${SUDO} -u ${USER} ${BINKD} -c -p -q -P "${UPLINK}" ${BINKDCFG}
    rm -f ${FLAGSDIR}/polling
  fi
fi
