FROM mcr.microsoft.com/vscode/devcontainers/python:0-3.10

RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends default-mysql-server \
    && apt-get clean -y && rm -rf /var/lib/apt/lists/*
