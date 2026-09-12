# hyprchroma

**Change your Omarchy theme once and let the rest of your desktop follow.**

hyprchroma carries the active Omarchy palette into the applications that do not
follow it on their own: GTK 3, GTK 4 and libadwaita, GNOME settings, Qt and KDE
Frameworks, Dark Reader in the default browser, and Pear Desktop / YouTube
Music.

It runs as a user service. Set a theme and everything is rewritten immediately;
applications that cannot be restyled while open are listed so you can restart
them when you feel like it, and the ones that must be closed first — KDE
applications holding `kdeglobals`, a browser holding Dark Reader's database —
are applied the moment they exit.

For the Omarchy bar widget and toggle panel, see
[omarchroma](https://github.com/NobleDoodle/omarchroma), which installs this
package for you if it is missing.

## Install

```bash
omarchy pkg aur add hyprchroma
systemctl --user enable --now hyprchromad.service
```

The daemon installs Omarchy's `theme-set` and `font-set` hooks into your own
configuration on first start, so a theme change applies at once rather than on
the next poll.

## Use

```bash
hyprchroma                        # sync only what changed
hyprchroma --force                # rewrite everything
hyprchroma --target=gtk --force   # gtk | qt-kde | dark-reader | pear
hyprchroma --target=pear --set-enabled=false   # turn one off and revert it
hyprchroma restore --stock        # hand everything back to Omarchy's defaults
hyprchroma restore --captured     # put back what was on disk before first run
```

Turning a framework off reverts it to the values captured before hyprchroma
first touched it, rather than leaving its colours in place with syncing merely
stopped. The snapshot is kept, so turning it back on re-syncs from the same
baseline.

## Where the palette comes from

hyprchroma needs a palette. It does not care who provides one.

**On Omarchy** it is first class and automatic: the daemon installs Omarchy's
`theme-set` and `font-set` hooks, and `omarchy theme set` applies everything at
once. Omarchy's own resolver answers, so its alias cascade and derived shades
are exactly what Omarchy computes rather than an approximation made here.

**Anywhere else** — plain Hyprland, a Quickshell setup, whatever you have
built — write a palette file and sync when you want to:

```bash
hyprchroma palette --template > ~/.config/hyprchroma/palette.toml
$EDITOR ~/.config/hyprchroma/palette.toml
hyprchroma --force
```

Twenty `#rrggbb` keys, all required, named in the template. `mode` is optional
and inferred from the background's luminance. The file wins over Omarchy when
both are present, so it is also how you override a theme you otherwise like.

`hyprchroma palette --capture` writes the currently resolved palette into that
file. On Omarchy that is the way to pin a theme, or to carry one to a machine
without Omarchy: Omarchy derives several keys rather than storing them, so a
theme's own `colors.toml` copied across would be missing some, and capturing
resolves them first.

`hyprchroma palette --source` says which is in use.

## Requirements

**A palette source.** Omarchy, or a palette file as above. The daemon says so
and stops without changing anything when there is neither.

| | Needed for | Without it |
|---|---|---|
| `hyprland` | the event stream the daemon watches | the daemon restarts until it appears |
| `jq`, `python3` | settings, status and every JSON write | required |
| `adw-gtk-theme` | GTK 3 applications | GTK 3 apps will not follow the theme |
| `python-plyvel` | Dark Reader in Chromium browsers | Dark Reader is not themed there |
| Dark Reader | browser page theming | nothing to theme; everything else works |

**hyprchroma never installs Dark Reader.** Install it yourself from the
[Chrome Web Store](https://chromewebstore.google.com/detail/dark-reader/eimadpbcbfnmbkopoojfekhnkhdbieeh)
or [Firefox Add-ons](https://addons.mozilla.org/firefox/addon/darkreader/); it
is themed from the next sync once it is there.

## Privileges

None. The daemon runs as your user, writes only inside your own home
directory, and runs no privileged command. Installing the package is the only
step that needs root, and that is `pacman` doing it, not this code.

Commands are resolved from a fixed set of directories checked to be root-owned
and unwritable by anyone else, and every file it writes is created and renamed
relative to a directory descriptor it has verified, so nothing on the path can
be redirected between the check and the write.

## Files written

```text
~/.config/gtk-3.0/            ~/.local/share/color-schemes/Hyprchroma.colors
~/.config/gtk-4.0/            ~/.local/share/hyprchroma/
~/.config/kdeglobals          ~/.local/state/hyprchroma/
~/.config/*rc                 (only the [UiSettings] ColorScheme key)
~/.config/YouTube Music/hyprchroma.css
~/.config/omarchy/hooks/{theme-set,font-set}.d/hyprchroma
```

Unrelated GTK, KDE, Pear Desktop and browser settings are preserved. A state
directory left by Omarchroma, the single-repo predecessor, is migrated on first
start so the captured baseline is not lost.

## Remove

```bash
hyprchroma restore --stock        # or --captured
systemctl --user disable --now hyprchromad.service
omarchy pkg drop hyprchroma
```

## License

[MIT](LICENSE)
