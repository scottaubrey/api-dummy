REPO_PREFIX=scottaubrey/elifesciences-api-dummy
IMAGE_TAG=develop
DOCKERFILE=Dockerfile.combined
DOCKER_COMPOSE_FILE=docker-compose.combined.yml

DOCKER_COMPOSE_CMD=docker-compose -f $(DOCKER_COMPOSE_FILE)
DOCKER_BUILD_CMD=docker build -f $(DOCKERFILE)
DOCKER_BUILDX_CMD=docker buildx build -f $(DOCKERFILE)

build:
	$(DOCKER_BUILDX_CMD) . -t $(REPO_PREFIX):$(IMAGE_TAG) --load

test: build
	$(DOCKER_BUILD_CMD) --target tests . -t $(REPO_PREFIX):tests
	docker run --rm $(REPO_PREFIX):tests
	docker image rm $(REPO_PREFIX):tests
	$(DOCKER_COMPOSE_CMD) up -d
	ls
	docker ps
	docker cp ./smoke_tests.sh api-dummy_app_1:/
	docker exec api-dummy-app-1 /smoke_tests.sh
	$(DOCKER_COMPOSE_CMD) down --remove-orphans --volumes --rmi all || true

install-dependencies:
	@# These install dependencies into the working tree for the bind mount to the docker container to work
	$(DOCKER_COMPOSE_CMD) --profile=dependencies run composer

start: build install-dependencies
	$(DOCKER_COMPOSE_CMD) up

reset:
	$(DOCKER_COMPOSE_CMD) down --remove-orphans --volumes --rmi all || true
	rm -Rf vendor/* || true

buildx-and-push:
	$(DOCKER_BUILDX_CMD) --push --platform linux/amd64,linux/arm64 . -t $(REPO_PREFIX):$(IMAGE_TAG)


.PHONY: test build push
