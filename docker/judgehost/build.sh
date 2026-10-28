#!/bin/sh -eu

cd /domjudge-src/domjudge*
chown -R domjudge: .
# If we used a local source tarball, it might not have been built yet
sudo -u domjudge make configure
sudo -u domjudge ./configure --with-baseurl=http://localhost/ --disable-domserver-build --with-install-method=docker

echo "default	http://localhost/api	dummy	dummy" | sudo -u domjudge tee etc/restapi.secret > /dev/null

sudo -u domjudge make judgehost
make install-judgehost

startstop=/opt/domjudge/judgehost/lib/judge/chroot-startstop.sh
sed -i 's/^SUBDIRMOUNTS="etc usr lib bin"$/SUBDIRMOUNTS="etc usr lib bin nix"/' "$startstop"
grep -qx 'SUBDIRMOUNTS="etc usr lib bin nix"' "$startstop"
