#!/bin/sh
# Used to change the email for Report-Msgid-Bugs-To in .po and .pot files.
set -e

usage() {
	echo "usage: $(basename "$0") new@email"
	exit 1
}

[ -n "$1" ] || usage

dryrun=1
if [ "$1" = "-f" ]; then
	dryrun=0
	shift
fi

set -x
newemail="$1"

for i in *-l10n; do
	cd "$i/po"

	for j in *.po *.pot; do
		sed "s,^\"Report-Msgid-Bugs-To: .*\",\"Report-Msgid-Bugs-To: $newemail\\\n\"," \
			-i "$j"
	done

	if [ "$dryrun" != 1 ]; then
		git add *.po *.pot
		git commit -m 'Update Report-Msgid-Bugs-To'
		git checkout maemo/beowulf
		git merge master
		git checkout master
	fi

	cd -
done
