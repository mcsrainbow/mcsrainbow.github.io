# Using Git Worktree to Deploy GitHub Pages

#### Create an orphan branch gh-pages to initialize it in a clean way

```sh
git checkout --orphan gh-pages
git reset --hard
git commit --allow-empty -m "First empty commit"
git checkout main
```

#### Mount the branch gh-pages as a subdirectory

```sh
rm -rf public
git worktree add public gh-pages
```

#### Deploy Hugo site to branch gh-pages

```sh
# Remove all existing files in public folder
rm -rf public/*

# Generate Hugo site
hugo

# Go into worktree subdirectory of branch gh-pages
cd public

# Deploy Hugo site
git add --all

# Commit all changes to branch gh-pages
commit_msg="Update site on $(date '+%b %d, %Y')"
git commit -m "$commit_msg"

# Push to branch gh-pages
git push origin gh-pages
```

#### Set GitHub Pages to deploy from branch gh-pages

Settings - Pages - Branch - gh-pages - / (root) - Save
