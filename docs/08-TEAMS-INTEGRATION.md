# 08-TEAMS-INTEGRATION.md

## Goal
Provide a repeatable hand-off package that helps customers connect an existing Cortex Analyst semantic view (for example, `VW_CORTEX_ANALYST_SALES_CALL_ACTIVITY`) to the Snowflake Cortex Agents Microsoft Teams integration while documenting the guardrails and validation steps we cannot execute without direct Teams access.

## Liability & Validation Notice
We validated every Snowflake-side artifact (SQL templates, RBAC guidance, cleanup automation) inside this repository. We cannot exercise or verify the Microsoft Teams tenant configuration, OAuth consent prompts, or end-user chat flows because we do not have access to the customer’s Microsoft 365 environment. Customers must:

- Perform all Microsoft Teams and Azure admin tasks in their tenant and confirm the consent banners, security policies, and Teams UI flows operate as expected.
- Run a production smoke test (for example, using the `agent:run` REST call shown below or by chatting in Teams) before broad rollout.
- Accept responsibility for tenant-level configuration, Teams app governance, and any regressions introduced by conditional access or network controls.

Document all customer-run validations (screenshots, query IDs, Teams transcripts) before promoting to production.

## Prerequisites
- Snowflake role with `ACCOUNTADMIN` or equivalent rights to create security integrations, warehouses, and Cortex Agents.
- Microsoft Entra ID Global Administrator to approve the Snowflake Cortex Agents application and capture the tenant ID.[^teams-setup]
- Cortex AI, Cortex Analyst, and Cortex Agents enabled in the Snowflake account.
- Existing curated semantic view (`VW_CORTEX_ANALYST_SALES_CALL_ACTIVITY`) published in the customer database with governed access and up-to-date documentation.
- Agreement with the business owner on which warehouse will power Teams traffic (default: `SFE_CORTEX_AGENTS_WH`).

## Step 1 – Align Data & RBAC
1. Confirm the semantic view compiles and returns data from the target warehouse:
   ```sql
   USE ROLE <DATA_OWNER_ROLE>;
   USE WAREHOUSE <ANALYST_WH>;
   DESCRIBE VIEW <DB>.<SCHEMA>.VW_CORTEX_ANALYST_SALES_CALL_ACTIVITY;

   SELECT COUNT(*) AS rowcount_2024
   FROM <DB>.<SCHEMA>.VW_CORTEX_ANALYST_SALES_CALL_ACTIVITY
   WHERE PLAN_YEAR = 2024
   LIMIT 1;
   ```
2. Identify every underlying table the semantic view reads. Grant the Teams-facing role read access to the view and base tables only (avoid schema-wide grants).
3. Capture any row-access or masking policies that may alter the result set so you can communicate expected behavior back to the business users.

## Step 2 – Create or Update Snowflake Infrastructure
1. Run the setup scripts (Snowsight Workspace or Snow CLI):
   ```sql
   -- Foundation objects, warehouse, and OAuth integration template
   @@sql/01_setup/01_create_demo_objects.sql
   @@sql/01_setup/04_create_security_integration.sql   -- Replace YOUR_TENANT_ID with the real value
   ```
   The security integration must match the doc template (`EXTERNAL_OAUTH_TYPE = AZURE`, issuer and JWS URLs with the tenant ID, audience `5a840489-78db-4a42-8772-47be9d833efe`, and `EXTERNAL_OAUTH_ANY_ROLE_MODE = 'ENABLE'`).[^security-template]
2. Mirror the tenant configuration steps in Azure (tenant-wide consent, Entra ID app visibility) using the official quickstart.[^teams-setup]
3. If the customer already uses network policies or Private Link, flag that the Teams integration cannot operate until those controls are disabled.[^limitations]

## Step 3 – Register the Cortex Agent
Use the updated template in `sql/01_setup/03_create_cortex_agent.sql` (Option C) to register a production-ready agent:

1. Update the JSON payload with the customer database, schema, semantic view path, preferred orchestration model, and instruction set.
2. Execute the `POST /api/v2/databases/{db}/schemas/{schema}/agents` request with a Snowflake Personal Access Token (PAT) or OAuth token that maps to an ACCOUNTADMIN-level user. Store tokens in a secure secret manager or environment variable (`$PAT` in the example) and never commit them to source control.
3. Immediately follow with the `agent:run` smoke test payload to ensure the agent generates grounded SQL before surfacing it in Teams.

Example payloads are embedded in the SQL file and summarized below:
```bash
# Create or replace the analytics agent
curl -X POST "$SNOWFLAKE_ACCOUNT_BASE_URL/api/v2/databases/SNOWFLAKE_EXAMPLE/schemas/CORTEX_DEMO/agents" \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--header "Authorization: Bearer $PAT" \
--data '{
  "name": "SALES_CALLS_ANALYST",
  "instructions": {
    "system": "You are a revenue operations analyst...",
    "response": "Lead with the requested metric...",
    "sample_questions": ["Show quarterly call volume...", "Which distributors had a 10 percent decline..." ]
  },
  "tools": [
    {
      "tool_spec": {
        "type": "cortex_analyst_text_to_sql",
        "name": "sales_calls_analyst",
        "description": "Structured analytics over VW_CORTEX_ANALYST_SALES_CALL_ACTIVITY"
      }
    }
  ],
  "tool_resources": {
    "sales_calls_analyst": {
      "semantic_view": "<DB>.<SCHEMA>.VW_CORTEX_ANALYST_SALES_CALL_ACTIVITY",
      "execution_environment": {"type": "warehouse", "warehouse": "SFE_CORTEX_AGENTS_WH"},
      "query_timeout": 90
    }
  }
}'
```

```bash
# Smoke test the agent
curl -X POST "$SNOWFLAKE_ACCOUNT_BASE_URL/api/v2/cortex/agent:run" \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--header "Authorization: Bearer $PAT" \
--data '{
  "agent_id": {"database": "SNOWFLAKE_EXAMPLE", "schema": "CORTEX_DEMO", "name": "SALES_CALLS_ANALYST"},
  "messages": [
    {
      "role": "user",
      "content": [{"type": "text", "text": "Which manufacturers increased call volume by at least 5 percent quarter over quarter?"}]
    }
  ]
}'
```

Record the generated SQL and result sample. If the call fails, consult the troubleshooting matrix below before escalating.

## Step 4 – Grant Production Access
1. Choose a dedicated Teams access role (template in `sql/01_setup/05_grant_permissions.sql`, Option 3).
2. Grant usage on the semantic view, supporting tables, execution warehouse, and the new agent to that role.
3. Assign the role to pilot users as a secondary role so their standard default role remains unchanged:
   ```sql
   GRANT ROLE SALES_CALLS_AGENT_ROLE TO USER <SALES_MANAGER_USER>;
   ALTER USER <SALES_MANAGER_USER> SET DEFAULT_SECONDARY_ROLES = ('ALL');
   ```
4. Update the cleanup procedure (`sql/99_cleanup/teardown_all.sql`) if you introduce additional roles, warehouses, or search services.

## Step 5 – Link Snowflake to Microsoft Teams
1. Azure administrator installs the Snowflake Cortex Agents app from Microsoft AppSource and approves tenant consent.[^teams-setup]
2. Snowflake administrator (with the security integration created above) connects the Snowflake account inside Teams:
   - Launch the Teams app.
   - Choose **Add account** → supply account URL, role, and warehouse context.
   - Select the `SALES_CALLS_ANALYST` agent.
3. Validate sign-in prompts, conditional access policies, and MFA flows. Capture screenshots to accompany the delivery package.
4. Remind customers that network policies and Private Link connections must remain disabled for this integration.[^limitations]

## Step 6 – Business Validation Checklist
- [ ] Run at least three production questions in Teams and confirm the answers match existing BI dashboards.
- [ ] Confirm that RBAC, masking, and row access policies behave as expected for multiple roles (sales rep vs. manager).
- [ ] Verify that the agent cites the semantic view name and data freshness in its responses per the instruction template.
- [ ] Capture the Teams conversation IDs and related `QUERY_HISTORY` entries for audit.
- [ ] Update local runbooks with customer-specific warehouse sizing or throttling thresholds.

## Troubleshooting Quick Reference
| Symptom | Likely Cause | Resolution |
|---------|--------------|------------|
| Error 390303: Invalid OAuth access token | Tenant ID mismatch in security integration | Re-run `DESCRIBE SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION` and confirm issuer/JWS URLs include the correct tenant ID.[^security-template] |
| Error 390304: Incorrect username or password | Snowflake user login/email does not match Entra ID UPN | Align `LOGIN_NAME` or `EMAIL_ADDRESS` with Entra ID and update `EXTERNAL_OAUTH_TOKEN_USER_MAPPING_CLAIM` if necessary.[^security-template] |
| Teams UI cannot connect to Snowflake | Network policy or Private Link enforced | Disable network policies/Private Link for the account while using the integration.[^limitations] |
| Agent response lacks data | User’s default role missing grants or semantic view filters out their rows | Ensure the Teams session role (default role plus secondary roles set to `ALL`) has `USAGE` and `SELECT` grants on the governed objects.[^rbac] |

## Cleanup & Rollback
To remove the demo or revert a failed pilot, run `sql/99_cleanup/teardown_all.sql` (after uncommenting the safety flag). The script revokes grants, drops custom roles (`CORTEX_AGENT_USERS`, `SALES_CALLS_AGENT_ROLE`), removes the schema and warehouse, and preserves shared assets (`SNOWFLAKE_EXAMPLE` database, `SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION`). Document any additional customer-specific objects you create so the teardown can be extended before handing it off.

## Deliverables Checklist
- Updated SQL templates (`sql/01_setup/03_create_cortex_agent.sql`, `sql/01_setup/05_grant_permissions.sql`, `sql/99_cleanup/teardown_all.sql`).
- This guide (`docs/08-TEAMS-INTEGRATION.md`).
- Internal context notes in `.cursor/STATUS_TEAMS_CONTEXT.md` and `.cursor/STATUS_TEAMS_DOCS.md`.
- Customer test evidence (to be supplied by customer).

## References
- Snowflake Docs – *Cortex Agents for Microsoft Teams and Microsoft 365 Copilot* (setup flow, authentication, limitations)[^teams-setup][^limitations]
- Snowflake Docs – *Create security integration for Entra ID* (parameter reference and troubleshooting)[^security-template]
- Snowflake Docs – *Cortex Agents security considerations* (RBAC enforcement details)[^rbac]

[^teams-setup]: [Cortex Agents for Microsoft Teams and Microsoft 365 Copilot – Set up integration](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-teams-integration)
[^security-template]: [Security integration template for Microsoft Teams integration](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-teams-integration#snowflake-security-integration)
[^limitations]: [Integration limitations (network policies, Private Link, regional consent)](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-teams-integration#current-limitations)
[^rbac]: [Authentication flow and RBAC enforcement](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-agents-teams-integration#role-based-access-control)
