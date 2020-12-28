#!/bin/bash

if [[ $(git status -s) ]]; then
  echo "The working directory is dirty, please commit all pending changes."
  exit 1;
fi

echo -e "\033[0;32mDeploying updates to GitHub...\033[0m"

echo "Deleting old public folder..."
rm -rf public
mkdir public
git worktree prune
rm -rf .git/worktrees/public/

echo "Checking out main branch into public..."
git worktree add -B main public origin/main

echo "Removing existing files in public folder..."
rm -rf public/*

echo "Generating blog..."
hugo

echo "Updating main branch..."
cd public && git add --all 

msg="Rebuild blog on $(date '+%b %d, %Y')"
if [ $# -eq 1 ]; then
  msg="$1"
fi
git commit -m "$msg"

git push -f origin main

cd ..
