.PHONY: new
HAVE_GO_BINDATA := $(shell command -v hugo 2> /dev/null)
args=`arg="$(filter-out $@,$(MAKECMDGOALS))" && echo $${arg:-${1}}`
new: ## Create a new post(ex. make new GDGCloud Taipei meetup 47)
ifndef HAVE_GO_BINDATA
	@echo "requires 'hugo' vist https://gohugo.io/getting-started/installing/"
	@exit 1 # fail
else
	hugo new --kind post-bundle posts/$(shell docker run -it --rm vandot/casbab kebab "$(call args,defaultstring)")
endif


.PHONY: help
help: ## this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_0-9-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST) | sort

.DEFAULT_GOAL := help