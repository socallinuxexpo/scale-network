# Kermit

Collection of kermit configs so tech team member never have to remember baud rates
and flowcontrol settings

## Config

Make sure your user is added to the `dialer` group so that you dont have to `sudo`
to use the console devices

To make a connection using kermit:

```
kermit <type>.kermit
```

Where <type> is one of the files in this directory depending on the type of
device you are connecting to.

## Controls

To get back to your own system, you must type the "escape character", which is
Control-Backslash (^\\) unless you have changed it with the SET ESCAPE command,
followed by a single-character command, such as C for "close connection".
Single-character commands may be entered in upper or lower case.  They include:

```
  C     Return to C-Kermit.  If you gave an interactive CONNECT command, return
        to the C-Kermit prompt.  If you gave a -c or -n option on the command
        line, close the connection and return to the system prompt.
  B     Send a BREAK signal.
  0     (zero) send a null.
  S     Give a status report about the connection.
  H     Hangup the phone.
  !     Escape to the system command processor "under" Kermit.  Exit or logout
        to return to your CONNECT session.
  Z     Suspend Kermit (UNIX only).
  \nnn  A character in backslash-code form.
  ^\    Send Control-Backslash itself (whatever you have defined the escape
        character to be, typed twice in a row sends one copy of it).
```
