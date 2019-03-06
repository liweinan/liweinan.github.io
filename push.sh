git fetch origin
git rebase origin/master
git add CNAME _config.yml Gemfile _includes index.md _posts README.md push.sh
git commit -a -m '.'
git push origin master

