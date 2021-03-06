###############################
# Common defaults/definitions #
###############################

comma := ,
empty :=
space := $(empty) $(empty)

# Checks two given strings for equality.
eq = $(if $(or $(1),$(2)),$(and $(findstring $(1),$(2)),\
                                $(findstring $(2),$(1))),1)




######################
# Project parameters #
######################

NAMESPACES := instrumentisto \
              ghcr.io/instrumentisto \
              quay.io/instrumentisto
NAME := opendkim
ALL_IMAGES := \
	debian:2.10.3-r1,2.10.3,2.10,2,latest \
	alpine:2.10.3-r1-alpine,2.10.3-alpine,2.10-alpine,2-alpine,alpine
#	<Dockerfile>:<version>,<tag1>,<tag2>,...

# Default is first image from ALL_IMAGES list.
DOCKERFILE ?= $(word 1,$(subst :, ,$(word 1,$(ALL_IMAGES))))
TAGS ?= $(word 1,$(subst |, ,\
	$(word 2,!$(subst $(DOCKERFILE):, ,$(subst $(space),|,$(ALL_IMAGES))))))
VERSION ?= $(word 1,$(subst -, ,$(TAGS)))-$(word 2,$(strip \
	$(subst -, ,$(subst $(comma), ,$(TAGS)))))
OPENDKIM_VER ?= $(word 1,$(subst -, ,$(VERSION)))




###########
# Aliases #
###########

dockerfile: codegen.dockerfile

image: docker.image

push: docker.push

release: git.release

tags: docker.tags

test: test.docker




###################
# Docker commands #
###################

docker-namespaces = $(strip $(if $(call eq,$(namespaces),),\
                            $(NAMESPACES),$(subst $(comma), ,$(namespaces))))
docker-tags = $(strip $(if $(call eq,$(tags),),\
                      $(TAGS),$(subst $(comma), ,$(tags))))


# Build Docker image with the given tag.
#
# Usage:
#	make docker.image [tag=($(VERSION)|<docker-tag>)]] [no-cache=(no|yes)]

docker.image:
	docker build --network=host --force-rm \
		$(if $(call eq,$(no-cache),yes),--no-cache --pull,) \
		-t instrumentisto/$(NAME):$(if $(call eq,$(tag),),$(VERSION),$(tag)) \
		$(DOCKERFILE)/


# Manually push Docker images to container registries.
#
# Usage:
#	make docker.push [tags=($(TAGS)|<docker-tag-1>[,<docker-tag-2>...])]
#	                 [namespaces=($(NAMESPACES)|<prefix-1>[,<prefix-2>...])]

docker.push:
	$(foreach tag,$(subst $(comma), ,$(docker-tags)),\
		$(foreach namespace,$(subst $(comma), ,$(docker-namespaces)),\
			$(call docker.push.do,$(namespace),$(tag))))
define docker.push.do
	$(eval repo := $(strip $(1)))
	$(eval tag := $(strip $(2)))
	docker push $(repo)/$(NAME):$(tag)
endef


# Tag Docker image with the given tags.
#
# Usage:
#	make docker.tags [of=($(VERSION)|<docker-tag>)]
#	                 [tags=($(TAGS)|<docker-tag-1>[,<docker-tag-2>...])]
#	                 [namespaces=($(NAMESPACES)|<prefix-1>[,<prefix-2>...])]

docker-tags-of = $(if $(call eq,$(of),),$(VERSION),$(of))

docker.tags:
	$(foreach tag,$(subst $(comma), ,$(docker-tags)),\
		$(foreach namespace,$(subst $(comma), ,$(docker-namespaces)),\
			$(call docker.tags.do,$(docker-tags-of),$(namespace),$(tag))))
define docker.tags.do
	$(eval from := $(strip $(1)))
	$(eval repo := $(strip $(2)))
	$(eval to := $(strip $(3)))
	docker tag instrumentisto/$(NAME):$(from) $(repo)/$(NAME):$(to)
endef


docker.test: test.docker




####################
# Codegen commands #
####################

# Generate Dockerfile from template.
#
# Usage:
#	make dockerfile [dir=(@all|<dockerfile-dir>)]

codegen-dockerfile-dir = $(if $(call eq,$(dir),),@all,$(dir))

codegen.dockerfile:
ifeq ($(codegen-dockerfile-dir),@all)
	$(foreach img,$(ALL_IMAGES),$(call codegen.dockerfile.do,\
		$(word 1,$(subst :, ,$(img))),\
		$(word 1,$(subst $(comma), ,$(word 2,$(subst :, ,$(img)))))))
else
	$(call codegen.dockerfile.do,\
		$(codegen-dockerfile-dir),\
		$(word 1,$(subst -, ,$(word 1,$(subst |, ,\
			$(word 2,!$(subst $(codegen-dockerfile-dir):, ,$(subst $(space),|,\
			                                               $(ALL_IMAGES)))))))))
endif
define codegen.dockerfile.do
	$(eval dockerfile-dir := $(strip $(1)))
	$(eval dockerfile-ver := $(strip $(2)))
	@mkdir -p $(dockerfile-dir)/
	docker run --rm -v "$(PWD)/Dockerfile.tmpl.php":/Dockerfile.php:ro \
		php:alpine php -f /Dockerfile.php -- \
			--dockerfile='$(dockerfile-dir)' \
			--version='$(dockerfile-ver)' \
		> $(dockerfile-dir)/Dockerfile
	@rm -rf $(dockerfile-dir)/rootfs
	cp -rf rootfs $(dockerfile-dir)/
	git add $(dockerfile-dir)/rootfs
endef




####################
# Testing commands #
####################

# Run Bats tests for Docker image.
#
# Documentation of Bats:
#	https://github.com/bats-core/bats-core
#
# Usage:
#	make test.docker [tag=($(VERSION)|<tag>)]

test.docker:
ifeq ($(wildcard node_modules/.bin/bats),)
	@make npm.install
endif
	DOCKERFILE=$(DOCKERFILE) \
	IMAGE=instrumentisto/$(NAME):$(if $(call eq,$(tag),),$(VERSION),$(tag)) \
	node_modules/.bin/bats \
		--timing $(if $(call eq,$(CI),),--pretty,--formatter tap) \
		tests/main.bats




################
# NPM commands #
################

# Resolve project NPM dependencies.
#
# Usage:
#	make npm.install [dockerized=(no|yes)]

npm.install:
ifeq ($(dockerized),yes)
	docker run --rm --network=host -v "$(PWD)":/app/ -w /app/ \
		node \
			make npm.install dockerized=no
else
	npm install
endif




################
# Git commands #
################

# Release project version (apply version tag and push).
#
# Usage:
#	make git.release [ver=($(VERSION)|<proj-ver>)]

git-release-tag = $(strip $(if $(call eq,$(ver),),$(VERSION),$(ver)))

git.release:
ifeq ($(shell git rev-parse $(git-release-tag) >/dev/null 2>&1 && echo "ok"),ok)
	$(error "Git tag $(git-release-tag) already exists")
endif
	git tag $(git-release-tag) master
	git push origin refs/tags/$(git-release-tag)




##################
# .PHONY section #
##################

.PHONY: dockerfile image push release tags test \
        codegen.dockerfile \
        docker.image docker.push docker.tags docker.test \
        git.release \
        npm.install \
        test.docker
