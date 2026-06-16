# iotdata-depend — helpers wrapping the git-submodule incantations.
# Run `make` (or `make help`) for the list. Submodule paths are read straight
# from .gitmodules, so adding/removing a submodule needs no edit here.

SUBMODULES := $(shell git config --file .gitmodules --get-regexp '\.path$$' | awk '{print $$2}')

.DEFAULT_GOAL := help
.PHONY: help init status update commit bump sync foreach

help: ## Show this help
	@echo "iotdata-depend — submodule helpers"
	@echo
	@echo "submodules: $(SUBMODULES)"
	@echo
	@awk 'BEGIN{FS=":.*## "} /^[a-zA-Z_-]+:.*## /{printf "  make %-8s %s\n",$$1,$$2}' $(MAKEFILE_LIST)

init: ## Populate submodules after a fresh clone (init + checkout pinned commits)
	git submodule update --init --recursive

status: ## Show each submodule's pinned commit and working-tree state
	@git submodule status --recursive

update: ## Move every submodule checkout to its upstream default-branch HEAD
	git submodule update --remote --recursive
	@echo
	@echo "Submodules moved to upstream HEAD. Review with 'make status',"
	@echo "then record the new pins with 'make commit' (or just 'make bump')."

commit: ## Record the current submodule pins as a commit (no-op if unchanged)
	@if git diff --quiet --ignore-submodules=none -- $(SUBMODULES); then \
		echo "No submodule pin changes to commit."; \
	else \
		git add $(SUBMODULES) && git commit -m "Bump submodule pins to upstream HEAD"; \
	fi

bump: update commit ## update + commit: pull all submodules to upstream HEAD and pin

sync: ## Apply .gitmodules URL changes to the local submodule config
	git submodule sync --recursive

foreach: ## Run CMD in each submodule, e.g. `make foreach CMD='git log -1'`
	@test -n "$(CMD)" || { echo "usage: make foreach CMD='<shell command>'"; exit 2; }
	git submodule foreach --recursive '$(CMD)'
