# Best Practices for Commits, Branching and Versioning


Presenting conventional commits, branching models, semantic versioning, and source-based versioning in YAML format.

<!--more-->

---

## Conventional Commits

### Specification

```yaml
website:
  - https://www.conventionalcommits.org
  - https://github.com/commitizen/conventional-commit-types/blob/master/index.json

conventional_commits:
  feat:     new feature
  fix:      bug fix
  docs:     documentation only changes
  style:    changes that do not affect the meaning of the code, e.g., white-space, formatting, missing semi-colons
  refactor: code change that neither fixes a bug nor adds a feature
  perf:     code change that improves performance
  test:     adding missing tests or correcting existing tests
  build:    changes that affect the build system or external dependencies, e.g., gulp, broccoli, npm
  ci:       changes to our CI configuration files and scripts, e.g., Travis, Circle, BrowserStack, SauceLabs
  chore:    other changes that do not modify src or test files
  revert:   reverts a previous commit

structure: <type>(scope): <subject>

verb_aliases:
  fix:
    - resolve
    - handle
    - correct
    - prevent
    - update
```

### Examples

- With description and breaking change footer

  ```yaml
  feat: allow provided config object to extend other configs

  BREAKING CHANGE: `extends` key in config file is now used for extending other config files
  ```

- With `!` to draw attention to breaking change

  ```yaml
  feat!: send an email to the customer when a product is shipped
  ```

- With scope and `!` to draw attention to breaking change

  ```yaml
  feat(api)!: send an email to the customer when a product is shipped
  ```

- With both `!` and BREAKING CHANGE footer

  ```yaml
  chore!: drop support for Node 6

  BREAKING CHANGE: use JavaScript features not available in Node 6.
  ```

- With no body

  ```yaml
  docs: correct spelling of CHANGELOG
  ```

- With scope

  ```yaml
  feat(lang): add Polish language
  ```

- With multi-paragraph body and multiple footers

  ```yaml
  fix: prevent racing of requests

  Introduce a request id and a reference to latest request. Dismiss
  incoming responses other than from latest request.

  Remove timeouts which were used to mitigate the racing issue but are
  obsolete now.

  Reviewed-by: Z
  Refs: #123
  ```

- With a footer that references the commit SHA that is being reverted

  ```yaml
  revert: feat(lang): add Polish language

  This reverts commit 667ecc1654a317a13331b17617d973392f415f02.
  ```

## Branching Models

### Gitflow

```yaml
Gitflow:
  website:
    - https://nvie.com/posts/a-successful-git-branching-model/
    - https://www.atlassian.com/git/tutorials/comparing-workflows/gitflow-workflow
  description: Traditional workflow, suitable for projects with clear release cycles and multi-person collaboration
  branches:
    feature/*: feature development branches, e.g., feature/login, feature/JIRA-985-login
    bugfix/*:  fix known non-urgent defects, e.g., bugfix/sso-auth, bugfix/JIRA-211-sso-auth
    develop:   development integration branch, merge multiple features and bugfixes
    release/*: release candidate branches, e.g., release/1.6.2
    hotfix/*:  production hotfixes, e.g., hotfix/1.6.3
    main:      production stable branch
  workflow:
    # Development flow: feature/bugfix branches from develop, merge back to develop, then through release to main, and tag on main
    develop → feature/bugfix → develop → release → main → tag(vX.Y.Z)[recommended]
    # Emergency fix: hotfix branches from main, merge back to develop and main, and tag on main
    main → hotfix
              ↘ develop
              ↘ main → tag(vX.Y.Z)[recommended]
  advantages:
    - Clear branch roles, suitable for version management
    - Easy to manage release and fix processes
  disadvantages:
    - Many branches, complex CI/CD processes
    - Not suitable for high-frequency continuous delivery
  extensions:
    branches:
      user/<name>/*: personal branches, e.g., user/john/login, user/alice/sso-auth
      env/*:         environment branches, e.g., env/uat, env/prod
    notes:
      - user/<name>/* only for personal experiments or independent development, no guarantee of merge, avoid polluting formal feature branches
      - env/* only for tracking current deployment versions in each environment, no direct code development, updates through merge commits
```

### GitHub Flow

```yaml
GitHubFlow:
  website: https://docs.github.com/en/get-started/using-github/github-flow
  description: Simplified workflow, suitable for continuous delivery and small teams
  branches:
    main:      the only long-term branch, always in deployable state, whether to deploy depends on team strategy
    feature/*: feature branches derived from main
  workflow:
    # Feature development: feature branches from main, merge back to main through Pull/Merge Request
    # Release version: tag on main to mark deployable versions
    main → feature → main → tag(vX.Y.Z)[recommended]
  advantages:
    - Simple process, suitable for rapid iteration
    - Combined with Pull/Merge Request review
  disadvantages:
    - Lacks stable development integration branch
    - Version control depends on tags
```

### Trunk Based Development

```yaml
TrunkBasedDevelopment:
  website: https://trunkbaseddevelopment.com
  description: Trunk-based development, minimalist workflow, suitable for continuous integration/daily builds
  branches:
    main:      the only trunk branch
    feature/*: very short-term feature branches, quickly merge back to main
  workflow:
    # Feature development: feature branches from main, short-cycle development then quickly merge back to main
    # Continuous release: each main merge can trigger build and release
    main → feature → main → tag(vX.Y.Z)[optional]
  notes:
    - Due to frequent merges, usually use `datetime + commit_hash` as version number, e.g., 2025.07.30.19.06.3f9a7c1d
    - Semantic versioning (vX.Y.Z) only for important milestone tags
  advantages:
    - Supports high-frequency releases, automation CI/CD friendly
    - Avoids code drift from long-term branches
  disadvantages:
    - Requires strong testing and automation support
    - High requirements for team collaboration
```

### GitLab Flow

```yaml
GitLabFlow:
  website: https://about.gitlab.com/blog/gitlab-flow-duo/
  description: GitLab's officially recommended workflow, combines trunk development with environment branches, suitable for multi-environment CI/CD deployment
  branches:
    feature/*:   feature development branches, derived from main, merge back to main through Merge Request
    main:        main branch, for integration and testing, always in mergeable state
    staging:     pre-release environment branch, for pre-launch validation
    production:  production environment branch, tracks current online deployment version
  workflow:
    # Feature development: feature branches from main, merge back to main after completion
    # Deployment process: main merge to staging triggers pre-release, main merge to production triggers production deployment
    # Optional release: tag on production to mark production version
    main → feature → main
                       ↘ staging
                       ↘ production → tag(vX.Y.Z)[recommended]
  notes:
    - staging/production branches for tracking current deployment versions in each environment
    - Environment branch updates through merge commits, no direct code development on these branches
    - Recommend tagging when main merges to production to mark official release version
  advantages:
    - Supports multi-environment deployment, CI/CD friendly
    - Manages releases through environment branches, intuitive tracking of current deployment status
    - Keeps main branch clean, features controlled through Merge Request
  disadvantages:
    - Requires strict merge policies and CI/CD conventions
    - May be overly complex for small projects
```

## Version Management

### Label Naming

```yaml
version_label:
  snapshot: development snapshot
  alpha:    internal testing
  beta:     public testing
  rc:       release candidate
  release:  official release
  hotfix:   emergency fix
```

### Semantic Versioning

```yaml
semantic_versioning:
  website: https://semver.org
  format: MAJOR.MINOR.PATCH
  initial_development_version: 0.1.0
  description:
    MAJOR:
      description: major version number
      scenario: incompatible changes
      example: 0.12.8 → 1.0.0
      rule: major version +1, minor and patch versions reset to zero
    MINOR:
      description: minor version number
      scenario: backward-compatible feature additions
      example: 1.5.1 → 1.6.0
      rule: minor version +1, patch version resets to zero
    PATCH:
      description: patch version number
      scenario: backward-compatible bug fixes
      example: 1.6.1 → 1.6.2
      rule: patch version +1

  pre_release_versions:
    format: MAJOR.MINOR.PATCH-<label>[.<identifier>]
    labels:
      alpha: internal testing version
      beta:  public testing version
      rc:    release candidate
    examples:
      - 1.12.6-alpha
      - 1.12.6-beta
      - 1.12.6-rc.1
      - 1.12.6-rc.2

  metadata:
    format: MAJOR.MINOR.PATCH[-<label>]+<metadata>
    examples:
      - 1.12.6-alpha+3f9a7c1d
      - 1.12.7+20250730

  version_evolution_example: |
    0.1.0 → 0.1.1 → ...
      ↓
     ...
      ↓
    0.12.8
      ↓
    1.0.0
      ↓
     ...
      ↓
    1.5.1
      ↓
    1.6.0 → 1.6.1 → 1.6.2
      ↓
     ...
      ↓
    1.12.6-alpha(1.12.6-alpha+3f9a7c1d) → 1.12.6-beta → 1.12.6-rc.1 → 1.12.6-rc.2
      ↓
    1.12.7(1.12.7+20250730)
```

### Source-based Versioning

```yaml
source_based_versioning:
  format: <branch>-YYYYMMDDHHmm-<commit_hash>
  description:
    branch: branch name
    YYYYMMDDHHmm: build date and time
    commit_hash: short hash value (first 8 characters)
  examples:
    - feature-login-202507281802-c4d8b21e
    - develop-202507291752-b17e5a9f
    - main-202507301906-3f9a7c1d
  advantages:
    - Directly shows build source branch
    - Each version is unique and traceable to specific commit
    - Suitable for automated continuous integration
  extended_rules:
    with_release_labels:
      format: <branch>-YYYYMMDDHHmm-<commit_hash>-<label>
      labels:
        alpha: internal testing version
        beta:  public testing version
        rc:    release candidate
      examples:
        - main-202507301906-3f9a7c1d-alpha
```

### GitLab CI Version Generation

```yaml
# .gitlab-ci.magic-version.yml

variables:
  TAG_PREFIX: "v"                     # Define tag prefix, used to remove 'v' from tags like v1.2.3

# Version based on tag
version_tag:
  stage: magic_version
  rules:
    - if: $CI_COMMIT_TAG =~ /^.+/     # Only run when tag exists, /^.+/ means return true if there's any non-empty character
  script:
    # Get current tag, remove TAG_PREFIX, e.g., v1.2.3 -> 1.2.3
    - export MAGIC_VERSION=${CI_COMMIT_TAG#*"$TAG_PREFIX"}
    # Write version number to build.env for subsequent Jobs
    - echo "MAGIC_VERSION=$MAGIC_VERSION" >> build.env
  artifacts:
    reports:
      dotenv: build.env               # Export build.env as dotenv for subsequent Jobs to use $MAGIC_VERSION variable

# Version based on branch
version_branch:
  stage: magic_version
  rules:
    - if: $CI_COMMIT_BRANCH           # Run when building based on branch
  script:
    # Generate timestamp in YYYYMMDDHHmm format, e.g., 202507301906
    - VERSION_DATETIME=$(date +'%Y%m%d%H%M')
    # Concatenate version number: <branch>-YYYYMMDDHHmm-<commit_hash>
    # Example: main-202507301906-3f9a7c1d
    # Variable descriptions:
    #   $CI_COMMIT_REF_SLUG  -> branch name slug, e.g., feature-login / main
    #   $CI_COMMIT_SHORT_SHA -> current commit short hash (first 8 characters)
    - export MAGIC_VERSION=${CI_COMMIT_REF_SLUG}-${VERSION_DATETIME}-${CI_COMMIT_SHORT_SHA}
    # Write version number to build.env for subsequent Jobs
    - echo "MAGIC_VERSION=$MAGIC_VERSION" >> build.env
  artifacts:
    reports:
      dotenv: build.env               # Export build.env as dotenv for subsequent Jobs to use $MAGIC_VERSION variable
```

