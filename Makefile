# SnappyMail Docker Makefile
# Common operations for managing the SnappyMail Docker container

CONTAINER_NAME ?= snappymail
IMAGE_NAME ?= snappymail
PORT ?= 8080
DATA_VOLUME ?= snappymail_data

.PHONY: help build start stop restart logs shell clean backup

# Default target
help: ## Show this help message
	@echo "SnappyMail Docker Commands:"
	@echo "=========================="
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'

build: ## Build the Docker image
	docker build -t $(IMAGE_NAME) .

start: ## Start SnappyMail container
	@if docker ps -a --format '{{.Names}}' | grep -q "^$(CONTAINER_NAME)$$"; then \
		echo "Stopping existing container..."; \
		docker stop $(CONTAINER_NAME) >/dev/null 2>&1 || true; \
		docker rm $(CONTAINER_NAME) >/dev/null 2>&1 || true; \
	fi
	docker run -d \
		--name $(CONTAINER_NAME) \
		-p $(PORT):80 \
		-v $(DATA_VOLUME):/var/www/html/data \
		--restart unless-stopped \
		$(IMAGE_NAME)
	@echo "SnappyMail is starting..."
	@echo "Web interface: http://localhost:$(PORT)"
	@echo "Admin panel: http://localhost:$(PORT)/?admin"

stop: ## Stop SnappyMail container
	docker stop $(CONTAINER_NAME)
	docker rm $(CONTAINER_NAME)

restart: ## Restart SnappyMail container
	docker restart $(CONTAINER_NAME)

logs: ## Show container logs
	docker logs -f $(CONTAINER_NAME)

shell: ## Open shell in running container
	docker exec -it $(CONTAINER_NAME) /bin/bash

clean: ## Remove container and image (keeps volumes)
	@if docker ps -a --format '{{.Names}}' | grep -q "^$(CONTAINER_NAME)$$"; then \
		docker stop $(CONTAINER_NAME) >/dev/null 2>&1 || true; \
		docker rm $(CONTAINER_NAME) >/dev/null 2>&1 || true; \
	fi
	@if docker images --format '{{.Repository}}' | grep -q "^$(IMAGE_NAME)$$"; then \
		docker rmi $(IMAGE_NAME) >/dev/null 2>&1 || true; \
	fi

clean-all: ## Remove everything including volumes (DANGER!)
	@echo "This will remove ALL data including emails and configurations!"
	@read -p "Are you sure? [y/N]: " confirm && [ "$$confirm" = "y" ] || exit 1
	@if docker ps -a --format '{{.Names}}' | grep -q "^$(CONTAINER_NAME)$$"; then \
		docker stop $(CONTAINER_NAME) >/dev/null 2>&1 || true; \
		docker rm $(CONTAINER_NAME) >/dev/null 2>&1 || true; \
	fi
	@if docker images --format '{{.Repository}}' | grep -q "^$(IMAGE_NAME)$$"; then \
		docker rmi $(IMAGE_NAME) >/dev/null 2>&1 || true; \
	fi
	@if docker volume ls --format '{{.Name}}' | grep -q "^$(DATA_VOLUME)$$"; then \
		docker volume rm $(DATA_VOLUME) >/dev/null 2>&1 || true; \
	fi

backup: ## Create backup of SnappyMail data
	@mkdir -p ./backups
	docker run --rm \
		-v $(DATA_VOLUME):/data \
		-v $(PWD)/backups:/backup \
		alpine tar czf /backup/snappymail-backup-$(shell date +%Y%m%d-%H%M%S).tar.gz -C /data .
	@echo "Backup created in ./backups/"

password: ## Show admin password
	@echo "Admin credentials:"
	@echo "Username: admin"
	@echo -n "Password: "
	@docker exec $(CONTAINER_NAME) cat /var/www/html/data/_data_/_default_/admin_password.txt 2>/dev/null || echo "Not yet generated - visit /?admin"

update: ## Update to latest version (edit Dockerfile first!)
	$(MAKE) stop
	$(MAKE) build
	$(MAKE) start
	@echo "Updated! Remember to update SNAPPYMAIL_VERSION in Dockerfile if needed."

status: ## Show container status
	@if docker ps --format '{{.Names}}' | grep -q "^$(CONTAINER_NAME)$$"; then \
		echo "✅ $(CONTAINER_NAME) is running"; \
		docker ps --filter "name=^$(CONTAINER_NAME)$$" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"; \
	else \
		echo "❌ $(CONTAINER_NAME) is not running"; \
	fi