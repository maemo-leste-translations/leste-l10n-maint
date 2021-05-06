#!/bin/sh
# Depends: jq, curl

url="https://api.github.com/orgs/maemo-leste-translations/repos?page="

for i in $(seq 1 2); do
	repos="$(curl -s "${url}${i}" | jq -r '.[].ssh_url')"
	for i in $repos; do
		if ! [ -d "$(basename "$i" .git)" ]; then
			git clone "$i"
		else
			git -C "$(basename "$i" .git)" pull
		fi
	done
done
