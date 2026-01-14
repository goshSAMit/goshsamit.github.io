---
title: Git Commands
date: 2025-04-03
type: post
tags:
  - topics
  - git
showTableOfContents: true
---

## Steps to connect to a Github repository
1. Create the repository (repo) on Github
2. Create a folder on your local device that you want to hold the repo
3. Run the following command to clone the Github repository
```
git clone repo_url_from_github
```
4. Run the following command to link "origin" to github url
```
git remote set-url origin repo_url_from_github
```
5. Run the following commands to link your commits to your name and email address
```
git config --global user.name “name"
git config --global user.email “email”
```
7. Run the following command to create a new branch on local
```
git branch newbranchname
```
7. Run the following branch to "checkout" and make changes to branch on local
```
git checkout newbranch
```
8. Run the following command to add all the files in the directory to the initialized git repo
```
git add .
```
9. Run the following command to commit all the changes and add a message detailing the changes
```
git commit -m "commit message"
```
10. Run the following command to push the local branch to Github
```
git push -u origin <branch-name>
```
10. Go to Github and create a new pull request to merge the new branch into the main branch

## Steps to start a repo on local and push to github
1. In command prompt/terminal, navigate to home directory of local project
2. Run the following command to initialize the directory as a git repository
```
git init
```
3. Run the following command to add all the files in the directory to the initialized git repo
```
git add .
```
4. Run the following command to commit all the changes and add a message detailing the changes
```
git commit -m "initial commit"
```
5. Run the following command to push local main repo to a remote repo (you will need to create a new empty repo in github for this example)
```
git remote add <url-of-remote-repo-from-github>
```
6. For your initial push to github, run the following command, otherwise, you can remove the "-u"
```
git push -u origin <branch-name>
```

## Various git commands
- pulls from the main branch to local checked out branch
```
git pull -u origin <branch-name>
```

