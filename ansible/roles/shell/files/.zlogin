# If running from tty1 start sway
if [ "$(tty)" = "/dev/tty1" ]; then
	export DESKTOP_SESSION=gnome

	# Fixes blank screen issues with java applications
	export _JAVA_AWT_WM_NONREPARENTING=1
	exec sway
fi
