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
ansible-playbook -i inventory.yml playbook.yml --tags mouseless
ansible-playbook -i inventory.yml playbook.yml --tags lazyvim
```

Or use role tags directly:
```bash
ansible-playbook -i inventory.yml playbook.yml -e "role=hyprlink"
ansible-playbook -i inventory.yml playbook.yml -e "role=kitty"
ansible-playbook -i inventory.yml playbook.yml -e "role=keyd"
ansible-playbook -i inventory.yml playbook.yml -e "role=mouseless"
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
Installs `mouseless` via yay (AUR) and configures mouse-less navigation with vim-style layers for keyboard-only control.

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
11. Deploys mouseless config.yaml with nav and mouse layers
12. Restarts mouseless user service
13. Backs up existing nvim config to .bak
14. Optionally backs up nvim data directories
15. Clones lazyvim configs via SSH

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
- `mouseless_package` - Package name to install (default: `mouseless`)
- `mouseless_config_src` - Source path for config.yaml
- `mouseless_config_dest` - Target path for config.yaml (default: `~/.config/mouseless/config.yaml`)

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
