# ociso image: opencode on Alpine, installed from npm with integrity
# verification.
#
# Why npm and not the curl|bash installer: npm verifies every downloaded
# tarball against the registry's sha512 integrity record, and the project's
# npm publishes are locked to their GitHub CI via npm trusted publishing
# (OIDC) — there are no long-lived publish tokens to leak. The curl|bash
# installer verifies nothing and is never used here.
#
# Unpinned by request. NOTE: `docker build` reuses cached RUN layers, so a
# plain rebuild does NOT pick up a new release. To upgrade:
#
#   docker build --pull --no-cache -t ociso:latest .
#
# Keep the container's opencode >= your host's version — they share one
# SQLite DB, and downgrades are the risky direction.
#
# Multi-stage: node exists only for the install step. The final image is
# alpine + the opencode ELF + git + ca-certs + bash + python3/tox (~295MB,
# mostly the binary itself).

FROM node:24-alpine AS installer
# Installs the platform binary package (opencode-linux-*-musl on alpine),
# sha512-verified by npm. The package's postinstall copies the verified ELF
# to bin/opencode.exe and smoke-tests it by running `opencode --version`.
RUN npm install -g @opencode/cli 


FROM alpine:latest
# git: read-only repo inspection by the agent.
# ca-certificates: provider HTTPS egress.
# bash: ociso's --shell debug mode.
# libgcc + libstdc++: the opencode musl ELF links against the C++ runtime
# (libgcc_s.so.1, libstdc++.so.6) which base Alpine doesn't ship.
# python3 + py3-pip + py3-tox: run the codepath's test suites inside the
# container (tox pulls virtualenv in via apk deps). No compiler: common
# C-extension deps ship musllinux wheels; build-base + python3-dev would
# add ~370MiB for rare exceptions.
# curl: HTTP egress / downloads.
# jq: JSON parsing in scripts.
# git-review: Gerrit code review tool, only in Alpine's community repo.
RUN apk add --no-cache bash ca-certificates curl git jq libgcc libstdc++ python3 py3-pip py3-tox \
    && apk add --no-cache --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community git-review
COPY --from=installer /usr/local/lib/node_modules/@opencode/cli/bin/opencode.exe /usr/local/bin/opencode

WORKDIR /workspace
ENTRYPOINT ["opencode"]
