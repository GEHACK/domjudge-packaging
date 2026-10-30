# GEHACK fork of domjudge-packaging

This fork exists for one reason: the judging chroot in the upstream `judgehost` image
does not carry the compilers the GEHACK contest workstations run.

Upstream builds the chroot with `dj_make_chroot` inside an `ubuntu:24.04` builder, and
`dj_make_chroot` follows the builder's own `lsb_release`. The result is a noble chroot
with gcc 13.x and pypy3 7.3.15, and no Kotlin at all. This fork bootstraps the chroot as
Ubuntu 26.04 (`resolute`) instead, which is much closer to the workstations' nixpkgs
toolchain, and installs Kotlin from JetBrains' own release.

| | Ubuntu 26.04 chroot | upstream (Ubuntu 24.04) |
| --- | --- | --- |
| gcc / g++ | 15.2.x | 13.x |
| pypy3 | 7.3.20 | 7.3.15 |
| OpenJDK | 21 | 21 |
| Kotlin | 2.4.20 (JetBrains) | — |

An intermediate version of this fork judged in a chroot built by Nix from genix
(`ghcr.io/gehack/genix/genix-chroot`). That has been dropped in favour of this one, which
stays within a few lines of upstream.

## What is changed

- `docker/judgehost/chroot-and-tar.sh` — bootstraps the chroot as Ubuntu 26.04, installs
  OpenJDK 21 by name (on 26.04 `default-jdk-headless` resolves to OpenJDK 25), and unzips
  the Kotlin compiler release into it. pypy3 needs nothing extra: upstream's
  `dj_make_chroot` already installs it on amd64 Ubuntu.
- `docker/judgehost/Dockerfile.build` — adds `wget`, which the Kotlin download needs.
- `.github/workflows/build-judgehost-gehack.yml` — builds and publishes
  `ghcr.io/gehack/judgehost`, and prints the manifest digest to pin.

Nothing else diverges, so upstream stays mergeable. Both Dockerfiles deliberately stay on
`ubuntu:24.04`: only the chroot needs the newer toolchain, and moving the runtime image
would rebuild `runguard` against a glibc upstream does not test.

## Kotlin

Kotlin follows the recipe in the
[DOMjudge wiki](https://github.com/DOMjudge/domjudge/wiki/Adding-a-new-language):
download `kotlin-compiler-<version>.zip` from JetBrains, unzip it to
`/usr/local/lib/kotlinc` inside the chroot, and symlink `bin/kotlinc` onto the chroot's
`PATH`. The version and hash are pinned in `chroot-and-tar.sh`; bump them together with
the Kotlin version genix gives the workstations.

The symlink layout is not incidental. DOMjudge's stock `kt` compile script locates the
compiler with `dirname "$(realpath "$(command -v kotlinc)")"` and then expects
`../lib/kotlin-stdlib.jar` beside it, so both the `/usr/local/bin` symlink and the
`/usr/local/lib` unzip target have to stay as they are.

No compile or run script is written here: `kt` ships with DOMjudge. It only has to be
enabled in the jury interface (Languages → `kt` → "Allow submit" → Yes).

Rebuilding months from now picks up 26.04 point updates; only Kotlin is pinned by hash.

## Consumers

- `genix` — `modules/judgehost/judgedaemon.nix` pins this image by manifest digest. It
  must stop mounting its Nix chroot over `/chroot/domjudge`, or it will shadow this one.
- `domjudge-deployment` — `judgehost.yaml` still points at `domjudge/judgehost:bleeding`,
  which judges in upstream's Ubuntu 24.04 chroot.
