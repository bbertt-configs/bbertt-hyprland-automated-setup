# Hyprland Dotfiles Ansible Setup

This Ansible playbook automates setting up your Hyprland dotfiles and kitty terminal configuration.

## Requirements

- Ansible installed: `pip install ansible` or `sudo apt install ansible`

## Usage

Each machine profile is its own playbook; the `Makefile` is a shortcut for running one.
Targets prompt for your sudo password (`-K`) since some roles install packages.

| Command              | Playbook            | Roles                                    |
|----------------------|---------------------|------------------------------------------|
| `make arch-wsl`      | `arch-wsl.yml`      | zsh, lazyvim, tmux                       |
| `make arch-hyprland` | `playbook.yml`      | all roles below except `mouseless-solo`  |
| `make mouseless-solo`| `mouseless-solo.yml`| mouseless-solo                           |
| `make check`         | all                 | syntax check only                        |

```bash
make arch-wsl TAGS=zsh                         # only some roles of a profile
make arch-hyprland ARGS="-e hypr_repo_url=..."  # extra ansible-playbook flags
make arch-wsl BECOME=                          # no sudo prompt (passwordless sudo)
```

To add a role to a profile, add it to that profile's playbook, not the Makefile.

The `ansible-playbook` commands below work the same without `make`.

Run all roles:
```bash
ansible-playbook -i inventory.yml playbook.yml
```

Revert to the standalone jbensmann setup (separate playbook, see below):
```bash
ansible-playbook -i inventory.yml mouseless-solo.yml
```

Run a specific role only:
```bash
ansible-playbook -i inventory.yml playbook.yml --tags hyprlink
ansible-playbook -i inventory.yml playbook.yml --tags kitty
ansible-playbook -i inventory.yml playbook.yml --tags mouseless
ansible-playbook -i inventory.yml playbook.yml --tags mouseless-click
ansible-playbook -i inventory.yml playbook.yml --tags lazyvim
ansible-playbook -i inventory.yml playbook.yml --tags zsh -K
ansible-playbook -i inventory.yml playbook.yml --tags tmux -K
```

Or use role tags directly:
```bash
ansible-playbook -i inventory.yml playbook.yml -e "role=hyprlink"
ansible-playbook -i inventory.yml playbook.yml -e "role=kitty"
ansible-playbook -i inventory.yml playbook.yml -e "role=mouseless"
ansible-playbook -i inventory.yml playbook.yml -e "role=mouseless-click"
ansible-playbook -i inventory.yml playbook.yml -e "role=lazyvim"
ansible-playbook -i inventory.yml playbook.yml -e "role=zsh"
ansible-playbook -i inventory.yml playbook.yml -e "role=tmux"
```

## Roles

### hyprlink
Clones Hyprland dotfiles repository and creates a symbolic link from `~/.config/hypr` to the cloned dotfiles.

### kitty
Copies `kitty.conf` and `custom.conf` from `roles/kitty/files/` to `~/.config/kitty/`.

### mouseless
Deploys jbensmann/mouseless config — the CapsLock nav layer (`hjkl`/`np` -> arrow keys) and nothing else.

Mouse control now belongs to the `mouseless-click` role. This config is deliberately
narrowed to key remapping so the two can run together; see **Running both together** below.

### mouseless-click
Installs Sonuscape Mouseless (`mouseless.click`, app id `net.sonuscape.mouseless`) as a
user flatpak and registers a Hyprland `exec-once` autostart that launches it through a
wrapper script instead of `flatpak run` directly.

Adds both the `sonuscape` remote and `flathub` — the vendor repo hosts only the app and
its Locale extension, so the `org.gnome.Platform/50` runtime it depends on has to come
from Flathub or the install fails on an unresolved runtime.

Also installs two helper scripts to `~/.local/bin`: `mouseless-devices`, which detects
currently-connected physical keyboards via udev, and `mouseless-launch`, the autostart
wrapper that regenerates Sonuscape's keyboard-exclusion list immediately before every
launch. See **Why Mouseless excludes the physical keyboards** below for the full
mechanism — this replaced a one-shot, host-specific hardcoded list, and the two-pass
install (deploy once, then re-run after the app has created its config) it used to
require is no longer needed.

The app is proprietary and licensed per machine. **Activation is manual** and cannot be
automated: launch it, then choose *Activate* (not *Start Trial*).

### mouseless-solo
The original standalone jbensmann setup — CapsLock nav layer **and** the LeftCtrl mouse
layer, byte-identical bindings to the pre-Mouseless config.

**Not part of `playbook.yml`**, so a normal run can never overwrite the coexistence config.
It has its own entrypoint, `mouseless-solo.yml`. Mutually exclusive with `mouseless-click`
— see [Reverting to the standalone setup](#reverting-to-the-standalone-setup).

### lazyvim
Clones LazyVim configuration from a Git repository via SSH and backs up existing Neovim config.

### zsh
Recreates the zsh setup from LinuxBeginnings/Hyprland-Dots (its installer,
`Arch-Hyprland/install-scripts/zsh.sh`): Oh My Zsh with the `gnzh` theme (upstream uses `agnosterzak`),
`zsh-autosuggestions` and `zsh-syntax-highlighting`, `lsd` aliases, fzf Ctrl+R history,
and fastfetch on start. Then sets zsh as your login shell.

Installs packages with pacman, clones Oh My Zsh and the plugins over HTTPS, and copies
`.zshrc`, `.zprofile` and 7 extra themes from `roles/zsh/files/`. Existing dotfiles are
backed up with a timestamp suffix.

Differences from upstream:
- Git clones instead of `curl | sh`, so re-runs are safe. Oh My Zsh is never pulled by
  the role; it updates itself.
- Extra themes go in `~/.oh-my-zsh/custom/themes`, keeping the Oh My Zsh checkout clean.
- fastfetch uses Hyprland-Dots' `config-compact.jsonc` only if it exists, so shells
  don't error on machines without those dots (e.g. WSL).
- `mercurial` is not installed; nothing in the config uses it.
- Inside Windows Terminal (`$WT_SESSION` set), `.zshrc` swaps palette blue for One Half
  Dark's `#61AFEF` via OSC 4. Campbell's `#0037DA` is unreadable on a dark background, and
  gnzh draws the current directory in blue. Only the blue changes, so the terminal
  keeps its own background, and other terminals are untouched.
- Activates [mise](https://mise.jdx.dev) when `~/.local/bin/mise` exists.

The theme draws powerline glyphs, so the terminal needs a Nerd Font. On WSL that is set
in Windows Terminal, not in Linux.

### tmux
Installs tmux and [Oh my tmux!](https://github.com/gpakosz/.tmux) in its XDG layout:
the upstream `.tmux.conf` is cloned to `~/.local/share/tmux/oh-my-tmux` and symlinked to
`~/.config/tmux/tmux.conf`, and `roles/tmux/files/tmux.conf.local` is copied next to it.
An existing `tmux.conf` that isn't a symlink, or an existing `tmux.conf.local`, is backed
up first. Oh my tmux! is never pulled by the role.

Customizations in `tmux.conf.local`:
- Dracula colour palette, status bar at the top, no battery indicator.
- Windows and panes are numbered from 1.
- Unnamed sessions are numbered from 1: tmux has no base index for sessions, so a
  `session-created` hook renames them to the lowest free number.
- `prefix` + `s` sorts sessions by name and numbers its shortcut keys from 1, so
  `prefix` + `s` + `1` jumps to session 1.
- vi copy mode, `y` copies with `wl-copy`, mouse on.

tmux reads `~/.tmux.conf` before `~/.config/tmux/tmux.conf`; the role warns if one exists.

### keyd (retained, not run)
`roles/keyd/` is still in the tree but deliberately absent from `playbook.yml`. Key
remapping belongs to jbensmann/mouseless (the `mouseless` role); running keyd alongside it
would put two remappers in contention for the same exclusive `EVIOCGRAB` on the physical
keyboards, and whichever lost would simply be dead. Re-add the role entry to
`playbook.yml` if you ever want it back.

## What it does

1. Ensures `~/.config` directory exists
2. Clones the Hyprland dotfiles repository to `hypr/` folder
3. Backs up existing `~/.config/hypr` (if not already a symlink) to `.bak`
4. Creates symbolic link: `~/.config/hypr` → `hypr/`
5. Copies `kitty.conf` and `custom.conf` to `~/.config/kitty/`
6. Backs up existing kitty config files to `.bak`
7. Installs mouseless via yay (AUR)
8. Deploys mouseless config.yaml with the CapsLock nav layer
9. Restarts mouseless user service
10. Installs flatpak, adds the `flathub` and `sonuscape` remotes
11. Installs the `net.sonuscape.mouseless` flatpak (user scope)
12. Installs `mouseless-devices` and `mouseless-launch` to `~/.local/bin`, and adds the
    Mouseless `exec-once` autostart (via `mouseless-launch`) to Hyprland's
    `UserConfigs/Startup_Apps.conf`
13. Backs up existing nvim config to .bak
14. Optionally backs up nvim data directories
15. Clones lazyvim configs via SSH

## Running both together

Two separate programs handle the keyboard here, and they must not fight over it.
jbensmann/mouseless (`mouseless` role) does key remapping; Sonuscape Mouseless
(`mouseless-click` role) does mouse control and has no remapping capability of its own.

Four things make coexistence work. Only the last is about timing:

1. **Different jobs.** Neither duplicates the other's function.
2. **No keybinding collision.** Mouseless binds `toggle free mode: ControlLeft tap`, so
   jbensmann's old `leftctrl: tap-hold-next layer mouse` fired both on one tap. The
   `leftctrl` binding is gone. CapsLock is unbound in Mouseless, so the nav layer is free.
3. **`devicesExclude`** in the jbensmann config. Without it jbensmann reads Mouseless's
   own virtual devices and remaps the keystrokes Mouseless synthesizes — a feedback loop.
4. **Startup order.** `EVIOCGRAB` is exclusive: whichever starts first owns the physical
   keyboards. jbensmann must win, because without the grab it cannot suppress the original
   keystroke and `CapsLock+h` would emit both `h` and Left arrow. The `exec-once` therefore
   waits for jbensmann's uinput device instead of using a fixed sleep.

If jbensmann never starts, the wait loop times out after 30s and Mouseless grabs the
physical keyboards directly — you lose CapsLock arrows but keep mouse control. That is
deliberate; excluding the physical keyboards in Mouseless's own config would instead
leave it with no input at all.

### Why Mouseless excludes the physical keyboards

`EVIOCGRAB` is exclusive, and Mouseless grabs every device it classifies as a keyboard —
including ones hotplugged after startup. So replugging an external keyboard lets Mouseless
win it, and jbensmann can never get it back:

```
Keybord device has been removed: event13 (AULA-F75 5.0 KB Keyboard)
Detected new keyboard device:    event13 (AULA-F75 5.0 KB Keyboard)
Failed to grab keyboard device   event13: device or resource busy
```

Startup order alone cannot fix this, because the race reopens on every replug. The fix is
`excluded_input_devices` in Mouseless's own config: Mouseless then grabs only jbensmann's
`mouseless keyboard`, so jbensmann reliably owns the real hardware. Mouseless still sees
every keystroke, because jbensmann passes them through to that virtual device.

**The list is auto-generated, not hand-maintained.** `mouseless-devices` (installed to
`~/.local/bin`) walks `/dev/input/event*`, keeps the ones udev classifies as
`ID_INPUT_KEYBOARD=1`, and prints an `ids:VVVV:PPPP` entry for each — skipping
jbensmann's own virtual keyboard (vendor `4711`) and Sonuscape's own virtual devices
(vendor `736e`) so neither program ends up excluding itself. `mouseless-launch`, the
script the Hyprland autostart actually runs, calls it and merges the result into
`config.yaml` every time Sonuscape is about to launch:

- **Union, not overwrite.** Entries already in the file stay even if that keyboard is
  currently unplugged, so the list only ever grows to cover every keyboard this machine
  has ever had connected. An optional `~/.config/mouseless-click/extra-excludes` (see
  `mouseless_click_excluded_devices` below) is unioned in too, for pinning a device
  Ansible manages instead of leaving to auto-detection.
- **Fail-safe validation.** Before writing, any entry that would also match jbensmann's
  virtual keyboard — a bare substring of `mouseless keyboard`, or an `ids:` entry whose
  vendor/product use `0`/`0000` as a wildcard against `4711:0815` — is dropped and
  reported (stderr and `notify-send`). A sticky bad entry here would permanently leave
  Sonuscape with no input at all and be very hard to diagnose, so this never writes one.
- **Textual, not YAML-library, rewrite.** The merge edits only the
  `excluded_input_devices` key in place — as an inline `[]`, an existing block sequence,
  or appended if the key is missing — so every comment, key order, and setting made in
  Sonuscape's own config editor survives untouched.

**Why the merge happens in the launch wrapper, immediately before `flatpak run`:**
Sonuscape reads `config.yaml` once at startup and rewrites the whole file from memory
when it quits. That means editing it while Sonuscape is running is pointless — it will
be clobbered on exit — and editing it right after Ansible finishes is unsafe on a fresh
install, because the file doesn't exist until the app has run at least once. Pre-launch
is the only window that is both safe and guaranteed to exist.

The tradeoff is deliberate: with the physical keyboards excluded, Mouseless depends on
jbensmann running. If jbensmann dies, Mouseless has no input source. `SUPER+CTRL+ALT+R`
restarts jbensmann and is a Hyprland bind, so it keeps working in that state; if
Sonuscape isn't already running when it finishes, it also relaunches it (through
`mouseless-launch`, so the exclusion list gets regenerated).

#### Hotplugging a keyboard Mouseless has never seen before

Both programs watch for new devices — jbensmann via `fsnotify` on `/dev/input` — so
plugging in a keyboard for the first time after login is a race, exactly like the
startup race above:

- If jbensmann wins, everything is correct, and `mouseless-devices` will pick that
  keyboard up on Sonuscape's next launch.
- If Sonuscape wins, that one keyboard loses the CapsLock nav layer but keeps typing
  normally (Sonuscape re-emits keystrokes through its own virtual keyboard); the
  built-in keyboard is unaffected, and mouse control keeps working throughout.

Recovery: quit Sonuscape from its own UI (tap Left Shift, then Tab), then press
`SUPER+CTRL+ALT+R`. jbensmann restarts and grabs the new keyboard, the exclusion list
regenerates to include it, and Sonuscape relaunches automatically with the updated
list. Because the list accumulates, this can only happen once per keyboard.

### Role order matters

`mouseless-click` must run after `hyprlink`. `hyprlink` does a `force: true` git update of
the dotfiles repo, which would discard the autostart block; re-adding it afterwards keeps
the playbook convergent. The block is `blockinfile`-managed, so it is re-applied on every
run rather than duplicated.

## Reverting to the standalone setup

To go back to jbensmann/mouseless on its own, with the LeftCtrl mouse layer:

```bash
ansible-playbook -i inventory.yml mouseless-solo.yml
```

That deploys the original config, removes the Ansible-managed Mouseless autostart block
from Hyprland, and restarts the user service. The two configs are mutually exclusive: the
standalone one binds `leftctrl` and omits `devicesExclude`, so leaving Mouseless running
against it reintroduces both the ControlLeft collision and the device feedback loop.

A Mouseless instance already running stays running — the role only removes the autostart.
Quit it from its own UI (tap Left Shift, then Tab) or log out. **Do not kill it:**
signalling the flatpak can corrupt its config on shutdown.

Keep Mouseless's autostart anyway (not recommended):

```bash
ansible-playbook -i inventory.yml mouseless-solo.yml \
  -e mouseless_solo_remove_click_autostart=false
```

Return to the coexistence setup:

```bash
ansible-playbook -i inventory.yml playbook.yml --tags mouseless,mouseless-click
```

Neither direction uninstalls anything — they only swap the jbensmann config and toggle the
autostart, so switching back and forth is cheap.

## Variables

Override defaults in `roles/<role>/defaults/main.yml` or pass via CLI:

### hyprlink
- `hypr_repo_url` - Git repository URL (default: `https://github.com/bbertt-configs/bbertt-hyprland-dotfiles.git`)
- `hypr_install_path` - Where to clone dotfiles
- `hypr_config_target` - Symlink target (default: `~/.config/hypr`)

### kitty
- `kitty_config_target` - Target directory (default: `~/.config/kitty`)
- `kitty_backup_suffix` - Backup suffix for existing files (default: `.bak`)

### mouseless
- `mouseless_config_src` - Source path for config.yaml
- `mouseless_config_dest` - Target path for config.yaml (default: `~/.config/mouseless/config.yaml`)

### mouseless-click
- `mouseless_click_app_id` - Flatpak app id (default: `net.sonuscape.mouseless`)
- `mouseless_click_remote_name` / `mouseless_click_remote_url` - Sonuscape flatpak remote
- `mouseless_click_flathub_name` / `mouseless_click_flathub_url` - Flathub, for the GNOME runtime
- `mouseless_click_flatpak_method` - `user` or `system` (default: `user`)
- `mouseless_click_startup_file` - Hyprland startup config to manage (default: `~/.config/hypr/UserConfigs/Startup_Apps.conf`)
- `mouseless_click_wait_device` - uinput device to wait for (default: `mouseless keyboard`)
- `mouseless_click_wait_timeout` - seconds to wait before giving up (default: `30`)
- `mouseless_click_devices_script_src` / `_dest` - `mouseless-devices` helper (default dest: `~/.local/bin/mouseless-devices`)
- `mouseless_click_launch_script_src` / `_dest` - `mouseless-launch` autostart wrapper (default dest: `~/.local/bin/mouseless-launch`)
- `mouseless_click_refresh_script_src` / `_dest` - `mouseless-refresh` helper (default dest: `~/.local/bin/mouseless-refresh`)
- `mouseless_click_extra_excludes_file` - Always-on extra exclusions, unioned in by `mouseless-launch` (default: `~/.config/mouseless-click/extra-excludes`)
- `mouseless_click_excluded_devices` - Extra entries written to that file (default: `[]`, i.e. rely entirely on auto-detection). See **Why Mouseless excludes the physical keyboards** above.

Skip the package install where flatpak is provisioned elsewhere:
```bash
ansible-playbook -i inventory.yml playbook.yml --tags mouseless-click --skip-tags packages
```

### mouseless-solo
- `mouseless_solo_config_src` - Source path for the standalone config.yaml
- `mouseless_solo_config_dest` - Target path (default: `~/.config/mouseless/config.yaml`)
- `mouseless_solo_remove_click_autostart` - Remove Mouseless's Hyprland autostart (default: `true`)
- `mouseless_solo_startup_file` - Hyprland startup config to edit
- `mouseless_solo_click_marker` - `blockinfile` marker, must match the `mouseless-click` role

### lazyvim
- `lazyvim_repo_url` - Git repository URL (default: `git@github.com:bbertt-configs/lazyvim-configs.git`)
- `lazyvim_target` - Target directory (default: `~/.config/nvim`)
- `lazyvim_backup_suffix` - Backup suffix (default: `.bak`)
- `lazyvim_backup_data` - Whether to backup data directories (default: `true`)

**Note:** Requires SSH key loaded in agent (`ssh-add`) for git@github.com access.

### zsh
- `zsh_packages` - pacman packages to install
- `zsh_omz_repo_url` - Oh My Zsh repository (default: `https://github.com/ohmyzsh/ohmyzsh.git`)
- `zsh_omz_dir` - Oh My Zsh install path (default: `~/.oh-my-zsh`)
- `zsh_plugins` - list of `{name, repo}` cloned into `custom/plugins`
- `zsh_set_default_shell` - Make zsh the login shell (default: `true`)

### tmux
- `tmux_packages` - pacman packages to install (default: `tmux`, `git`)
- `tmux_omt_repo_url` - Oh my tmux! repository (default: `https://github.com/gpakosz/.tmux.git`)
- `tmux_omt_dir` - Oh my tmux! clone path (default: `~/.local/share/tmux/oh-my-tmux`)
- `tmux_config_dir` - tmux config directory (default: `~/.config/tmux`)

Example with custom repo:
```bash
ansible-playbook -i inventory.yml playbook.yml -e "hypr_repo_url=https://github.com/your-custom-repo.git"
```
