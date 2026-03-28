# Hyprland Dotfiles Ansible Setup

This Ansible playbook automates setting up your Hyprland dotfiles by cloning the repository and creating a symbolic link from `~/.config/hypr` to the cloned dotfiles.

## Requirements

- Ansible installed: `pip install ansible` or `sudo apt install ansible`

## Usage

1. Run the playbook:
   ```bash
   cd ansible
   ansible-playbook -i inventory.yml playbook.yml
   ```

## What it does

1. Ensures `~/.config` directory exists
2. Clones the Hyprland dotfiles repository to `hypr/` folder
3. Backs up existing `~/.config/hypr` (if not already a symlink) to `.bak`
4. Creates symbolic link: `~/.config/hypr` → `hypr/`

## Variables

Override defaults in `roles/hyprlink/defaults/main.yml` or pass via CLI:
- `hypr_repo_url` - Git repository URL (default: `https://github.com/bbertt-configs/bbertt-hyprland-dotfiles.git`)
- `hypr_install_path` - Where to clone dotfiles
- `hypr_config_target` - Symlink target (default: `~/.config/hypr`)

Example with custom repo:
```bash
ansible-playbook -i inventory.yml playbook.yml -e "hypr_repo_url=https://github.com/your-custom-repo.git"
```
