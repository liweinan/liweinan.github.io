#!/usr/bin/sh
jekyll build
git add assets CNAME _config.yml Gemfile _includes index.md _layouts _posts README.md _site
git commit -a -m '.'
git push origin master

