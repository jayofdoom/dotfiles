# ociso — credential-isolated opencode containers

Run any number of opencode instances against host codepaths, edited in place,
with GPG/SSH/AWS and the rest of your homedir unreachable from inside the
container. One bash script + one Docker image. No locks, no state, no
subcommands — `docker ps` is the instance list.

## Build

    docker buildx bake

The `ociso:latest` tag lives in `docker-bake.hcl` — no `-t` to remember.
Newer Docker CLIs auto-detect the bake file even for plain `docker build .`;
if yours doesn't, `docker buildx bake` is the command.

### Upgrading (unpinned by design)

Rebuilds reuse cached layers, so a plain rebuild does **not** pick up
a new release. Upgrade with:

    docker buildx bake --pull --no-cache

Keep the container's opencode version >= your host's — both write the same
SQLite DB; forward migrations are fine, downgrades are the risky direction.

## Install

    chmod +x ociso
    ln -s "$PWD/ociso" ~/.local/bin/ociso   # or wherever on PATH

## Usage

    ociso ~/code/openstack/nova                         # core case
    ociso ~/code/openstack --config ~/cfgs/strict.json  # repo-group + injected config
    ociso ~/scratch/legacy --ro                         # read-only codepath
    ociso ~/code/openstack --shell                      # debug the container
    ociso . -- --log-level DEBUG                        # flag passthrough

Options: `--config FILE` (OPENCODE_CONFIG — sits between global and project
config, so a repo's own `opencode.json` still wins), `--ro`, `--shell`,
`--env K=V` (repeatable, for `{env:...}` config substitution), `--` passes
everything after it to opencode. `OCISO_IMAGE` overrides the image name
(default `ociso:latest`).

## Security boundary

| Inside | Outside (requires container breakout) |
|---|---|
| Codepath you point at (RW, in place) | `~/.gnupg`, `~/.ssh`, `~/.aws`, dotfiles, browser profiles |
| Real opencode sessions/config/cache | GPG/SSH agent sockets |
| Provider auth (`auth.json`) — by design | Rest of `$HOME` |

Hardening: `--cap-drop=ALL`, `no-new-privileges`, read-only rootfs, tmpfs
`/tmp`, runs as your uid/gid (in-place editing requires it — so a breakout
lands as you; the barrier is the mount namespace and dropped capabilities,
not file permissions). Provider auth is mounted on purpose: calling
providers is the agent's job. Network: default bridge, unrestricted egress.

## How it stays "local"

The codepath AND `$HOME` sit at their real host paths. `$HOME` is a shadow:
a scratch dir (`~/.cache/ociso/home`, disposable) mounted at the real home
path, with the three real opencode subtrees (`~/.local/share/opencode`,
`~/.config/opencode`, `~/.cache/opencode`) mounted inside it at their true
paths — same sessions, same auth, warm cache, and project identity (git
worktree) matches local runs. Anything opencode writes elsewhere in `$HOME`
lands in the scratch shadow. Sharing behaves exactly like running N local
opencodes in N terminals.

## Known behaviors (same-as-local, by design)

- Host and container opencode share one SQLite DB — keep container >= host.
- Concurrent cold starts share `~/.cache/opencode`.
- Non-git codepaths share the `global` pseudo-project.
- Git discovery stops at the mount root (parents of the mount are invisible).
- `git commit` inside is unsupported (no identity, no creds — by design);
  commit and push from the host.
