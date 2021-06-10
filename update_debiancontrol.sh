#!/bin/sh
# Regenerates debian/control to potentially add new languages.
set -e

dryrun=1
if [ "$1" = "-f" ]; then
	dryrun=0
	shift
fi

set -x

for i in *-l10n; do
	cd "$i"

	name="$(dpkg-parsechangelog -S Source)"

	cat <<EOF > debian/control
Source: ${name}
Section: misc
Priority: optional
Maintainer: Ivan J. <parazyd@dyne.org>
Build-Depends: debhelper-compat (= 12), gettext
Standards-Version: 4.3.0

Package: ${name}-mr0
Section: misc
Architecture: all
Provides: ${name}-mr
Depends:
Description: ${name} marketing release package
 This is a metapackage for ${name} to pull all the l10n packages.
 Application developers of ${name} should depend on
 "${name}-mr0 | ${name}-mr"
 to ensure correct locales are getting installed.
EOF

	for po in po/*.po; do
		lang_name="$(basename "$po" .po)"
		lang_lower="$(printf "%s" "$lang_name" | tr '[A-Z]' '[a-z]' | tr -d '_')"
		lang_pkg_name="${name}-${lang_lower}"

		sed \
			-e "s/^Depends:/&\n ${lang_pkg_name},/" \
			-i debian/control

		cat <<EOF >> debian/control

Package: ${lang_pkg_name}
Section: misc
Architecture: all
Description: language files for $(printf "%s" "${name}" | sed 's/-l10n//') (${lang_name})
 Language files for ${lang_name} $(printf "%s" "${name}" | sed 's/-l10n//').
EOF
	done

	if [ "$dryrun" != 1 ]; then
		git add debian/control
		git commit -m 'Update debian/control'
		git checkout maemo/beowulf
		git merge master
		git checkout master
	fi

	cd -
done
