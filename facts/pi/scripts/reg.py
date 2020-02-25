#!/usr/bin/env python

import gtk
import webkit
import socket
import fcntl
import struct

def get_ip_address(ifname):
    s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
    return socket.inet_ntoa(fcntl.ioctl(
        s.fileno(),
        0x8915,  # SIOCGIFADDR
        struct.pack('256s', ifname[:15])
    )[20:24])

ip = get_ip_address('eth0')  
ip = ip.split(".")
ip = 'SCALE:'+ip[3]


def close_func(webview):
 # Byebye!
 gtk.main_quit()
 return True

def create_func(webview, webframe):
 # Return the original webview, and now it can be closed...
 return webview

webview = webkit.WebView()
webview.get_settings().props.user_agent += ip
webview.get_settings().props.enable_private_browsing = True
webview.get_settings().props.enable_default_context_menu = False
webview.get_settings().props.javascript_can_open_windows_automatically = True

webview.connect('close-web-view', close_func)
webview.connect('create-web-view', create_func)
webview.open('https://register.socallinuxexpo.org/reg6/kiosk/')


scroller = gtk.ScrolledWindow()
scroller.add(webview)

win = gtk.Window()
win.fullscreen()
win.add(scroller)
win.show_all()

gtk.main()
