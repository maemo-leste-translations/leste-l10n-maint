#!/bin/sh
# This script was used to create and import all repositories from
# existing fremantle l10n packages.

# gh is https://github.com/cli/cli

set -x
set -e

usage() {
	echo "usage: $(basename "$0") foo-bar-l10n"
	exit 1
}

[ -n "$1" ] || usage

repo="$1"

mkdir -p "$repo/debian" "$repo/po"

cp "$repo-"*.deb "$repo"

cd "$repo"

langs="$(ls *.deb | awk -F_ '{print $1}' | awk -F- '{print $NF}')"

ar x *l10n-mr0_*.deb
tar xf control.tar.gz
tar xf data.tar.gz

depends="$(grep ^Depends: control | cut -d' '  -f2-)"
provides="$(grep ^Provides: control | cut -d' ' -f2-)"
name="$(echo "$repo" | sed 's/-l10n//')"

gunzip -c usr/share/doc/*/changelog.gz > debian/changelog
rm -rf usr *.tar.gz control md5sums debian-binary

cat <<EOF > debian/control
Source: $repo
Section: misc
Priority: optional
Maintainer: Ivan J. <parazyd@dyne.org>
Build-Depends: debhelper-compat (= 12), gettext
Standards-Version: 4.3.0

Package: $repo-mr0
Section: misc
Architecture: all
Provides: $provides
Depends: $depends
Description: $name marketing release package
 This is a metapackage for $name to pull all the l10n packages.
 Application developers of $name should depend on
 "${repo}-mr0 | ${repo}-mr"
 to ensure correct locales are getting installed.
EOF

for lang in $langs; do
	if [ "$lang" = mr0 ]; then
		cat <<EOF > README.md
# $name

gettext source files for $name
EOF
		continue
	fi

	ar x "${repo}-${lang}"_*.deb
	tar xf data.tar.gz
	lng="$(ls usr/share/locale)"

	msgunfmt usr/share/locale/$lng/LC_MESSAGES/*.mo > "po/$lng.po"

	if [ "$lang" = engb ]; then
		msgunfmt usr/share/locale/$lng/LC_MESSAGES/*.mo > "po/$name.pot"
	fi

	cat <<EOF >> debian/control

Package: $repo-$lang
Section: misc
Architecture: all
Description: language files for $name ($lng)
 Language files for $lng $name.
EOF

	rm -rf usr *.tar.gz control md5sums debian-binary
done

cat <<EOF > debian/gbp.conf
[DEFAULT]
upstream-tag=%(version)s
EOF

cat <<EOF > debian/rules
#!/usr/bin/make -f

TEXT_DOMAIN=\$(shell sed -n 's/^Source: \(.*\)-l10n\$\$/\1/; t e; b; :e; p; q' debian/control)
LANGS=\$(shell echo po/*.po|sed -e 's,po/,,g' -e 's/.po//g')
FMTPARAMS=--statistics

%:
	dh \$@

override_dh_auto_build:
	sh -c 'a=0; for lang in \$(LANGS); do msgfmt -o /dev/null -c po/\$\$lang.po || a=1; done; if [ \$\$a = 1 ]; then exit 1; fi'
	msgfmt -o /dev/null -c po/\$(TEXT_DOMAIN).pot
	@for lang in \$(LANGS) ; do \\
		targetdir="\$(CURDIR)/debian/\$(TEXT_DOMAIN)-l10n-\`echo \$\$lang|tr [A-Z] [a-z]|tr -d _\`/usr/share/locale/\$\$lang/LC_MESSAGES" ;\\
		[ -d "\$\$targetdir" ] || mkdir -p \$\$targetdir ; \\
		echo -n "\$\$lang.po: "; \\
		msgfmt -v \$(FMTPARAMS) po/\$\$lang.po -o \$\$targetdir/\$(TEXT_DOMAIN).mo || exit 1; \\
	done

override_dh_prep:
	@echo Skip dh_prep
EOF

chmod +x debian/rules

rm *.deb

version="$(dpkg-parsechangelog -S Version | cut -d'+' -f1)"

golegnahc="$(tac debian/changelog)"
cat <<EOF | tac > debian/changelog
$golegnahc

 -- $(git config --get user.name) <$(git config --get user.email)>  $(date -R)

  * Initial Maemo Leste packaging

$repo (7.0) unstable; urgency=medium
EOF

git init
git add .
git commit -m 'Initial import'
git tag 7.0
gh repo create "maemo-leste-translations/${repo}" \
	-y -d "$name localization" --public

git push
git push --tags

git checkout -b maemo/beowulf
git push
