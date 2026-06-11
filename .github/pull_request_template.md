# Pull Request

## What:
<!-- A brief description of what this PR does -->

## Why:
<!-- The reasoning or context behind this change -->

## Ticket:
<!-- Link to the relevant Jira/ticket, or 'N/A' if not applicable -->

## Risk:

**Risk level:** 🟢 / 🟠 / 🔴 <!-- delete as appropriate -->

**Reason for rating:**
<!-- One or two sentences explaining your assessment, especially for Amber or Red -->

───────────────────────────────────────────────────

Rate the overall risk of deploying this change:

🟢 Green  – Low risk. Good to go, standard review applies.

🟠 Amber  – Medium risk. Socialise with the team before merging.

🔴 Red    – High risk. Requires explicit approval from Thor or Neil before merging.

───────────────────────────────────────────────────

🟢 GREEN – things that are typically low risk:
───────────────────────────────────────────────────
- New tests or improved test coverage with no production code changes
- Dependency bumps with no API changes (minor/patch gems, npm packages)
- Copy or content changes to admin UI labels, hint text, or page titles
- Config/env var additions that are purely additive and have safe defaults
- Refactors with full test coverage and no behaviour change
- Adding or updating CloudWatch alarms or dashboards (read-only observability)
- Terraform formatting or variable renaming with no resource recreation
- Logging improvements or additional audit trail entries (additive only)

🟠 AMBER – things that need a team conversation first:
───────────────────────────────────────────────────
- Changes to how tariff data is displayed, edited, or validated in the admin UI
- New or modified API calls to the backend service
- Changes to authentication or authorisation logic (AUTH_STRATEGY, identity integration)
- Modifications to admin-only actions (section notes, measure management, quota controls)
- Adding or changing feature flags that affect live admin journeys
- Infrastructure changes that alter networking, security groups, or IAM permissions in non-production first
- Terraform changes that will cause a resource replacement (check plan output carefully)
- Changes to CI/CD pipeline steps or deployment order dependencies
- Removing or deprecating a route, controller action, or view still in use

🔴 RED – requires explicit approval from Thor or Neil:
───────────────────────────────────────────────────
- Changes to how measures, conditions, footnotes, or quotas are created or modified through the admin UI
- Modifications to the authentication mechanism or identity service integration
- Changes to admin user roles, permissions, or access control rules
- Any change to production AWS infrastructure that cannot be easily rolled back
- Secrets rotation or changes to how credentials are stored, scoped, or accessed
- Database migrations that are destructive (dropping columns/tables, removing indexes)
- Significant architectural shifts (e.g. new service boundaries or authentication providers)
