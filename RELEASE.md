# Release Process for scale-network

Releases can be found: https://github.com/socallinuxexpo/scale-network/tags

Each release corresponds to a conference number. This repo was originally conceived sometime around Scale 16x so before this
time there was no open source codebase.

## Convention

The team has standardized on the following convention:

1. All releases (i.e. git tags) are made off the default branch, `master` in our case
1. All releases are immutable, regardless of functionality.
1. Releases are cut under `4 scenarios`:
   - Within the last month before the tech team arrives at the conference venue for setup
   - At the end of each day during the conference
   - After a significant change has be merged into the default branch during the conference
   - At the end of the conference
1. The release prefix maps to the corresponding scale conference number (e.g. a prefix of `18` would coorespond to `scale 18x`
   conference)
1. Releases ending in `.N` (e.g. `18.2`) are tags that were made leading up to and/or during the conference
1. Releases ending in `x` (e.g. `18x`) denote the final state of the repo at the end of the conference

## Creation

> This is currently only for the core maintainers of the scale tech team

1. You will need write access to the repo
1. Get an update to copy of the default branch:

```
cd scale-network
git checkout master
git pull --rebase origin master --tags
```

3. Check to see the latest tag and increment it by 1 (unless creating final state)

```
git tag
```

4. Create the new tag and push:

```
git tag -a -m "Release version xx.x of scale-network" xx.x
git push origin --tags
```
