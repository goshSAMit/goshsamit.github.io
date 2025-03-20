#!/bin/bash
set -euo pipefail

# Change to the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Set variables for Obsidian to Hugo copy
obsidianPostsPath="/home/sam/Documents/Obsidian Vault/posts"
hugoPostsPath="/home/sam/website/goshsamit.github.io/content/posts"
obsidianPagesPath="/home/sam/Documents/Obsidian Vault/posts"
hugoContentPath="/home/sam/website/goshsamit.github.io/content"

# Set GitHub Repo
myrepo="goshsamit.github.io"

# Check for required commands
for cmd in git rsync python3 hugo; do
    if ! command -v $cmd &> /dev/null; then
        echo "$cmd is not installed or not in PATH."
        exit 1
    fi
done

# Step 1: Check if Git is initialized, and initialize if necessary
if [ ! -d ".git" ]; then
    echo "Initializing Git repository..."
    git init
    git remote add origin $myrepo
else
    echo "Git repository already initialized."
    if ! git remote | grep -q 'origin'; then
        echo "Adding remote origin..."
        git remote add origin $myrepo
    fi
fi

# Step 2: Sync posts from Obsidian to Hugo content folder using rsync
echo "Syncing posts from Obsidian..."

if [ ! -d "$obsidianPostsPath" ]; then
    echo "Source path does not exist: $obsidianPostsPath"
    exit 1
fi

if [ ! -d "$hugoPostsPath" ]; then
    echo "Destination path does not exist: $hugoPostsPath"
    exit 1
fi

rsync -av --delete "$obsidianPostsPath" "$hugoPostsPath"

if [ ! -d "$obsidianPagesPath" ]; then
    echo "Source path does not exist: $obsidianPagesPath"
    exit 1
fi

if [ ! -d "$hugoContentPath" ]; then
    echo "Destination path does not exist: $hugoContentPath"
    exit 1
fi

rsync -av --delete "$obsidianPagesPath" "$hugoContentPath"

# Step 3: Process Markdown files with Python script to handle image links
echo "Processing image links in Markdown files..."
if [ ! -f "images.py" ]; then
    echo "Python script images.py not found."
    exit 1
fi

if ! python3 images.py; then
    echo "Failed to process image links."
    exit 1
fi

# Step 4: Build the Hugo site
echo "Building the Hugo site..."
if ! hugo; then
    echo "Hugo build failed."
    exit 1
fi

# Step 5: Add changes to Git
echo "Staging changes for Git..."
if git diff --quiet && git diff --cached --quiet; then
    echo "No changes to stage."
else
    git add .
fi

# Step 6: Commit changes with a dynamic message
# commit_message="New Blog Post on $(date +'%Y-%m-%d %H:%M:%S')"
echo "Please enter a commit message: "
read commit_message
if git diff --cached --quiet; then
    echo "No changes to commit."
else
    echo "Committing changes..."
    git commit -m "$commit_message"
fi

# Step 7: Push all changes to the main branch
echo "Deploying to GitHub Main..."
if ! git push origin main; then
    echo "Failed to push to main branch."
    exit 1
fi