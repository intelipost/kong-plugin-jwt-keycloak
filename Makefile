include makefiles/*.mk

REPOSITORY?=gbbirkisson
IMAGE?=kong-plugin-jwt-keycloak
KONG_VERSION?=1.0
FULL_IMAGE_NAME:=${REPOSITORY}/${IMAGE}:${KONG_VERSION}

PLUGIN_VERSION?=1.0.0-1

TEST_VERSIONS?=1.0.0 1.0.1 1.0.2 1.0.3 1.1rc1

build:
	docker build -t ${FULL_IMAGE_NAME} --build-arg KONG_VERSION=${KONG_VERSION} --build-arg PLUGIN_VERSION=${PLUGIN_VERSION} .

run: build
	docker run -it --rm ${FULL_IMAGE_NAME} kong start --vv

exec: build
	docker run -it --rm ${FULL_IMAGE_NAME} ash

push: build test
	docker push ${FULL_IMAGE_NAME}

### Testing ###

start: kong-db-start kong-start
restart: kong-stop kong-start
restart-all: stop start
stop: kong-stop kong-db-stop

test-unit:
	@echo ======================================================================
	@echo "Running unit tests"
	@echo

	@cd tests && $(MAKE) --no-print-directory _tests-unit PLUGIN_VERSION=${PLUGIN_VERSION}

	@echo
	@echo "Unit tests passed"
	@echo ======================================================================

test-integration: restart-all sleep
	@echo ======================================================================
	@echo "Testing kong version ${KONG_VERSION} with ${KONG_DATABASE}"
	@echo

	@cd tests && $(MAKE) --no-print-directory _tests-integration PLUGIN_VERSION=${PLUGIN_VERSION}

	@echo
	@echo "Testing kong version ${KONG_VERSION} with ${KONG_DATABASE} was successful"
	@echo ======================================================================

test: test-unit test-integration

test-all:
	@echo "Starting integration tests for multiple versions"
	@set -e; for t in  $(TEST_VERSIONS); do \
		$(MAKE) --no-print-directory test-unit PLUGIN_VERSION=${PLUGIN_VERSION} KONG_VERSION=$$t ; \
    $(MAKE) --no-print-directory test-integration PLUGIN_VERSION=${PLUGIN_VERSION} KONG_VERSION=$$t KONG_DATABASE=postgres ; \
		$(MAKE) --no-print-directory test-integration PLUGIN_VERSION=${PLUGIN_VERSION} KONG_VERSION=$$t KONG_DATABASE=cassandra ; \
    done
	@echo "All test successful"

sleep:
	@sleep 5