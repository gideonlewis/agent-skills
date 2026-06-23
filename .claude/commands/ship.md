---
description: Deploy code to production with confidence and documentation
---

# /ship

Prepare and ship changes to production.

**Phase: SHIP**

When invoked:

1. **Final checks** — All tests passing? Code reviewed?
2. **Documentation** — README, API docs, migration guides updated?
3. **Versioning** — Semantic versioning (MAJOR.MINOR.PATCH)
4. **Changelog** — Document what changed and why
5. **Deployment** — Push to production (or create PR for approval)
6. **Monitoring** — Ensure observability is in place

Checklist:
- [ ] All tests pass locally
- [ ] Code reviewed and approved
- [ ] Documentation updated
- [ ] Version bumped (CHANGELOG.md, package.json, etc.)
- [ ] Migration guide written (if needed)
- [ ] Deployed or PR created
- [ ] Monitoring/alerts in place

Reference the `shipping-and-launch`, `ci-cd-and-automation`, and `observability-and-instrumentation` skills.
