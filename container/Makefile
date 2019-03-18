# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

VERSION?=3.11.4
REV?=v22
PROJECT_ID?=pso-examples
PROJECT?=gcr.io/${PROJECT_ID}
CASSANDRA_HOST_IP?=$(strip $(shell ifconfig | sed -En 's/127.0.0.1//;s/.*inet (addr:)?(([0-9]*\.){3}[0-9]*).*/\2/p'|tail -n 1|awk '{print $1}'))

all: build

docker:
	docker build --no-cache=true --compress --squash --build-arg "CASSANDRA_VERSION=${VERSION}" -t ${PROJECT}/cassandra:${VERSION}-${REV} .

docker-cqlsh:
	docker build --pull --build-arg "CASSANDRA_VERSION=${VERSION}" --build-arg "CQLSH_CONTAINER=1" -t ${PROJECT}/cassandra:${VERSION}-cqlsh-${REV} .

docker-cached:
	docker build --compress --squash --build-arg "CASSANDRA_VERSION=${VERSION}" -t ${PROJECT}/cassandra:${VERSION}-${REV} .

build: docker

build-cqlsh: docker-cqlsh

build-cached: docker-cached

push: build build-cqlsh
	docker push ${PROJECT}/cassandra:${VERSION}-${REV}
	docker push ${PROJECT}/cassandra:${VERSION}-cqlsh-${REV}

run: build-cached
	docker run -i -t --rm \
	-e CASSANDRA_SEEDS='172.17.0.2' \
	-e CASSANDRA_MEMTABLE_FLUSH_WRITERS=1 \
	${PROJECT}/cassandra:${VERSION}

shell: build-cached
	docker run -i -t --rm \
	-e CASSANDRA_SEEDS='172.17.0.2' \
	-e CASSANDRA_MEMTABLE_FLUSH_WRITERS=1 \
	${PROJECT}/cassandra:${VERSION} \
	/bin/bash

push-cqlsh: build-cqlsh
	docker push ${PROJECT}/cassandra:${VERSION}-cqlsh-${REV}

push-all: build build-cqlsh push push-cqlsh

.PHONY: all build push docker docker-cqlsh build-cqlsh push push-all
