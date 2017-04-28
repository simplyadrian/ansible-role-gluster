GIT_COMMIT=$(shell git rev-parse HEAD)
MY_DIR=$(shell basename "$(CURDIR)")
PLATFORM=centos
TEST_LABEL_KEY=ansible-role-testing
TEST_TAG=7.3.1611
define DOCKER_BODY
ARG ANSIBLE_OPTIONS
ARG TEST_LABEL
ARG TEST_LABEL_KEY
ARG TEST_TAG
ARG GIT_COMMIT=unknown
LABEL $$TEST_LABEL_KEY=$$TEST_LABEL
LABEL git-commit=$$GIT_COMMIT
LABEL TEST_TAG=$$TEST_TAG
RUN yum -y update && \
    yum install -y epel-release && \
    yum install -y python2.7 python-pip gcc python-devel openssl-devel && \
    pip install -U distribute boto ansible==2.1.0 virtualenv awscli
ADD tests /tmp/playbook
ADD . /tmp/playbook/roles/$$TEST_LABEL
WORKDIR /tmp/playbook
RUN ansible-playbook $$ANSIBLE_OPTIONS -i inventory test.yml
endef
export DOCKER_BODY
.PHONY: default
testv: ANSIBLE_OPTIONS = -v
test testv:
	echo 'FROM ${PLATFORM}:${TEST_TAG}' > tests/Dockerfile
	echo "$$DOCKER_BODY" >> tests/Dockerfile
	docker build --build-arg TEST_LABEL="${MY_DIR}" \
	  --build-arg TEST_LABEL_KEY=${TEST_LABEL_KEY} \
	  --build-arg GIT_COMMIT=${GIT_COMMIT} \
	  --build-arg TEST_TAG=${TEST_TAG} \
          --build-arg ANSIBLE_OPTIONS=${ANSIBLE_OPTIONS} \
	  --force-rm -t "${MY_DIR}":${TEST_TAG} -f tests/Dockerfile .
remove:
	docker rmi $(shell docker images -q --filter label=TEST_TAG=${TEST_TAG} --filter label=${TEST_LABEL_KEY}="${MY_DIR}")
	rm tests/Dockerfile
clean .IGNORE: remove
all: test
