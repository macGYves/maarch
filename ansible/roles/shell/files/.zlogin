# If running from tty1 start sway
if [ "$(tty)" = "/dev/tty1" ]; then
	export DESKTOP_SESSION=gnome
	exec sway
fi
