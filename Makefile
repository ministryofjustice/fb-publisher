ifdef TARGET
TARGETDEFINED="true"
else
TARGETDEFINED="false"
endif

dev:
	$(eval export env_stub=dev)
	@true

test:
	$(eval export env_stub=test)
	@true

integration:
	$(eval export env_stub=integration)
	@true

live:
	$(eval export env_stub=live)
	@true

target:
ifeq ($(TARGETDEFINED), "true")
	$(eval export env_stub=${TARGET})
	@true
else
	$(info Must set TARGET)
	@false
endif

init:
	$(eval export ECR_REPO_NAME_SUFFIXES=base web worker)
	$(eval export ECR_REPO_URL_ROOT=754256621582.dkr.ecr.eu-west-2.amazonaws.com/formbuilder)

build: stop
	docker-compose build

stop:
	docker-compose down
	docker-compose kill
	docker-compose rm -f

lint:
	$(MAKE) build
	docker-compose run --rm web bundle exec rubocop

# install aws cli w/o sudo
install_build_dependencies: init
	docker --version
	pip install --user awscli
	$(eval export PATH=${PATH}:${HOME}/.local/bin/)

# Needs ECR_REPO_NAME & ECR_REPO_URL env vars
build_and_push: install_build_dependencies
	TAG="latest-${env_stub}" REPO_SCOPE=${ECR_REPO_URL_ROOT} ./scripts/build_and_push_all.sh



.PHONY := init push build login lint
