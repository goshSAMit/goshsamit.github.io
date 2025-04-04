---
title: Git Commands
date: 2025-04-03
type: post
tags:
  - topics
  - git
showTableOfContents: true
---

## Steps to connect to a git repo
1. Create the repo on Github
2. Create a folder on your local device that you want to old the repo
3. git clone {repo_url_from_github}
4. git remote set-url origin {repo_url_from_github}
5. git config --global user.name “name"
6. git config --global user.email “email”
7. git branch newbranch
8. git checkout newbranch
9. make changes to code
10. git add .
11. git commit . -m "commit message"
12. git push origin main
13. Go to github and create a new pull request

## Steps to start a repo on local and push to github
- In Progress
## Various git commands
- git pull origin main ==> pulls from the main branch to local checked out branch
- git remote add {alias} {url} -> git remote add origin github.com/url
