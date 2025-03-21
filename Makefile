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

logs:
	cd srcs && docker compose logs -f

re: clean up

fclean: clean
	-rm -rf /home/${USER}/data
	
flush:
	yes | docker system prune -a --volumes 

