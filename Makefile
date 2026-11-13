SHELL := /bin/bash
.DEFAULT_GOAL := help
.PHONY: help init build up down stop restart recreate shell logs ps doctor smoke test-persistence backup restore update-opencode update-tools clean-cache config-path verify publish-github

help:
	@echo 'make init                 Create .env and workspace (first time)'
	@echo 'make build                Build selected DEVKIT_PROFILE'
	@echo 'make up                   Build and start OpenCode'
	@echo 'make down                 Stop and remove containers (preserves volumes)'
	@echo 'make stop                 Stop service'
	@echo 'make restart              Restart service'
	@echo 'make recreate             Force recreate without deleting volumes'
	@echo 'make shell                Open shell in existing container'
	@echo 'make logs                 Follow logs'
	@echo 'make doctor               Validate local setup'
	@echo 'make smoke                Run runtime tool checks'
	@echo 'make test-persistence     Test config/data/workspace survive recreation'
	@echo 'make backup               Stop and archive persistent volumes'
	@echo 'make restore FILE=...     Restore trusted backup (interactive)'
	@echo 'make update-opencode VERSION=2.2.8'
	@echo 'make update-tools PNPM=10.34.9 AGENT_BROWSER=0.42.0'
	@echo 'make clean-cache          Remove only package caches (service stopped)'
	@echo 'make config-path          Show location of OpenCode user config'
	@echo 'make publish-github       Interactive public GitHub publish (requires gh)'

init:
	@bash scripts/init.sh

build:
	docker compose build --pull

up:
	docker compose up -d --build --wait

down:
	docker compose down

stop:
	docker compose stop

restart:
	docker compose restart

recreate:
	docker compose up -d --wait --force-recreate --no-deps opencode

shell:
	docker compose exec opencode bash

logs:
	docker compose logs --follow --tail=100 opencode

ps:
	docker compose ps

doctor:
	@bash scripts/doctor.sh

smoke:
	@bash scripts/smoke.sh

test-persistence:
	@bash scripts/persistence-test.sh

backup:
	@bash scripts/backup.sh

restore:
	@test -n "$(FILE)" || (echo 'Usage: make restore FILE=backups/file.tar.gz' && exit 2)
	@bash scripts/restore.sh '$(FILE)'

update-opencode:
	@test -n "$(VERSION)" || (echo 'Usage: make update-opencode VERSION=2.2.8' && exit 2)
	@sed -i.bak 's/^OPENCODE_VERSION=.*/OPENCODE_VERSION=$(VERSION)/' .env && rm -f .env.bak
	@$(MAKE) up

update-tools:
	@test -n "$(PNPM)$(AGENT_BROWSER)" || (echo 'Usage: make update-tools PNPM=x AGENT_BROWSER=y' && exit 2)
	@if test -n "$(PNPM)"; then sed -i.bak 's/^PNPM_VERSION=.*/PNPM_VERSION=$(PNPM)/' .env; fi
	@if test -n "$(AGENT_BROWSER)"; then sed -i.bak 's/^AGENT_BROWSER_VERSION=.*/AGENT_BROWSER_VERSION=$(AGENT_BROWSER)/' .env; fi
	@rm -f .env.bak
	@$(MAKE) up

clean-cache:
	@docker compose stop opencode
	@docker compose run --rm --no-deps --entrypoint sh opencode -ec \
	  'rm -rf "$$HOME/.npm/_cacache" "$$HOME/.cache/pnpm" "$$HOME/.cache/node-gyp"'
	@echo 'Only known caches cleared; OpenCode data/config and workspace retained.'

config-path:
	@echo '/home/devkit/.config/opencode/opencode.json (devkit-opencode volume, or OPENCODE_CONFIG_DIR bind)'

verify:
	@python3 -m unittest discover -s tests -v

publish-github:
	@bash scripts/publish-github.sh
