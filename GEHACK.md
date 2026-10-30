# GEHACK fork of domjudge-packaging

This fork exists for one reason: the GEHACK judgehosts judge in a chroot built by Nix from
the exact toolchain the contest workstations run, and upstream's `judgehost` image cannot
judge in such a chroot.

The toolchain itself is not defined here. `genix` publishes it as the image
`ghcr.io/gehack/genix/genix-chroot` (`chroot/Containerfile`: gcc, pypy3, JDK 21, Kotlin from
Nix, symlinked into `/usr/local/bin`), and this image's build turns that image into
`/chroot/domjudge` with upstream's `dj_make_chroot_docker`.

An earlier version of this fork instead bootstrapped an Ubuntu 26.04 chroot and installed
Kotlin from JetBrains to approximate the workstation versions. That drifted as soon as
genix's `flake.lock` moved (gcc 15.2.0 vs 15.3.0, Kotlin 2.4.20 vs 2.3.21), which is what
the Nix chroot rules out.

## What is changed

- `docker/judgehost/build.sh` — adds `nix` to `SUBDIRMOUNTS` in the installed
  `chroot-startstop.sh`. That script bind-mounts only `etc usr lib bin lib64` from the
  chroot into each judging, so without this every binary in a Nix chroot, which lives in
  `/nix/store`, is missing at compile and run time even though a plain
  `chroot /chroot/domjudge g++ --version` works.
- `docker/judgehost/chroot-and-tar.sh` — builds the chroot from the genix chroot image
  with `dj_make_chroot_docker` instead of debootstrapping upstream's default one.
- `docker/judgehost/Dockerfile.build` — adds `curl`, which `dj_make_chroot_docker` needs
  to download the temporary Docker it extracts the image with, since the build container
  has none.
- `docker/judgehost/scripts/start.sh` — copies `resolv.conf` into the chroot only when
  its `etc` is writable, since the Nix chroot is a read-only store path.
- `.github/workflows/build-gehack.yml` — builds `ghcr.io/gehack/judgehost` and an
  unmodified `ghcr.io/gehack/domserver` from one DOMjudge git ref (`main` by default, so
  the newest commit rather than upstream's weekly `bleeding` snapshot), and prints the
  commit and the manifest digests to pin. Judgehost and domserver must run the same
  DOMjudge version, which is why both come from this one build.

Nothing else diverges, so upstream stays mergeable.

## Consumers

- `genix` — `modules/judgehost/judgedaemon.nix` pins this image by manifest digest and
  mounts its own chroot into it.
- `domjudge-deployment` — `domserver.yaml` and `judgehost.yaml` still point at upstream's
  `domjudge/*:bleeding`; the judgehost there judges in upstream's Ubuntu chroot, not on
  the contest toolchain, and the domserver is not the version genix's judgehost runs.
