#!/bin/sh

set -x

git fetch origin
git rebase origin/master
git add CNAME _config.yml _includes index.html _posts README.md push.sh
git commit -a -m '.'
git push origin master

