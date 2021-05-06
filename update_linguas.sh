#!/bin/sh
# Used to regenerate LINGUAS files

set -x
set -e

dryrun=1

for i in $@; do
	if [ "$i" = "-f" ]; then
		dryrun=0
	fi
done

for i in *-l10n; do
	cd "$i/po"
	find . -name '*.po' | sed -e 's,./,,' -e 's,\.po$,,' > LINGUAS
	cd -

	if [ "$dryrun" != 1 ]; then
		cd "$i"
		git add po/LINGUAS
		git commit -m "Add missing LINGUAS files."
		git checkout maemo/beouwulf
		git merge master
		git checkout master
		cd -
	fi
done
