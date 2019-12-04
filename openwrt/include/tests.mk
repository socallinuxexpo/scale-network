REPO_ROOT := $(shell git rev-parse --show-toplevel)

golden-test:
	@cd $(REPO_ROOT)/tests/unit/openwrt && \
	    sh test.sh -t ar71xx && \
	    sh test.sh -t ipq806x


golden-update:
	@cd $(REPO_ROOT)/tests/unit/openwrt && \
	    sh test.sh -u -t ar71xx && \
	    sh test.sh -u -t ipq806x
