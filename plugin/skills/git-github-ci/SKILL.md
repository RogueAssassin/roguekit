---
name: git-github-ci
description: Use for Git workflows, GitHub repositories, pull requests, branch management, GitHub Actions, CI builds, releases and changelogs.
---
# Git, GitHub and CI/CD
- Inspect status, branch, remotes and recent history before operating.
- Preserve unrelated working-tree changes and follow the repository's branch strategy.
- Review workflow triggers, permissions, secrets, caching, artifact contents and version propagation.
- Reproduce CI failures locally where practical and fix root causes rather than masking checks.
- Do not commit, push, merge, tag, publish or force-push unless explicitly requested.
- For releases, verify version consistency, changelog, documentation, build artifacts and rollback path.
- For repos that ship versioned releases (`VERSION`, `CHANGELOG.md`, `SECURITY.md`, upload notes): bump the version file, changelog, manifests and any version matrix together; record SHA-256 checksums for release archives; never commit generated release archives or secrets; if the user uploads through GitHub Desktop, write the exact list of files to include and exclude rather than pushing yourself.
