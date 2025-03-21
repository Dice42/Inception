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