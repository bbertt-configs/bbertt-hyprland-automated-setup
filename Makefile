# Thin wrapper around the playbooks. Each target is one machine profile;
# which roles a profile gets is defined in its playbook, not here.
#
#   make arch-wsl                   # all roles for the profile
#   make arch-wsl TAGS=zsh          # only some roles
#   make arch-hyprland ARGS="-e hypr_repo_url=..."
#   make arch-wsl BECOME=           # skip the sudo prompt (passwordless sudo)

ANSIBLE   ?= ansible-playbook
INVENTORY ?= inventory.yml
BECOME    ?= --ask-become-pass
TAGS      ?=
ARGS      ?=

RUN = $(ANSIBLE) -i $(INVENTORY) $(BECOME) $(if $(TAGS),--tags $(TAGS)) $(ARGS)

.PHONY: help arch-wsl arch-hyprland mouseless-solo check

help:
	@echo "Targets:"
	@echo "  arch-wsl        Arch on WSL2: zsh, lazyvim          (arch-wsl.yml)"
	@echo "  arch-hyprland   Arch desktop with Hyprland, all roles (playbook.yml)"
	@echo "  mouseless-solo  Revert to standalone jbensmann/mouseless (mouseless-solo.yml)"
	@echo "  check           Syntax-check every playbook"
	@echo ""
	@echo "Variables: TAGS=zsh,lazyvim  ARGS='-e var=value'  BECOME= (no sudo prompt)"

arch-wsl:
	$(RUN) arch-wsl.yml

arch-hyprland:
	$(RUN) playbook.yml

mouseless-solo:
	$(RUN) mouseless-solo.yml

check:
	$(ANSIBLE) -i $(INVENTORY) --syntax-check arch-wsl.yml playbook.yml mouseless-solo.yml
