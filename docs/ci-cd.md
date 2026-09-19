# CI/CD

GitHub Actions assume IAM roles via OIDC.

Example subject (name form):

```text
repo:<github-owner>/<repository>:environment:nonprod
repo:<github-owner>/<repository>:environment:prod
```

GitHub may emit unique IDs:

```text
repo:<github-owner>@<orgId>/<repository>@<repoId>:environment:<env>
```

Inspect the token `sub` claim rather than copying another account's trust policy. The Terraform IAM module uses `repo:${var.github_org}@*/${repo}@*:environment:${env}`.
