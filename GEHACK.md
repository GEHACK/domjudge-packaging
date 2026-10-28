# GEHACK fork of domjudge-packaging

This fork exists for one reason: the GEHACK judgehosts judge in a chroot built by Nix from
the exact toolchain the contest workstations run, and upstream's `judgehost` image cannot
judge in such a chroot.

The chroot itself is not built here. `genix` builds it from the team machines' own
`pkgs.contestToolchain` (gcc, pypy3, JDK 21, Kotlin), so judge and workstation share store
paths and therefore compiler bits, and every `nix flake update` moves both together. Its
judgehost bind-mounts that chroot read-only over `/chroot/domjudge` in this image. See
`genix` `modules/judgehost/chroot.nix`.

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
- `docker/judgehost/chroot-and-tar.sh` — still builds upstream's default chroot, so the
  image judges on its own, and adds the empty `/nix` that `chroot-startstop.sh check` now
  requires.
- `docker/judgehost/scripts/start.sh` — copies `resolv.conf` into the chroot only when
  its `etc` is writable, since the Nix chroot is a read-only store path.
- `.github/workflows/build-judgehost-gehack.yml` — builds and publishes
  `ghcr.io/gehack/judgehost`, and prints the manifest digest to pin.

Nothing else diverges, so upstream stays mergeable.

## Consumers

- `genix` — `modules/judgehost/judgedaemon.nix` pins this image by manifest digest and
  mounts its own chroot into it.
- `domjudge-deployment` — `judgehost.yaml` still points at `domjudge/judgehost:bleeding`,
  which judges in upstream's Ubuntu chroot, not on the contest toolchain.
