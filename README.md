leste-l10n-maint
================

Maintenance tools for maemo-leste-translations.


Workflows
---------

**NOTE: All scripts dryrun git-related commands unless specified
`-f` as first(!) parameter.**

### Clone all repositories

```
mkdir leste-translations
cd leste-translations
git clone git@github.com:maemo-leste-translations/leste-l10n-maint
./leste-l10n-maint/clone_or_update_all.sh
```


### Change bug report email for all repos

```
./leste-l10n-maint/update_msgid_bug_report.sh new@email
```

### (Re)Generate LINGUAS files for all repos

```
./leste-l10n-maint/update_linguas.sh
```


### Create changelog entry, tag, and push for all repos

```
./leste-l10n-maint/update_changelog.sh 7.2
```

