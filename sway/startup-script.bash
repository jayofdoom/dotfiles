#!/bin/bash

# Sway upstream does not set XDG_CURRENT_DESKTOP, so we have to get it into our environment
systemctl --user set-environment XDG_CURRENT_DESKTOP=sway
# Import items from our current environment into the systemctl user session.
# includes *DISPLAY and SWAYSOCK variables which populate as sway starts, and XDG_CURRENT_DESKTOP set above.
systemctl --user import-environment DISPLAY SWAYSOCK WAYLAND_DISPLAY XDG_CURRENT_DESKTOP
# Update dbus environments with the same neccessary variables
dbus-update-activation-environment --systemd DISPLAY SWAYSOCK XDG_CURRENT_DESKTOP=sway WAYLAND_DISPLAY

# Wait until the notification center is on the dbus, then autostart items
/usr/libexec/sway-systemd/wait-sni-ready && systemctl --user start sway-xdg-autostart.target

/usr/libexec/gsd-xsettings

# if fonts look weird, re-enable me
xrdb -load ~/.Xresources

