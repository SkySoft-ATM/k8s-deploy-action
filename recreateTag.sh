#!/usr/bin/env sh
git push --delete origin v9 && git tag -d v9 && git tag -a -m "new tag" v9 &&  git push --follow-tags