#!/bin/sh

set -x

git add CNAME _config.yml _includes index.html _posts
git commit -a -m '.'
git fetch origin
git rebase origin/master
git push origin master

