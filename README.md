# Hyprland Dotfiles Ansible Setup

This Ansible playbook automates setting up your Hyprland dotfiles and kitty terminal configuration.

## Requirements

- Ansible installed: `pip install ansible` or `sudo apt install ansible`

## Usage

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
ansible-playbook -i inventory.yml playbook.yml --tags keyd
ansible-playbook -i inventory.yml playbook.yml --tags mouseless
ansible-playbook -i inventory.yml playbook.yml --tags mouseless-click
ansible-playbook -i inventory.yml playbook.yml --tags lazyvim
```

Or use role tags directly:
```bash
ansible-playbook -i inventory.yml playbook.yml -e "role=hyprlink"
ansible-playbook -i inventory.yml playbook.yml -e "role=kitty"
ansible-playbook -i inventory.yml playbook.yml -e "role=keyd"
ansible-playbook -i inventory.yml playbook.yml -e "role=mouseless"
ansible-playbook -i inventory.yml playbook.yml -e "role=mouseless-click"
ansible-playbook -i inventory.yml playbook.yml -e "role=lazyvim"
```

## Roles

### hyprlink
Clones Hyprland dotfiles repository and creates a symbolic link from `~/.config/hypr` to the cloned dotfiles.

### kitty
Copies `kitty.conf` and `custom.conf` from `roles/kitty/files/` to `~/.config/kitty/`.

### keyd
Installs `keyd` via yay (AUR) and configures global vim-style navigation by holding Caps Lock as a modifier layer.

### mouseless
Deploys jbensmann/mouseless config — the CapsLock nav layer (`hjkl`/`np` -> arrow keys) and nothing else.

Mouse control now belongs to the `mouseless-click` role. This config is deliberately
narrowed to key remapping so the two can run together; see **Running both together** below.

### mouseless-click
Installs Sonuscape Mouseless (`mouseless.click`, app id `net.sonuscape.mouseless`) as a
user flatpak and registers a Hyprland `exec-once` autostart.

Adds both the `sonuscape` remote and `flathub` — the vendor repo hosts only the app and
its Locale extension, so the `org.gnome.Platform/50` runtime it depends on has to come
from Flathub or the install fails on an unresolved runtime.

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

## What it does

1. Ensures `~/.config` directory exists
2. Clones the Hyprland dotfiles repository to `hypr/` folder
3. Backs up existing `~/.config/hypr` (if not already a symlink) to `.bak`
4. Creates symbolic link: `~/.config/hypr` → `hypr/`
5. Copies `kitty.conf` and `custom.conf` to `~/.config/kitty/`
6. Backs up existing kitty config files to `.bak`
7. Installs keyd via yay (AUR)
8. Deploys keyd default.conf with vim motion layer
9. Enables and starts keyd service
10. Installs mouseless via yay (AUR)
11. Deploys mouseless config.yaml with the CapsLock nav layer
12. Restarts mouseless user service
13. Installs flatpak, adds the `flathub` and `sonuscape` remotes
14. Installs the `net.sonuscape.mouseless` flatpak (user scope)
15. Adds the Mouseless `exec-once` autostart to Hyprland's `UserConfigs/Startup_Apps.conf`
16. Backs up existing nvim config to .bak
17. Optionally backs up nvim data directories
18. Clones lazyvim configs via SSH

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

### keyd
- `keyd_package` - Package name to install (default: `keyd`)
- `keyd_config_src` - Source path for default.conf
- `keyd_config_dest` - Target path for default.conf (default: `/etc/keyd/default.conf`)

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

Example with custom repo:
```bash
ansible-playbook -i inventory.yml playbook.yml -e "hypr_repo_url=https://github.com/your-custom-repo.git"
```
