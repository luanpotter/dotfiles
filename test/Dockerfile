# Bare minimum host before ./update.sh can converge (Debian-family example).
# — base image with apt, + ca-certificates (HTTPS mirrors), + sudo (update.sh runs apt via sudo),
# — normal user with passwordless sudo (same shape as a typical laptop).
# yq, git, … come from bootstrap + manifests.
# Build: test/run.sh  (context = repo root)

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
	&& apt-get install -y --no-install-recommends ca-certificates sudo \
	&& rm -rf /var/lib/apt/lists/* \
	&& useradd -m -s /bin/bash test \
	&& echo 'test ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/test

WORKDIR /home/test/dotfiles

COPY --chown=test:test . .

USER test

RUN ./update.sh --yes
