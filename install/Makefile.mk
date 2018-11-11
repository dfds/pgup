DBMIGRATIONS_IMAGE_NAME := ded/p-team/tracking-service/dbmigrations

migration: ## add database migration
	@cd db && chmod +x add-migration.sh && ./add-migration.sh

container: CONFIGURATION=Release ## build container
container: package
	docker build -t $(IMAGE_NAME) .
	cd db && docker build -t $(DBMIGRATIONS_IMAGE_NAME) .

release: container ## push container
	chmod +x ./scripts/push_container_image.sh && ./scripts/push_container_image.sh $(IMAGE_NAME) $(BUILD_NUMBER)
	chmod +x ./scripts/push_container_image.sh && ./scripts/push_container_image.sh $(DBMIGRATIONS_IMAGE_NAME) $(BUILD_NUMBER)
