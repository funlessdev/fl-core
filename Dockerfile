# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#   http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
# The version of Alpine to use for the final image
# This should match the version of Alpine that the `elixir:1.13.4-alpine` image uses
ARG ALPINE_VERSION=3.16

FROM elixir:1.13.4-alpine AS builder

# The following are build arguments used to change variable parts of the image.
# The name of your application/release (required)
ARG MIX_ENV=prod

ENV MIX_ENV=${MIX_ENV}
# RUSTUP_HOME=/opt/rust CARGO_HOME=/opt/cargo PATH=/opt/cargo/bin:$PATH

# By convention, /opt is typically used for applications
WORKDIR /opt/app

# This step installs all the build tools we'll need
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache git build-base rust cargo && \
    mix local.rebar --force && \
    mix local.hex --force


# This copies our app source code into the build container
COPY . .

RUN mix do deps.get, deps.compile, compile

RUN mix release 

# From this line onwards, we're in a new image, which will be the image used in production
FROM alpine:${ALPINE_VERSION}

ARG MIX_ENV=prod

# # The name of your application/release (required)
RUN apk update && \
    apk upgrade && \
    apk add --no-cache libstdc++ libgcc ncurses-libs socat sudo bash

ENV REPLACE_OS_VARS=true \
    MIX_ENV=${MIX_ENV} 

WORKDIR /home/funless
RUN adduser --disabled-password --home "$(pwd)" funless &&\
    echo "funless ALL=(ALL:ALL) NOPASSWD: ALL" >>/etc/sudoers

USER funless 

COPY --chown=funless --from=builder /opt/app/_build/${MIX_ENV}/rel/worker ./worker

COPY --chown=funless init_container.sh .

RUN chmod +x init_container.sh

CMD ["bash", "init_container.sh"]
