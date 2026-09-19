# Registry

Canonical repositories (immutable tags, scan on push, lifecycle keep 30 `sha-` tags):

- `hospitality-booking/frontend`
- `hospitality-booking/backend`
- `enterprise-erp/app`
- `workflow-automation/app`

Created once with the nonprod eks stack. Prod pulls the same names/digests (build once / promote many). Pass `ecr_repository_arns` into prod if a prod push role is required.

Do not tag `latest`. Do not rebuild for production.
