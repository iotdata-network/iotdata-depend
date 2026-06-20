# iotdata-depend — helpers wrapping the git-submodule incantations.
# Run `make` (or `make help`) for the list. Submodule paths are read straight
# from .gitmodules, so adding/removing a submodule needs no edit here.

SUBMODULES := $(shell git config --file .gitmodules --get-regexp '\.path$$' | awk '{print $$2}')

.DEFAULT_GOAL := help
.PHONY: help init status update commit bump sync foreach _assert-clean

# Override the pin commit message:  make bump MSG="..."
MSG ?= update submodule pins

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

# Guard: a submodule must be committed AND pushed before the parent pins it. Otherwise
# `update`/`bump` orphan uncommitted edits (via `submodule update --remote`) or pin a SHA
# nobody else can fetch — and the old `commit` failed with a cryptic "nothing to commit".
# This turns that footgun into a clear, actionable message. Phase 1 (commit+push the
# submodule itself) is yours to do; this just refuses phase 2 (pin) until it's done.
_assert-clean:
	@bad=0; for s in $(SUBMODULES); do \
	  st=""; \
	  [ -z "$$(git -C "$$s" status --porcelain -uno 2>/dev/null)" ] || st="uncommitted"; \
	  [ -n "$$(git -C "$$s" branch -r --contains HEAD 2>/dev/null)" ] || st="$${st:+$$st,}unpushed"; \
	  [ -z "$$st" ] || { echo "  $$s: $$st"; bad=1; }; \
	done; \
	[ "$$bad" = 0 ] || { \
	  echo "iotdata-depend: submodule(s) above aren't ready to pin. Commit + push each first:"; \
	  echo "    git -C <sub> checkout main        # only if it's in detached HEAD"; \
	  echo "    git -C <sub> add -A && git -C <sub> commit -m '...' && git -C <sub> push"; \
	  echo "  then re-run 'make bump'."; \
	  exit 1; \
	}

update: _assert-clean ## Move every submodule checkout to its upstream default-branch HEAD
	git submodule update --remote --recursive
	@echo
	@echo "Submodules moved to upstream HEAD. Review with 'make status',"
	@echo "then record the new pins with 'make commit' (or just 'make bump')."

commit: _assert-clean ## Record the current submodule pins as a commit (no-op if unchanged)
	@if git diff --quiet --ignore-submodules=none -- $(SUBMODULES); then \
		echo "No submodule pin changes to commit."; \
	else \
		git add $(SUBMODULES) && git commit -m "$(MSG)"; \
		echo "Pinned. Now publish the parent:  git push"; \
	fi

bump: update commit ## update + commit: pull all submodules to upstream HEAD and pin

sync: ## Apply .gitmodules URL changes to the local submodule config
	git submodule sync --recursive

foreach: ## Run CMD in each submodule, e.g. `make foreach CMD='git log -1'`
	@test -n "$(CMD)" || { echo "usage: make foreach CMD='<shell command>'"; exit 2; }
	git submodule foreach --recursive '$(CMD)'
