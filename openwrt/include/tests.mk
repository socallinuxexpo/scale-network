# gitlab trigger token
# ref: https://docs.gitlab.com/ee/ci/triggers/#create-a-trigger-token
GITLAB_TOKEN ?= empty
# gitlab mirror project id
GITLAB_PROJECT ?= 17362342
WORMHOLE_CODE ?= empty

REPO_ROOT := $(shell git rev-parse --show-toplevel)
REPO_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)

golden-test:
	@cd $(REPO_ROOT)/tests/unit/openwrt && \
	    sh test.sh -t ar71xx && \
	    sh test.sh -t ipq806x

golden-update:
	@cd $(REPO_ROOT)/tests/unit/openwrt && \
	    sh test.sh -u -t ar71xx && \
	    sh test.sh -u -t ipq806x

autoflash-test:
	curl --request POST \
	  --form token=$(GITLAB_TOKEN) \
	  --form "ref=$(REPO_BRANCH)" \
	  --form "variables[OPENWRT_INTEG]=YES" \
	  --form "variables[WORMHOLE_CODE]=$(WORMHOLE_CODE)" \
	  https://gitlab.com/api/v4/projects/$(GITLAB_PROJECT)/trigger/pipeline
