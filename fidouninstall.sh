#!/bin/bash

if [ "$(whoami)" != "root" ]
then
  echo "Please run as root."
  echo "eg: sudo $0"
  exit 2
fi
if [ "$(ps aux |grep -c '^fido')" != "0" ]
then
  dialog --backtitle "Fidian uninstall" --extra-button --extra-label "Abort" --ok-label "Continue anyway" --msgbox "Please run as root with user \"fido\" completely logged out everywhere, or delete the folder \"/home/fido/\" manually, later..." 10 40
  if [ $? -gt 0 ]
  then
    clear
    echo "Aborted..."
    echo ""
    exit 1
  fi
fi

dialog --backtitle "Fidian uninstall" --extra-button --extra-label Cancel --msgbox "This will completely uninstall everything fido related.\nIncluding all data and configuration!" 10 40
if [ $? -lt 1 ]
then
  clear
  echo "Starting uninstall"
  echo ""
  grep -v fido /etc/sudoers | (EDITOR="tee" visudo)
  apt-get -qy purge binkd hpt htick nltools sqpack goldedplus
  apt-get -qy autoremove
  rm -f /etc/apt/sources.list.d/kuehlbox.list
  rm -f /etc/apt/sources.list.d/fido.list
  deluser fido
  rm -rf /home/fido
  rm -rf /etc/husky
  rm -rf /etc/binkd
  rm -rf /var/spool/ftn/*
  rm -rf /var/log/husky
  rm -rf /var/log/binkd
  rm -f /usr/local/sbin/echoscan.sh
  rm -f /usr/local/sbin/fidocomplete.sh
  rm -f /usr/local/sbin/fidoconfig.sh
  rm -f /usr/local/sbin/fidosetup.sh
  rm -f /usr/local/sbin/fidouninstall.sh
  rm -f /usr/local/sbin/netscan.sh
  rm -f /usr/local/sbin/poll.sh
  rm -f /usr/local/sbin/semacheck.sh
  rm -f /usr/local/sbin/tick.sh
  rm -f /usr/local/sbin/toss.sh
  rm -f /etc/cron.d/fido
  rm -f /etc/logrotate.d/husky
else
  clear
  echo "Aborted..."
  exit 1
fi

