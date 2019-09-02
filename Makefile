DOCKER_IMAGE_NAME	= dfds/pgup:$(VERSION)
OWNER				:= dfds
REPO				:= pgup
PROJECT				:= github.com/$(OWNER)/$(REPO)
VERSION				?= $(shell git describe --tags --always --dirty --match=v* 2> /dev/null || cat $(CURDIR)/.version 2> /dev/null || echo v0)
M					= $(shell printf "\033[34;1m▶\033[0m")

.PHONY: all
all: build

build:
	@docker build -t pgup .

run:
	@docker-compose up --build pgup

db-start:
	@docker-compose up -d database

db-log:
	@docker-compose logs database

db-stop:
	@docker-compose down

github-release-create:
	./scripts/git-release.sh \
		$(OWNER) \
		$(REPO) \
		$(VERSION)

# github-asset-upload:
# 	./script/git-upload.sh \
# 		$(OWNER) \
# 		$(REPO) \
# 		$(VERSION) \
# 		db.tar.gz

.PHONY: docker
docker: docker-build docker-push ## build and push docker container

.PHONY: docker-build
docker-build: ; $(info $(M) Building docker container $(DOCKER_IMAGE_NAME)) @ ## build docker image
	#docker build -t $(DOCKER_IMAGE_NAME) .

.PHONY: docker-push
docker-push: ; $(info $(M) Pushing docker container $(DOCKER_IMAGE_NAME)) @ ## push docker image
	docker push $(DOCKER_IMAGE_NAME)

.PHONY: clean
clean: ; $(info $(M) Cleaning...) @ ## clean the build artifacts
	@rm -rf $(BIN)

.PHONY: version
version: ## prints the version (from either environment VERSION, git describe, or .version. default: v0)
	@echo $(VERSION)

.PHONY: help
help:
	@grep -E '^[ a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-15s\033[0m %s\n", $$1, $$2}'
