# iotdata-depend — helpers wrapping the git-submodule incantations.
# Run `make` (or `make help`) for the list. Submodule paths are read straight
# from .gitmodules, so adding/removing a submodule needs no edit here.

SUBMODULES := $(shell git config --file .gitmodules --get-regexp '\.path$$' | awk '{print $$2}')

.DEFAULT_GOAL := help
.PHONY: help init status attach update commit bump sync foreach _assert-clean

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

# Submodules check out in DETACHED HEAD — that is normal for `submodule update`, and
# it is also the trap: commits made there sit on no branch, so `git push` has nothing
# to push and the pin cannot be published. (A `branch =` key in .gitmodules does NOT
# help: the checkout still lands detached on the remote-tracking ref.) Run this BEFORE
# editing inside a submodule, or afterwards to rescue commits already stranded.
# It refuses rather than guesses when the branch is not an ancestor of HEAD, because
# `checkout -B` force-resets and would otherwise discard commits.
attach: ## Re-attach detached submodules to their branch (run before editing in one)
	@for s in $(SUBMODULES); do \
	  [ -e "$$s/.git" ] || { echo "  $$s: not initialised, skipping (try 'make init')"; continue; }; \
	  cur=$$(git -C "$$s" symbolic-ref --short -q HEAD || true); \
	  if [ -n "$$cur" ]; then echo "  $$s: already on '$$cur'"; continue; fi; \
	  n=$$(git config -f .gitmodules --name-only --get-regexp '^submodule\..*\.path$$' "^$$s$$" 2>/dev/null | sed 's/^submodule\.//; s/\.path$$//'); \
	  b=$$(git config -f .gitmodules --get "submodule.$$n.branch" 2>/dev/null || true); \
	  [ -n "$$b" ] || b=$$(git -C "$$s" symbolic-ref --short -q refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||'); \
	  [ -n "$$b" ] || b=main; \
	  if ! git -C "$$s" show-ref --verify --quiet "refs/heads/$$b"; then \
	    git -C "$$s" checkout -q -b "$$b" && echo "  $$s: created '$$b' at HEAD and checked out"; \
	  elif git -C "$$s" merge-base --is-ancestor "refs/heads/$$b" HEAD; then \
	    if [ "$$(git -C "$$s" rev-parse "refs/heads/$$b")" = "$$(git -C "$$s" rev-parse HEAD)" ]; then \
	      git -C "$$s" checkout -q "$$b" && echo "  $$s: attached to '$$b' (already at HEAD)"; \
	    else \
	      git -C "$$s" checkout -q -B "$$b" HEAD && echo "  $$s: fast-forwarded '$$b' to HEAD and attached — commits rescued, now 'git -C $$s push'"; \
	    fi; \
	  else \
	    echo "  $$s: REFUSED — '$$b' ($$(git -C "$$s" rev-parse --short refs/heads/$$b)) is not an ancestor of HEAD ($$(git -C "$$s" rev-parse --short HEAD))."; \
	    echo "        Attaching would discard commits. Resolve by hand: git -C $$s log --oneline $$b..HEAD"; \
	    continue; \
	  fi; \
	  git -C "$$s" rev-parse --verify -q "refs/remotes/origin/$$b" >/dev/null 2>&1 && \
	    git -C "$$s" branch -q --set-upstream-to="origin/$$b" "$$b" >/dev/null 2>&1 || true; \
	done

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
