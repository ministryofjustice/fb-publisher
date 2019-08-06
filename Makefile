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

serve:
	sudo docker-compose down -v
	sudo docker-compose build
	sudo docker-compose up -d db
	./scripts/wait_for_db.sh db postgres
	sudo docker-compose up -d app

init:
	$(eval export ECR_REPO_URL_ROOT=754256621582.dkr.ecr.eu-west-2.amazonaws.com/formbuilder)

# install aws cli w/o sudo
install_build_dependencies: init
	docker --version
	pip install --user awscli
	$(eval export PATH=${PATH}:${HOME}/.local/bin/)

# Needs ECR_REPO_NAME & ECR_REPO_URL env vars
build_and_push: install_build_dependencies
	TAG="latest-${env_stub}" CIRCLE_SHA1=${CIRCLE_SHA1} REPO_SCOPE=${ECR_REPO_URL_ROOT} ./scripts/build_and_push_all.sh

.PHONY := init push build login
