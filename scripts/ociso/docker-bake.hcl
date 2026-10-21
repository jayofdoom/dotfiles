# Build config so you never type -t: `docker buildx bake` builds and tags
# ociso:latest. (Recent Docker CLIs auto-detect this file for plain
# `docker build .` too.)

target "default" {
  context = "."
  dockerfile = "Dockerfile"
  tags = ["ociso:latest"]
}
