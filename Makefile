# Copyright 2022 Giuseppe De Palma, Matteo Trentin
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

export SHELL:=/bin/bash
export SHELLOPTS:=$(if $(SHELLOPTS),$(SHELLOPTS):)pipefail:errexit

.PHONY: build-core-image build-worker-image credo-core credo-worker dial-core dial-worker test-core test-worker test-all

## Compile core docker image
build-core-image: 
	docker build \
	-f core/Dockerfile \
	--build-arg SECRET_KEY_BASE=local-make-secret \
	--build-arg MIX_ENV="dev" \
	-t core .

## Compile worker docker image
build-worker-image: 
	docker build -f worker/Dockerfile --build-arg MIX_ENV="dev" -t worker .

## Run credo --strict
credo-core: 
	cd core
	mix credo --strict

credo-worker:
	cd worker
	mix credo --strict

## Run dialyzer
dial-core:
	cd core
	mix dialyzer

dial-worker:
	cd worker
	mix dialyzer

 ## Run test suite, launch Postgres with docker-compose
test-core: 
	cd core
	function tearDown {
		docker compose -f docker-compose.yml down
	}
	trap tearDown EXIT
	mix deps.get
	docker compose -f docker-compose.yml up --detach
	mix test
	mix itest

test-worker:
	cd worker
	mix deps.get
	mix test

test-all:
	make test-core
	make test-worker