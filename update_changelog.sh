#!/bin/sh
# Updates the debian/changelog for all repos, tags, and pushes.
set -e

usage() {
	echo "usage: $(basename "$0") [-f] new@email"
	exit 1
}

[ -n "$1" ] || usage

dryrun=1
if [ "$1" = "-f" ]; then
	dryrun=0
	shift
fi

set -x

tag="$1"

for i in *-l10n; do
	cd $i

	name="$(dpkg-parsechangelog -S Source)"

	changelog="$(tac debian/changelog)"

	cat <<EOF | tac > debian/changelog
$changelog

 -- $(git config --get user.name) <$(git config --get user.email)>  $(date -R)

  * Tag new release

$name ($tag) unreleased; urgency=medium
EOF

	if [ "$dryrun" != 1 ]; then
		git add debian/changelog
		git commit -m 'Tag new release'
		git tag "$tag"
		git push
		git push --tags
		git checkout maemo/beowulf
		git merge master
		git push
		git checkout master
	fi

	cd -
done
