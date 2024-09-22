# Pi

Currently the pi image is being built in a separate repo: https://github.com/socallinuxexpo/scale-kiosk

## gold image instructions

Instructions heavily influenced by https://youtu.be/T9AtKld8USU

### Create bootable SDCARD:

1. Download the current specified Raspbian image from https://www.raspberrypi.org/downloads/raspbian/
   a. As of 2020-02-24 the specified image is `2019-09-26-raspbian-buster-lite.img`

1. Write to an SD Card using [Etcher](https://www.balena.io/etcher/)

#### Boot and setup system:

1. Boot up

1. Log in as pi/raspberry

1. sudo adduser admin (set password)

1. sudo usermod -aG sudo admin

1. sudo apt-get update; sudo apt-get upgrade -y

1. sudo reboot

1. Log in as pi

1. sudo apt-get install lightdm -y

1. sudo raspi-config

   -- 2. Network Options

   ---- N1. Hostname

   ------ set name to kiosk (you cannot change this later without great effort, chromium's lock depends on hostname)

   -- 3. Boot Options

   ---- B1. Desktop / CLI

   ------ Select Console no auto login

   -- 4. Localization Options

   ---- I2. Change Timezone

   ------ America > Los Angeles

   -- 4. Localization Options

   ---- I3. Change Keyboard Layout

   ------ Generic 104-key PC > Other > English (US) > English (US) > The default for the keyboard layout > No compose key > No

   -- 7. Advanced Options

   ---- A2. Overscan

   ------ No > Ok

   -- 7. Advanced Options

   ---- A3. Memory Split

   ------ Enter 256

   -- Finish

   ---- Yes to Reboot

1. After reboot hit CTRL+ALT+F2 to get a terminal

1. Login as admin

1. sudo apt-get install plymouth plymouth-themes pix-plym-splash -y

1. wget https://linuxjournal.com/sites/default/files/nodeimage/story/ScaleLogo.jpg

1. sudo mv ScaleLogo.jpg /usr/share/plymouth/themes/pix/splash.jpg

1. sudo vi /boot/config.txt

   -- add a line that says disable_splash=1 to the end

   -- save file

1. sudo vi /usr/share/plymouth/themes/pix/pix.script

   -- change theme_image to splash.jpg

   -- remove the two lines that have message_sprite at the beginning

   -- remove the line that starts with my-image within the message_callback function

   -- remove the line that starts with message_sprite within the message_callback function

   -- save file

1. sudo vi /boot/cmdline.txt

   -- replace tty1 with tty3

   -- at the end add splash quiet plymouth.ignore-serial-consoles logo.nologo vt.global_cursor_default=0

   -- save file

1. sudo apt-get install --no-install-recommends xserver-xorg x11-xserver-utils xinit openbox chromium-browser -y

1. sudo vi /etc/xdg/openbox/autostart

   -- replace the contents of the file with the following:

```
#!/bin/bash

xset s off
xset s noblank
xset dpms 0 0 0
xset -dpms

if [ -e /sys/class/input/mouse0 ]
then
	while true; do
		/usr/bin/reg.py
        done
else
	while true; do
		/usr/bin/web.py
	done
fi
```

-- save file

20. sudo vi /etc/rc.local

    -- before the exit 0 at the bottom add the following
    startx &

01. copy the two files [web.py](./scripts/web.py) and [reg.py](./scripts/reg.py) from the scripts `scripts` directory to /usr/bin/ on the pi using scp or a thumb drive.

    -- make sure they are executable

01. sudo apt-get install python-gtk2 python-webkit unclutter zabbix-agent -y

01. sudo vi /etc/xdg/openbox/rc.xml

    -- remove everything in the keyboard section

    -- remove everything except for <doubleClickTime> in the mouse section

01. sudo vi /etc/group

    -- remove pi from the sudo group

01. sudo rm /etc/sudoers.d/010_pi-nopasswd

01. sudo mv /etc/rc3.d/K01ssh /etc/rc3.d/S99ssh

01. change the password for pi and admin, save for sharing with team

01. reboot, test with a mouse and without one
