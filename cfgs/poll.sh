#!/bin/sh

# Initialize variables
h=0
p=0
v=0
e=0

# Read parameters
for o in "$@"
do
  if [ "$o" = "-h" ]
  then
    h=1
  elif [ "$o" = "-v" ]
  then
    v=1
  elif [ "$o" = "-p" ]
  then
    p=1
  else
    e=1
  fi
done

# Display title if needed
if [ $v -gt 0 ] || [ $h -gt 0 ] || [ $e -gt 0 ]
then
  echo "*** Fidian POLL script"
  echo ""
fi

# Display help if needed
if [ $h -gt 0 ] || [ $e -gt 0 ]
then
  echo "  Usage: poll.sh [-h|-p|-d]"
  echo "  Parameters:"
  echo "    -h  - Display this help text"
  echo "    -v  - Be verbose"
  echo "    -p  - Fix messagebase permissions"
  echo ""
  exit
fi

# Verbose status
if [ $v -gt 0 ]
then
  echo -n "  - Polling mail... "
fi

# Actual command
sudo -u ftn /usr/sbin/binkd -c -p -q -P "@UPLINK_AKA@" /etc/binkd/binkd.cfg

# Status information
if [ $? -ne 0 ]
then
  if [ $v -gt 0 ]
  then
    echo "error ($?)"
  else
    echo "Error polling mail"
  fi
else
  if [ $v -gt 0 ]
  then
    echo "done."
  fi
fi

# Fix permissions if wanted
if [ $p -gt 0 ]
then
  if [ $v -gt 0 ]
  then
    echo "  - Fixing msgbase permissions... "
		echo "    root permissions needed. Please provide your password for sudo when asked."
		echo ""
  fi
  sudo chown -R ftn:ftn /var/spool/ftn/msgbase/*
  sudo chmod -R 770 /var/spool/ftn/msgbase/*
  sudo find /var/spool/ftn/msgbase/ -type f -exec chmod 660 "{}" \;
  if [ $v -gt 0 ]
  then
    echo "    done."
  fi
fi