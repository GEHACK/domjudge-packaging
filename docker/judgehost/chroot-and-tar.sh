#!/bin/bash

set -euo pipefail

RELEASE=resolute #Contains the more up to date releases
CHROOTDIR=/chroot/domjudge
ln -sf gutsy "/usr/share/debootstrap/scripts/$RELEASE"
sed -i 's/default-jdk-headless default-jre-headless/openjdk-21-jdk-headless openjdk-21-jre-headless/g' \
	/opt/domjudge/judgehost/bin/dj_make_chroot

/opt/domjudge/judgehost/bin/dj_make_chroot -D Ubuntu -R "$RELEASE"

KOTLIN_VERSION=2.4.20
KOTLIN_SHA256=59e9ca74c7904ef2c122b12114937673ccce68de820a663f0ed66ccf8799e0b7

echo "[..] Installing Kotlin $KOTLIN_VERSION into the chroot"
wget -q "https://github.com/JetBrains/kotlin/releases/download/v$KOTLIN_VERSION/kotlin-compiler-$KOTLIN_VERSION.zip" \
	-O /kotlin-compiler.zip
echo "$KOTLIN_SHA256  /kotlin-compiler.zip" | sha256sum -c -
unzip -qq -d "$CHROOTDIR/usr/local/lib/" /kotlin-compiler.zip
chroot "$CHROOTDIR" ln -s /usr/local/lib/kotlinc/bin/kotlinc /usr/local/bin/kotlinc
rm /kotlin-compiler.zip


cd /
echo "[..] Compressing chroot"
tar -czpf /chroot.tar.gz --exclude=/chroot/tmp --exclude=/chroot/proc --exclude=/chroot/sys --exclude=/chroot/mnt --exclude=/chroot/media --exclude=/chroot/dev --one-file-system /chroot
echo "[..] Compressing judge"
tar -czpf /judgehost.tar.gz /opt/domjudge/judgehost
