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
  echo "*** Fidian TICK script"
  echo ""
fi

# Display help if needed
if [ $h -gt 0 ] || [ $e -gt 0 ]
then
  echo "  Usage: tick.sh [-h|-p|-d]"
  echo "  Parameters:"
  echo "    -h  - Display this help text"
  echo "    -v  - Be verbose"
  echo "    -p  - Fix filebase permissions"
  echo ""
  exit
fi

# Verbose status
if [ $v -gt 0 ]
then
  echo -n "  - Ticking files... "
fi

# Actual command
sudo -u ftn /usr/bin/htick -c /etc/husky/config toss

# Status information
if [ $? -ne 0 ]
then
  if [ $v -gt 0 ]
  then
    echo "error ($?)"
  else
    echo "Error ticking files"
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
    echo "  - Fixing filebase permissions... "
		echo "    root permissions needed. Please provide your password for sudo when asked."
		echo ""
  fi
  sudo chown -R ftn:ftn /var/spool/ftn/filebase/*
  sudo chmod -R 770 /var/spool/ftn/filebase/*
  sudo find /var/spool/ftn/filebase/ -type f -exec chmod 660 "{}" \;
  if [ $v -gt 0 ]
  then
    echo "    done."
  fi
fi
