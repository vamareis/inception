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
	@echo "Open: https://$(DOMAIN)"

re: fclean all
rerun: re run
