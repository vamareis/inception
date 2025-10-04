SHELL = /bin/bash

# Paths
SRC      = srcs/docker-compose.yml
ENV_FILE = srcs/.env
SETUP    = srcs/requirements/tools/setup.sh

# Read DOMAIN_NAME from .env (used by "run")
DOMAIN = $(shell grep -E '^DOMAIN_NAME=' $(ENV_FILE) | cut -d= -f2)

.PHONY: all secrets up down build stop ps restart logs clean fclean run re rerun config

# Default flow: ensure secrets exist (idempotent), then bring stack up (build+detach)
all: secrets up

# Idempotent secret generation and any lightweight preflight (no stdout leaks)
secrets:
	@$(SETUP) "$(ENV_FILE)"
	
# Compose actions
up:
	docker compose -f $(SRC) up -d --build

down:
	docker compose -f $(SRC) down

build:
	docker compose -f $(SRC) build

stop:
	docker compose -f $(SRC) stop

ps:
	docker compose -f $(SRC) ps -a

restart:
	docker compose -f $(SRC) restart

logs:
	# tail logs; do not fail on Ctrl-C
	-docker compose -f $(SRC) logs -f

clean:
	docker compose -f $(SRC) rm -af

# Be careful: this prunes globally, not just the project.
fclean: stop clean
	docker system prune -af
	@if [ -d /home/vamachad/data ]; then \
	 echo "\nInput sudo password to delete volumes"; \
	 sudo rm -rf /home/vamachad/data; \
	fi
	@if [ -d secrets ]; then \
	 echo "Deleting secrets"; \
	 rm -rf secrets; \
	fi

# Quick open hint (kept light & robust)
run: all
	@echo "Open: https://$(DOMAIN)"

# Utilities
re: fclean all
rerun: re run

config:
	docker compose -f $(SRC) config >/dev/null

