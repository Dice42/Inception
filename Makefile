all: up logs 

up:
	mkdir -p /home/${USER}/data/mariadb
	mkdir -p /home/${USER}/data/wordpress
	cd srcs && docker compose up -d

down:
	cd srcs && docker compose down

build:
	cd srcs && docker compose build

clean: down
	docker rmi -f $(shell docker images -q)

re: clean up

logs:
	cd srcs && docker compose logs -f

fclean:
	- yes | docker system prune -a --volumes
	- rm -rf /home/${USER}/data

.PHONY: up down build clean re logs 