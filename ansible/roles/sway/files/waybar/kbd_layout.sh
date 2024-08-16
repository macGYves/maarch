#!/bin/sh

keyboard_flag() {
  while read -r layout; do
    if [ "$layout" = "English (UK)" ]; then
      layout_waybar="🇬🇧"
    elif [ "$layout" = "German" ]; then
      layout_waybar="🇩🇪"
    elif [ "$layout" = "Swedish" ]; then
      layout_waybar="🇸🇪"
    else
      layout_waybar="$layout"
    fi

    printf '%s\n' "$layout_waybar"
  done
}

# inspired by https://github.com/Alexays/Waybar/pull/85

swaymsg --type get_inputs --raw | \
  jq --raw-output \
    '[
        .[] |
          select(.type == "keyboard") |
          .xkb_active_layout_name |
	  select(contains("English \\(Colemak\\)") | not)
     ] |
     first 
    ' | keyboard_flag

swaymsg --type subscribe --monitor --raw '["input"]' | \
  jq --raw-output --unbuffered \
    '
      select(.change == "xkb_layout") |
        .input.xkb_active_layout_name
    ' | keyboard_flag
