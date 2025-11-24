K6_SERVICE := k6

# Environment variables for k6 testing
FRANKEN_URL := https://localhost:443
FRANKEN_WORKER_URL := https://localhost:444
FPM_URL := http://localhost:8088

.PHONY: k6 clean

pull-docker:
	@echo "Pulling Docker images..."
	docker pull redis:7-alpine
	docker pull php:8.4-fpm
	docker pull prom/prometheus:v2.53.4
	docker pull grafana/grafana:latest
	docker pull hipages/php-fpm_exporter:latest
	docker pull dunglas/frankenphp
	@echo "All Docker images pulled successfully!"

# Individual Docker image pull commands
docker-redis:
	@echo "Pulling Redis image..."
	docker pull redis:7-alpine
	@echo "Redis image pulled successfully!"

docker-php:
	@echo "Pulling PHP-FPM image..."
	docker pull php:8.4-fpm
	@echo "PHP-FPM image pulled successfully!"

docker-prometheus:
	@echo "Pulling Prometheus image..."
	docker pull prom/prometheus:v2.53.4
	@echo "Prometheus image pulled successfully!"

docker-grafana:
	@echo "Pulling Grafana image..."
	docker pull grafana/grafana:latest
	@echo "Grafana image pulled successfully!"

docker-exporter:
	@echo "Pulling PHP-FPM Exporter image..."
	docker pull hipages/php-fpm_exporter:latest
	@echo "PHP-FPM Exporter image pulled successfully!"

docker-frankenphp:
	@echo "Pulling FrankenPHP image..."
	docker pull dunglas/frankenphp
	@echo "FrankenPHP image pulled successfully!"

build:
	docker-compose build

restart:
	docker-compose stop app
	docker-compose up -d app

shell:
	docker-compose exec app bash

up:
	docker-compose up -d app
	docker-compose exec app composer install
	docker-compose up -d redis

down:
	docker-compose up -d down


ps:
	docker-compose ps

up-redis:
	docker-compose up -d redis


up-franken:
	docker-compose up franken -d

down-franken:
	docker-compose stop franken

up-worker:
	docker-compose up franken-worker -d

down-worker:
	docker-compose stop franken-worker

up-prometheus:
	docker-compose up -d prometheus 

up-grafana:
	docker-compose up prometheus grafana -d

down-grafana:
	docker-compose stop prometheus grafana

up-opcache-dashboard:
	docker-compose up -d opcache-dashboard

down-opcache-dashboard:
	docker-compose down opcache-dashboard

up-exporter:
	docker-compose up -d php-fpm-exporter

down-exporter:
	docker-compose down php-fpm-exporter

app-shell:
	docker-compose exec -it app bash

franken-shell:
	docker-compose exec -it franken bash

worker-shell:
	docker-compose exec -it franken bash

migrate: ## Run database migrations
	docker-compose exec app php bin/console doctrine:migrations:migrate --no-interaction

seed: ## Seed the database with test data
	@echo "Seeding database with test data..."
	@echo "Seeder file: src/Command/SeedDatabaseCommand.php"
	docker-compose exec app php bin/console app:seed-database

setup: migrate seed ## Run migrations and seed database

clean:
	docker-compose down -v --remove-orphans

# Franken Worker targets
.PHONY: k6-franken-worker-products
k6-franken-worker-products:
	@echo "Running products test against Franken Worker..."
	k6 run --env BASE_URL=$(FRANKEN_WORKER_URL) k6/list_products.js

.PHONY: k6-franken-worker-products-db
k6-franken-worker-products-db:
	@echo "Running products DB test against Franken Worker..."
	k6 run --env BASE_URL=$(FRANKEN_WORKER_URL) k6/list_products_db.js

.PHONY: k6-franken-worker-products-redis
k6-franken-worker-products-redis:
	@echo "Running products Redis test against Franken Worker..."
	k6 run --env BASE_URL=$(FRANKEN_WORKER_URL) k6/list_products_redis.js

.PHONY: k6-franken-worker-customers
k6-franken-worker-customers:
	@echo "Running customers test against Franken Worker..."
	k6 run --env BASE_URL=$(FRANKEN_WORKER_URL) k6/list_customers.js

.PHONY: k6-franken-worker-customers-db
k6-franken-worker-customers-db:
	@echo "Running customers DB test against Franken Worker..."
	k6 run --env BASE_URL=$(FRANKEN_WORKER_URL) k6/list_customers_db.js

.PHONY: k6-franken-worker-customers-redis
k6-franken-worker-customers-redis:
	@echo "Running customers Redis test against Franken Worker..."
	k6 run --env BASE_URL=$(FRANKEN_WORKER_URL) k6/list_customers_redis.js

.PHONY: k6-franken-worker-orders
k6-franken-worker-orders:
	@echo "Running orders test against Franken Worker..."
	k6 run --env BASE_URL=$(FRANKEN_WORKER_URL) k6/list_orders.js

.PHONY: k6-franken-worker-orders-db
k6-franken-worker-orders-db:
	@echo "Running orders DB test against Franken Worker..."
	k6 run --env BASE_URL=$(FRANKEN_WORKER_URL) k6/list_orders_db.js

.PHONY: k6-franken-worker-orders-redis
k6-franken-worker-orders-redis:
	@echo "Running orders Redis test against Franken Worker..."
	k6 run --env BASE_URL=$(FRANKEN_WORKER_URL) k6/list_orders_redis.js

.PHONY: k6-franken-worker-blog
k6-franken-worker-blog:
	@echo "Running blog test against Franken Worker..."
	k6 run --env BASE_URL=$(FRANKEN_WORKER_URL) k6/loadtest.js

# Franken targets
.PHONY: k6-franken-products
k6-franken-products:
	@echo "Running products test against Franken..."
	k6 run --env BASE_URL=$(FRANKEN_URL) k6/list_products.js

.PHONY: k6-franken-products-db
k6-franken-products-db:
	@echo "Running products DB test against Franken..."
	k6 run --env BASE_URL=$(FRANKEN_URL) k6/list_products_db.js

.PHONY: k6-franken-products-redis
k6-franken-products-redis:
	@echo "Running products Redis test against Franken..."
	k6 run --env BASE_URL=$(FRANKEN_URL) k6/list_products_redis.js

.PHONY: k6-franken-customers
k6-franken-customers:
	@echo "Running customers test against Franken..."
	k6 run --env BASE_URL=$(FRANKEN_URL) k6/list_customers.js

.PHONY: k6-franken-customers-db
k6-franken-customers-db:
	@echo "Running customers DB test against Franken..."
	k6 run --env BASE_URL=$(FRANKEN_URL) k6/list_customers_db.js

.PHONY: k6-franken-customers-redis
k6-franken-customers-redis:
	@echo "Running customers Redis test against Franken..."
	k6 run --env BASE_URL=$(FRANKEN_URL) k6/list_customers_redis.js

.PHONY: k6-franken-orders
k6-franken-orders:
	@echo "Running orders test against Franken..."
	k6 run --env BASE_URL=$(FRANKEN_URL) k6/list_orders.js

.PHONY: k6-franken-orders-db
k6-franken-orders-db:
	@echo "Running orders DB test against Franken..."
	k6 run --env BASE_URL=$(FRANKEN_URL) k6/list_orders_db.js

.PHONY: k6-franken-orders-redis
k6-franken-orders-redis:
	@echo "Running orders Redis test against Franken..."
	k6 run --env BASE_URL=$(FRANKEN_URL) k6/list_orders_redis.js

.PHONY: k6-franken-blog
k6-franken-blog:
	@echo "Running blog test against Franken..."
	k6 run --env BASE_URL=$(FRANKEN_URL) k6/loadtest.js

# mysql read
.PHONY: k6-fpm-products-db
k6-fpm-products-db:
	@echo "Running products DB test against FPM..."
	k6 run --env BASE_URL=$(FPM_URL) k6/list_products_db.js

# projection read
.PHONY: k6-fpm-products-redis
k6-fpm-products-redis:
	@echo "Running products Redis test against FPM..."
	k6 run --env BASE_URL=$(FPM_URL) k6/list_products_redis.js

.PHONY: k6-fpm-customers
k6-fpm-customers:
	@echo "Running customers test against FPM..."
	k6 run --env BASE_URL=$(FPM_URL) k6/list_customers.js

.PHONY: k6-fpm-customers-db
k6-fpm-customers-db:
	@echo "Running customers DB test against FPM..."
	k6 run --env BASE_URL=$(FPM_URL) k6/list_customers_db.js

.PHONY: k6-fpm-customers-redis
k6-fpm-customers-redis:
	@echo "Running customers Redis test against FPM..."
	k6 run --env BASE_URL=$(FPM_URL) k6/list_customers_redis.js

.PHONY: k6-fpm-orders
k6-fpm-orders:
	@echo "Running orders test against FPM..."
	k6 run --env BASE_URL=$(FPM_URL) k6/list_orders.js

.PHONY: k6-fpm-orders-db
k6-fpm-orders-db:
	@echo "Running orders DB test against FPM..."
	k6 run --env BASE_URL=$(FPM_URL) k6/list_orders_db.js

.PHONY: k6-fpm-orders-redis
k6-fpm-orders-redis:
	@echo "Running orders Redis test against FPM..."
	k6 run --env BASE_URL=$(FPM_URL) k6/list_orders_redis.js

.PHONY: k6-fpm-blog
k6-fpm-blog:
	@echo "Running blog test against FPM..."
	k6 run --env BASE_URL=$(FPM_URL) k6/loadtest.js

# Batch testing targets
.PHONY: k6-all-franken-worker
k6-all-franken-worker:
	@echo "Running all tests against Franken Worker..."
	$(MAKE) k6-franken-worker-products
	$(MAKE) k6-franken-worker-products-db
	$(MAKE) k6-franken-worker-products-redis
	$(MAKE) k6-franken-worker-customers
	$(MAKE) k6-franken-worker-customers-db
	$(MAKE) k6-franken-worker-customers-redis
	$(MAKE) k6-franken-worker-orders
	$(MAKE) k6-franken-worker-orders-db
	$(MAKE) k6-franken-worker-orders-redis
	$(MAKE) k6-franken-worker-blog

.PHONY: k6-all-franken
k6-all-franken:
	@echo "Running all tests against Franken..."
	$(MAKE) k6-franken-products
	$(MAKE) k6-franken-products-db
	$(MAKE) k6-franken-products-redis
	$(MAKE) k6-franken-customers
	$(MAKE) k6-franken-customers-db
	$(MAKE) k6-franken-customers-redis
	$(MAKE) k6-franken-orders
	$(MAKE) k6-franken-orders-db
	$(MAKE) k6-franken-orders-redis
	$(MAKE) k6-franken-blog

.PHONY: k6-all-fpm
k6-all-fpm:
	@echo "Running all tests against FPM..."
	$(MAKE) k6-fpm-products
	$(MAKE) k6-fpm-products-db
	$(MAKE) k6-fpm-products-redis
	$(MAKE) k6-fpm-customers
	$(MAKE) k6-fpm-customers-db
	$(MAKE) k6-fpm-customers-redis
	$(MAKE) k6-fpm-orders
	$(MAKE) k6-fpm-orders-db
	$(MAKE) k6-fpm-orders-redis
	$(MAKE) k6-fpm-blog

.PHONY: k6-all-environments
k6-all-environments:
	@echo "Running all tests against all environments..."
	$(MAKE) k6-all-franken-worker
	$(MAKE) k6-all-franken
	$(MAKE) k6-all-fpm

# Utility targets
.PHONY: k6-clean-reports
k6-clean-reports:
	@echo "Cleaning k6 report files..."
	rm -f k6/report-*.html

.PHONY: k6-install
k6-install:
	@echo "Installing k6..."
	@if command -v k6 >/dev/null 2>&1; then \
		echo "k6 is already installed"; \
	else \
		echo "Installing k6..."; \
		if command -v brew >/dev/null 2>&1; then \
			brew install k6; \
		elif command -v apt-get >/dev/null 2>&1; then \
			sudo apt-get update && sudo apt-get install -y k6; \
		else \
			echo "Please install k6 manually from https://k6.io/docs/getting-started/installation/"; \
		fi; \
	fi

# Projection rebuild targets
.PHONY: rebuild-projections
rebuild-projections:
	@echo "Rebuilding all projections..."
	docker-compose exec app php bin/console app:rebuild-product-projections
	docker-compose exec app php bin/console app:rebuild-customer-projections
	docker-compose exec app php bin/console app:rebuild-order-projections

.PHONY: rebuild-products
rebuild-products:
	@echo "Rebuilding product projections..."
	docker-compose exec app bin/console app:rebuild-product-projections

.PHONY: rebuild-customers
rebuild-customers:
	@echo "Rebuilding customer projections..."
	docker-compose exec app bin/console app:rebuild-customer-projections

.PHONY: rebuild-orders
rebuild-orders:
	@echo "Rebuilding order projections..."
	docker-compose exec app bin/console app:rebuild-order-projections

.PHONY: seed-db
seed-db:
	@echo "Seeding database with test data..."
	docker-compose exec app bin/console app:seed-database

.PHONY: reset-and-seed
reset-and-seed:
	@echo "Resetting database and seeding with test data..."
	docker-compose exec php bin/console doctrine:database:drop --force --if-exists
	docker-compose exec php bin/console doctrine:database:create
	docker-compose exec php bin/console doctrine:migrations:migrate --no-interaction
	docker-compose exec php bin/console app:seed-database



## help: show available targets
help:
	@echo "GlasgowPHP CQRS Load Testing"
	@echo ""
	@echo "Available targets:"
	@echo "  help                    - Show this help message"
	@echo "  docker                  - Pull all required Docker images"
	@echo "  docker-redis            - Pull Redis image only"
	@echo "  docker-php              - Pull PHP-FPM image only"
	@echo "  docker-prometheus       - Pull Prometheus image only"
	@echo "  docker-grafana          - Pull Grafana image only"
	@echo "  docker-exporter         - Pull PHP-FPM Exporter image only"
	@echo "  docker-frankenphp       - Pull FrankenPHP image only"
	@echo ""
	@echo "Franken Worker (https://localhost:444):"
	@echo "  k6-franken-worker-products    - Test products endpoint"
	@echo "  k6-franken-worker-products-db - Test products DB endpoint"
	@echo "  k6-franken-worker-products-redis - Test products Redis endpoint"
	@echo "  k6-franken-worker-customers   - Test customers endpoint"
	@echo "  k6-franken-worker-customers-db - Test customers DB endpoint"
	@echo "  k6-franken-worker-customers-redis - Test customers Redis endpoint"
	@echo "  k6-franken-worker-orders      - Test orders endpoint"
	@echo "  k6-franken-worker-orders-db   - Test orders DB endpoint"
	@echo "  k6-franken-worker-orders-redis - Test orders Redis endpoint"
	@echo "  k6-franken-worker-blog        - Test blog endpoint"
	@echo ""
	@echo "Franken (https://localhost:443):"
	@echo "  k6-franken-products           - Test products endpoint"
	@echo "  k6-franken-products-db        - Test products DB endpoint"
	@echo "  k6-franken-products-redis     - Test products Redis endpoint"
	@echo "  k6-franken-customers          - Test customers endpoint"
	@echo "  k6-franken-customers-db       - Test customers DB endpoint"
	@echo "  k6-franken-customers-redis    - Test customers Redis endpoint"
	@echo "  k6-franken-orders             - Test orders endpoint"
	@echo "  k6-franken-orders-db          - Test orders DB endpoint"
	@echo "  k6-franken-orders-redis       - Test orders Redis endpoint"
	@echo "  k6-franken-blog               - Test blog endpoint"
	@echo ""
	@echo "FPM (http://localhost:8088):"
	@echo "  k6-fpm-products               - Test products endpoint"
	@echo "  k6-fpm-products-db            - Test products DB endpoint"
	@echo "  k6-fpm-products-redis         - Test products Redis endpoint"
	@echo "  k6-fpm-customers              - Test customers endpoint"
	@echo "  k6-fpm-customers-db           - Test customers DB endpoint"
	@echo "  k6-fpm-customers-redis        - Test customers Redis endpoint"
	@echo "  k6-fpm-orders                 - Test orders endpoint"
	@echo "  k6-fpm-orders-db              - Test orders DB endpoint"
	@echo "  k6-fpm-orders-redis           - Test orders Redis endpoint"
	@echo "  k6-fpm-blog                   - Test blog endpoint"
	@echo ""
	@echo "Batch testing:"
	@echo "  k6-all-franken-worker         - Run all tests against Franken Worker"
	@echo "  k6-all-franken                - Run all tests against Franken"
	@echo "  k6-all-fpm                    - Run all tests against FPM"
	@echo "  k6-all-environments           - Run all tests against all environments"
	@echo ""
	@echo "Projection management:"
	@echo "  rebuild-projections            - Rebuild all projections (products, customers, orders)"
	@echo "  rebuild-products               - Rebuild product projections only"
	@echo "  rebuild-customers              - Rebuild customer projections only"
	@echo "  rebuild-orders                 - Rebuild order projections only"
	@echo "  seed-db                        - Seed database with test data"
	@echo "  reset-and-seed                 - Reset database and seed with test data"
