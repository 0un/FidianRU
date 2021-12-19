# Fidian

Installscript for setting up a Fido node (or point..) using binkd, husky and golded.

# RaspberryPi Image

You can [download a Raspberry Pi SD-Card Image](https://www.kuehlbox.wtf/fidian#download) 
based on the standard Raspbian (aka RaspiOS) Image.  
This will automatically download and start fidian setup when you first login as 
the default user "pi" via console or SSH.

Nothing else is done. It's a completely fresh Raspbian installation. 
So, the following steps are strongly adviced:

1. Run `sudo raspi-config` to change the password for user *"pi"*, 
   setup your localisation options and most important: 
   **Expand your filesystem!** (at the *"Advanced Options"* submenu)
2. Update your Raspbian base system:  
`sudo apt update`  
`sudo apt upgrade`
3. You could also think about further securing the SSH server, silencing 
   syslog to safe your SD-Card, setting up dyndns and portforwarding, so you 
   can receive crashmail, but that's beyond the scope of this manual..

# Manual Installation
## interactive
    wget https://kuehlbox.wtf/fidosetup.sh
    sudo bash fidosetup.sh
    rm fidosetup.sh

## Headless

For non-interactive installation, add a file 
[fidoconfig.txt](https://gitlab.ambhost.net/stimpy/scripts_fidian/blob/master/fidoconfig.txt)
to the same folder, where the 
[fidosetup.sh](https://gitlab.ambhost.net/stimpy/scripts_fidian/blob/master/fidosetup.sh)
is located.  

Use the included 
[fidoconfig.txt](https://gitlab.ambhost.net/stimpy/scripts_fidian/blob/master/fidoconfig.txt)
as an example and template...

To add more than one link, copy *"fidoconfig.txt"* to *"fidoconfig2.txt"*, 
*"fidoconfig3.txt"* ... (up to 10 links allowed)

# (Re-)config

    fidoconfig.sh

# Uninstall

    sudo fidouninstall.sh




# Configuration Parameters explained
No matter whether, you're running *fidosetup.sh*, *fidoconfig.sh* or manually 
writing a headless configuration file *fidoconfig.txt*, it all comes down to 
these parameters:

## LINK_NAME
Free text identifier for this link.  
*eg: FidoNet*

## LINK_DOMAIN
Domain identifier (used internally to distinguish different links)  
While this is technically free text, but you should still use the standards 
provided by your uplink.  
*eg: fidonet*

## YOUR_NAME
Your full first- and last name.  
*eg: John Doe*

## YOUR_AKA
Your AKA, assigned by your uplink.  
*eg: 2:240/5853.5*

## YOUR_SYSTEM
Free text to identify your system. Most common: Name of your BBS or just your name.  
*eg: Johnny's Fido System*

## YOUR_LOCATION
Free text to identify your location.  
You're kindly asked to use a format like this: City, country.  
*eg: Frankfurt, germany*

## YOUR_HOSTNAME
If your system is reachable from the internet, please enter your FQDN here.  
*eg: your.domain.com*

## UPLINK_HOST
The FQDN or IP of your uplink.
*eg: kuehlbox.wtf*

## UPLINK_PORT
Port number of uplink's binkd.  
Leave empty for default: *24554*

## UPLINK_AKA
The AKA of your uplink.  
*eg: 2:240/5853*

## SESSION_PASSWORD
The session / binkp password provided by your uplink.  
*eg: SECRET123*

## PACKET_PASSWORD
The packet password provided by your uplink.  
Leave empty to use `SESSION_PASSWORD`

## AREAFIX_PASSWORD
The areafix password provided by your uplink.  
Leave empty to use `PACKET_PASSWORD`

## FILEFIX_PASSWORD
The filefix password provided by your uplink.  
Leave empty to use `AREAFIX_PASSWORD`

