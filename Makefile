SRC      = srcs/docker-compose.yml
ENV_FILE = srcs/.env
SETUP    = srcs/requirements/tools/setup.sh

-include $(ENV_FILE)

DOMAIN = $(DOMAIN_NAME)

.PHONY: all secrets up down build stop ps restart logs clean fclean run re rerun config

all: secrets up

secrets:
	@$(SETUP) "$(ENV_FILE)"

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
	docker compose -f $(SRC) logs -f

clean:
	docker compose -f $(SRC) rm -af

fclean: stop clean
	docker system prune -af
	@if [ -d /home/vamachad/data ]; then \
		echo "Deleting volumes"; \
		sudo rm -rf /home/vamachad/data; \
	fi
	@if [ -d secrets ]; then \
		echo "Deleting secrets"; \
		rm -rf secrets; \
	fi

run: all
	@echo "Waiting for https://$(DOMAIN) to become reachable..."
	@for i in $(shell seq 1 60); do \
		if curl -sk --head https://$(DOMAIN) | grep -q "200 OK"; then \
			echo "\033[32m[OK]\033[0m  Site is up at https://$(DOMAIN)"; \
			exit 0; \
		fi; \
		sleep 2; \
	done; \
	echo "\033[31m[ERROR]\033[0m  Site did not become ready within 60s" >&2; \
	exit 1

re: fclean all
rerun: re run

