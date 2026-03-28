---
title: Git Submodule
date: 2026-03-06
type: post
tags:
  - topics
  - git
  - ansible
---
## Intro
Git Submodules allow developers to use existing projects inside their current project. For example, I have created a github project that will house all of my Infrastructure-as-code work. While I could always create my own ansible playbook from scratch, I decided to use the existing [k3s-ansible]((https://github.com/k3s-io/k3s-ansible) repo. 

## How to use a Git Submodule
- In this example, I will be using the [k3s-ansible]((https://github.com/k3s-io/k3s-ansible) repo and Github.
### 1. Create a Fork
- Go to the repo's Github page and click the Fork button at the top right of the page.
- This will put the repo under your account, so you can make changes to it as you like, without having to create a merge request to edit the overall project.

### 2. Update the submodule remote

- Inside your project, create a directory where your forked repo will be house. 
```bash
mkdir ansible/k3s-ansible
```
- Set the remote url for this directory as the url to the forked repo under your account.
```bash
cd ansible/k3s-ansible
git remote set-url origin https://github.com/YOUR_USERNAME/k3s-ansible
git remote -v  # verify it changed
```

### 3. Make changes if needed
- That's mostly it. Now you can use and edit that forked project as much or as little you need. 
### 4. Commit any changes to your submodule

- It is important to remember to commit and push any changes in your submodule to its remote BEFORE the main project. If the main project is first, it can cause problems where your main project is pointing to a commit that doesn't actually exist yet.

```bash
cd ansible/k3s-ansible
git add .
git commit -m "your message"
git push origin main
```

### 5. Commit changes to your main repo
- Move back to the main directory of the repo and commit/push your changes when you're ready.

```bash
cd ../..
git add .
git commit -m "your message"
git push origin main
```

## Upstream Syncing
- If you want to keep your submodule fork up-to-date with the original repo, you will have to sync your submodule from upstream.

### How to sync when you want to

### 1. Add the upstream remote once:

```bash
cd ansible/k3s-ansible
git remote add upstream https://github.com/k3s-io/k3s-ansible
```

### 2. Pull changes as desired:

```bash
git fetch upstream
git merge upstream/main
# resolve any conflicts
git push origin main
```