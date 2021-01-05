
from libqtile.config import Key
from libqtile.lazy import lazy

mod = "mod4"
terminal = 'kitty'

core_keys = [
    # Switch between windows in current stack pane
    Key([mod], "k", lazy.layout.down(),
        desc="Move focus down in stack pane"),
    Key([mod], "j", lazy.layout.up(),
        desc="Move focus up in stack pane"),

    # Move windows up or down in current stack
    Key([mod, "control"], "k", lazy.layout.shuffle_down(),
        desc="Move window down in current stack "),
    Key([mod, "control"], "j", lazy.layout.shuffle_up(),
        desc="Move window up in current stack "),

    # Switch window focus to other pane(s) of stack
    Key([mod], "space", lazy.layout.next(),
        desc="Switch window focus to other pane(s) of stack"),

    # Swap panes of split stack
    Key([mod, "shift"], "space", lazy.layout.rotate(),
        desc="Swap panes of split stack"),

    # Toggle between split and unsplit sides of stack.
    # Split = all windows displayed
    # Unsplit = 1 window displayed, like Max layout, but still with
    # multiple stack panes
    Key([mod, "shift"], "Return", lazy.layout.toggle_split(),
        desc="Toggle between split and unsplit sides of stack"),

    # Toggle between different layouts as defined below
    Key([mod], "Tab", lazy.next_layout(), desc="Toggle between layouts"),
    Key([mod], "w", lazy.window.kill(), desc="Kill focused window"),

    Key([mod, "control"], "r", lazy.restart(), desc="Restart qtile"),
    Key([mod, "control"], "q", lazy.shutdown(), desc="Shutdown qtile"),
    Key([mod], "r", lazy.spawncmd(),
        desc="Spawn a command using a prompt widget"),
]

volume_keys = [
    Key([], "XF86AudioRaiseVolume", lazy.spawn(
        "pactl set-sink-volume @DEFAULT_SINK@ +5%"
    ), desc="Increase volume"),
    Key([], "XF86AudioLowerVolume", lazy.spawn(
        "pactl set-sink-volume @DEFAULT_SINK@ -5%"
    ), desc="Decrease volume"),
]

brightness_keys = [
    Key([], "XF86MonBrightnessUp", lazy.spawn(
        'light -A 5'
    ), desc="Brightness up"),
    Key([], "XF86MonBrightnessDown", lazy.spawn(
        'light -U 5'
    ), desc="Brightness down"),
]

program_keys = [
    Key([mod], "Return", lazy.spawn(terminal), desc="Launch terminal"),
    Key([mod], "Print", lazy.spawn("flameshot gui"),
        desc="Launch screenshot software"),
    Key([mod, "shift"], "f", lazy.spawn("qutebrowser"), desc="Launch browser"),
    Key([mod, "shift"], "v", lazy.spawn("code"), desc="Launch VSCode"),
    Key([mod, "shift"], "r", lazy.spawn("kitty --class 'file-manager' ranger"),
        desc="Launch Ranger"),
    Key([], "XF86AudioPlay", lazy.spawn("playerctl play-pause"), desc="Toggle the music player"),
    Key([], "XF86AudioPrev", lazy.spawn("playerctl previous"),
        desc="Play the previous music in queue"),
    Key([], "XF86AudioNext", lazy.spawn("playerctl next"), desc="Play the next music in queue")
]

keys = core_keys + program_keys + volume_keys + brightness_keys
