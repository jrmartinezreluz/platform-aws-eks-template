# DNS

`base_domain` is a required **operator decision**. Empty string skips zone creation. Do not invent or purchase a domain in this phase. Do not keep the disposable private zone name as the new default.

When a domain is approved:

Recommended application hosts:

```text
<app>-dev.<domain>
<app>-staging.<domain>
<app>-uat.<domain>
<app>.<domain>
```

Private zone attached to the VPC when `private_zone=true`. Public ACME issuer is PENDING OPERATOR.
