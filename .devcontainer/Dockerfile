# See here for image contents: https://github.com/microsoft/vscode-dev-containers/tree/v0.145.1/containers/alpine/.devcontainer/base.Dockerfile

# [Choice] Alpine version: 3.12, 3.11, 3.10
ARG VARIANT="1.10.4"
FROM elixir:${VARIANT}

RUN apt-get update && apt-get install -y git vim
RUN mix local.hex --force && mix local.rebar --force
# ** [Optional] Uncomment this section to install additional packages. **
# RUN apk update \
#     && apk add --no-cache <your-package-list-here>
