# Hyprland Dotfiles Ansible Setup

This Ansible playbook automates setting up your Hyprland dotfiles and kitty terminal configuration.

## Requirements

- Ansible installed: `pip install ansible` or `sudo apt install ansible`

## Usage

Run all roles:
```bash
ansible-playbook -i inventory.yml playbook.yml
```

Run a specific role only:
```bash
ansible-playbook -i inventory.yml playbook.yml --tags hyprlink
ansible-playbook -i inventory.yml playbook.yml --tags kitty
ansible-playbook -i inventory.yml playbook.yml --tags keyd
```

Or use role tags directly:
```bash
ansible-playbook -i inventory.yml playbook.yml -e "role=hyprlink"
ansible-playbook -i inventory.yml playbook.yml -e "role=kitty"
ansible-playbook -i inventory.yml playbook.yml -e "role=keyd"
```

## Roles

### hyprlink
Clones Hyprland dotfiles repository and creates a symbolic link from `~/.config/hypr` to the cloned dotfiles.

### kitty
Copies `kitty.conf` and `custom.conf` from `roles/kitty/files/` to `~/.config/kitty/`.

### keyd
Installs `keyd` via yay (AUR) and configures global vim-style navigation by holding Caps Lock as a modifier layer.

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

Example with custom repo:
```bash
ansible-playbook -i inventory.yml playbook.yml -e "hypr_repo_url=https://github.com/your-custom-repo.git"
```
