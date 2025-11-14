# Snowflake Cortex Agents for Microsoft Teams

**Chat with AI-powered agents directly in Microsoft Teams - zero custom code required!**

---

## What is This?

A modern, enterprise-ready integration that brings Snowflake's conversational AI agents into Microsoft Teams. This quickstart demonstrates the official integration using a fun, safe example: an AI joke generator with content safety guardrails.

** Setup Time:** 15 minutes  
** Complexity:** No code required  
** Security:** Enterprise OAuth + RBAC enforced  
** Cost:** Standard Snowflake compute (minimal for demo)

---

## Quick Start

**First time here? Follow these steps in order:**

1. **Prerequisites** (5 min) → docs/01-PREREQUISITES.md
   - Verify Snowflake ACCOUNTADMIN access
   - Verify Microsoft Entra ID Global Admin access
   - Check Cortex AI is available

2. **Entra ID Setup** (3 min) → docs/02-ENTRA-ID-SETUP.md
   - Azure admin grants tenant consent (one-time)
   - Save your Tenant ID

3. **Snowflake Security Integration** (2 min) → Run SQL
   ```bash
   # Execute these in Snowsight:
   sql/01_setup/01_create_demo_objects.sql
   sql/01_setup/02_create_joke_function.sql
   sql/01_setup/04_create_security_integration.sql  # Use your Tenant ID
   sql/01_setup/05_grant_permissions.sql
   ```

4. **Create Agent** (5 min) → docs/04-CREATE-AGENT.md
   - Use Snowsight UI to create Cortex Agent
   - Or follow SQL instructions for automation

5. **Install Teams App** (2 min) → docs/05-INSTALL-TEAMS-APP.md
   - Install from Microsoft AppSource
   - Connect Snowflake account
   - Select Joke Assistant agent

6. **Test** (3 min) → Ask for a joke!
   ```
   Tell me a joke about data engineers
   ```

7. **Production Handoff (variable)** → docs/08-TEAMS-INTEGRATION.md
   - Map an existing semantic view (for example, `VW_CORTEX_ANALYST_SALES_CALL_ACTIVITY`)
   - Register a Cortex Analyst-powered agent for Microsoft Teams
   - Follow the customer validation checklist and record tenant-side testing

**Total setup time: ~20 minutes**

---

## Example Conversation

**You:** Tell me a joke about data engineers

**Bot:**  Why do data engineers prefer dark mode? Because light attracts bugs, and they've already got enough of those in their pipelines! 

Want another one? Try asking about a different topic!

---

**You:** Give me one about SQL

**Bot:**  Why did the SQL query go to therapy? It had too many relationships but still felt empty! 

---

## What You Get

**Zero Development:**
-  No custom bot code to write or maintain
-  No hosting infrastructure needed
-  No ngrok, Bot Framework SDK, or Flask apps
-  Install from AppSource in minutes

**Enterprise Security:**
-  OAuth with Microsoft Entra ID (SSO, MFA)
-  Snowflake RBAC automatically enforced
-  Content safety via Cortex Guard
-  Complete audit trail in QUERY_HISTORY

**AI-Powered:**
-  Snowflake Cortex AI (mistral-large model)
-  Cortex Guard filters unsafe content
-  Natural language understanding
-  Context-aware responses

---

## Project Structure

```
snowflake-cortex-teams/
├── README.md                           # You are here
├── QUICKSTART.md                      # Step-by-step with examples
├── sql/
│   ├── 01_setup/
│   │   ├── 01_create_demo_objects.sql      # Database, schema, warehouse
│   │   ├── 02_create_joke_function.sql     # AI joke generator
│   │   ├── 03_create_cortex_agent.sql      # Agent instructions
│   │   ├── 04_create_security_integration.sql  # OAuth with Entra ID
│   │   └── 05_grant_permissions.sql        # RBAC grants
│   └── 99_cleanup/
│       └── teardown_all.sql               # Complete removal
├── config/
│   ├── entra_id_setup_guide.md           # Azure admin guide
│   └── security_integration_template.sql  # OAuth template
└── docs/
    ├── 01-PREREQUISITES.md                # Requirements checklist
    ├── 02-ENTRA-ID-SETUP.md              # Azure tenant consent
    ├── 03-SNOWFLAKE-SECURITY-INTEGRATION.md  # OAuth setup
    ├── 04-CREATE-AGENT.md                # Agent creation guide
    ├── 05-INSTALL-TEAMS-APP.md           # End user installation
    ├── 06-TESTING.md                     # Test scenarios
    └── 07-CUSTOMIZATION.md               # Production use cases
```

---

## Beyond Jokes: Real Use Cases

This demo proves the architecture. The **same pattern** powers enterprise analytics:

### Sales Analytics
```
User: "What were Q4 revenues?"
Agent: "Q4 2024 revenues: $2.3M (+12% YoY)..."
```

### Customer Support
```
User: "How do I reset a customer password?"
Agent: "Based on our knowledge base: 1. Navigate to..."
```

### Financial Reporting
```
User: "Show budget vs actual for January"
Agent: "January variance analysis: Revenue +5%, Expenses -2%..."
```

### Data Quality
```
User: "Any data quality issues today?"
Agent: " Critical: customer_data table missing 15% of records..."
```

**See docs/07-CUSTOMIZATION.md for production implementation patterns.**

---

## Security & Governance

### How Authentication Works

1. User opens Teams bot
2. Bot redirects to Microsoft Entra ID login
3. User authenticates (SSO, MFA, Conditional Access)
4. Entra ID issues short-lived JWT token
5. Token sent to Snowflake with query
6. Snowflake validates token and executes as user's role

### What's Protected

 **Snowflake Data:** Never leaves Snowflake's environment  
 **RBAC Enforced:** Users see only data their role permits  
 **Row-Level Security:** Automatically applied  
 **Data Masking:** Policies respected  
 **Audit Logs:** All queries in QUERY_HISTORY  

### What's Shared

**Only sent to Snowflake:**
- User prompts/questions
- User identity (email/UPN from Entra ID)
- OAuth tokens (short-lived, validated)

**NOT shared:**
- Teams messages
- Microsoft 365 data
- Other users' conversations

---

## Cost Considerations

### Snowflake Costs

**Compute (Warehouse):**
- XSMALL warehouse with 60-second auto-suspend
- Each joke request: ~0.0001-0.0003 credits
- 1,000 jokes ≈ $0.30 (assuming $3/credit)

**Cortex AI:**
- Cortex COMPLETE function charges by tokens
- Each joke: ~300 tokens in + 100 tokens out
- 1,000 jokes ≈ $0.50

**Total demo cost:** < $1 for 1,000 jokes

### Microsoft Costs

- **Teams:** Included with Microsoft 365 license (no extra cost)
- **AppSource App:** Free to install
- **Entra ID OAuth:** No additional charges

**No separate Teams bot licensing required.**

---

## Why This vs. Custom Bot?

| Aspect | Official Integration | Custom Bot |
|--------|---------------------|------------|
| **Development** | Zero code | Days of coding |
| **Hosting** | Snowflake-managed | Self-hosted (AWS/Azure/GCP) |
| **OAuth** | Built-in | Manual implementation |
| **Maintenance** | Automatic updates | Manual patching |
| **Security** | Enterprise-grade | DIY |
| **Setup Time** | 15 minutes | Hours to days |
| **Cost** | Compute only | Compute + hosting |

**Use official integration unless you need highly custom behavior beyond what Cortex Agents provide.**

---

## Complete Cleanup

When done with the demo:

```bash
# Remove all Snowflake objects
sql/99_cleanup/teardown_all.sql
```

**This removes:**
-  Cortex Agent
-  SQL Function
-  Schema and Database
-  Warehouse
-  Security Integration

**Manual steps:**
- Uninstall Teams app (in Teams → Apps → ... → Uninstall)
- (Optional) Revoke Entra ID consent in Azure Portal

**Time Travel recovery available for 1-90 days** (if needed).

---

## Documentation

### For Administrators

- docs/01-PREREQUISITES.md - Requirements and access verification
- docs/02-ENTRA-ID-SETUP.md - Azure tenant consent (Global Admin)
- docs/03-SNOWFLAKE-SECURITY-INTEGRATION.md - OAuth configuration
- docs/04-CREATE-AGENT.md - Cortex Agent setup

### For End Users

- docs/05-INSTALL-TEAMS-APP.md - Install and connect in Teams
- docs/06-TESTING.md - Test scenarios and fun examples
- QUICKSTART.md - Illustrated walkthrough

### For Developers

- docs/07-CUSTOMIZATION.md - Production use case patterns
- sql/ - All setup and teardown scripts
- config/ - Templates and guides

---

## Troubleshooting

### Common Issues

**"Need admin approval"**
- Entra ID tenant consent not granted
- See docs/02-ENTRA-ID-SETUP.md

**"No agents available"**
- Agent not created or permissions not granted
- Run `sql/01_setup/05_grant_permissions.sql`

**Agent doesn't respond**
- Warehouse suspended (auto-resumes, but first query is slow)
- Check user default role has permissions

**User mapping fails**
- Snowflake LOGIN_NAME must match Entra ID UPN
- See docs/03-SNOWFLAKE-SECURITY-INTEGRATION.md

**For detailed troubleshooting, see documentation for each component.**

---

## Monitoring & Auditing

### Query History

```sql
-- See all joke requests
SELECT USER_NAME,
       QUERY_TEXT,
       START_TIME,
       EXECUTION_TIME,
       CREDITS_USED
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE QUERY_TEXT ILIKE '%GENERATE_SAFE_JOKE%'
ORDER BY START_TIME DESC;
```

### Cost Tracking

```sql
-- Agent warehouse costs
SELECT DATE_TRUNC('day', START_TIME) AS usage_date,
       SUM(CREDITS_USED) AS daily_credits,
       COUNT(*) AS query_count
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE WAREHOUSE_NAME = 'SFE_CORTEX_AGENTS_WH'
GROUP BY usage_date
ORDER BY usage_date DESC;
```

### User Activity

```sql
-- Most active users
SELECT USER_NAME,
       COUNT(*) AS joke_requests,
       SUM(EXECUTION_TIME) / 1000 AS total_seconds
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE QUERY_TEXT ILIKE '%GENERATE_SAFE_JOKE%'
  AND START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY USER_NAME
ORDER BY joke_requests DESC;
```

---

## Contributing

This is a demo project showcasing Snowflake's official Cortex Agents Teams integration. 

**To extend:**
1. Fork this repository
2. Modify for your use case — see docs/07-CUSTOMIZATION.md
3. Share your agent patterns with the community

---

## Reference

**Snowflake Documentation:**
- [Cortex Agents for Teams and Microsoft 365 Copilot](https://docs.snowflake.com/user-guide/snowflake-cortex/cortex-agents-teams-integration)  
  This integration is now generally available across all Snowflake public cloud deployments; refer to this guide for the latest regional considerations and setup requirements.
- [Cortex AI Functions](https://docs.snowflake.com/user-guide/snowflake-cortex/aisql)
- [Cortex Guard](https://docs.snowflake.com/en/user-guide/snowflake-cortex/cortex-guard)

**Microsoft Documentation:**
- [Microsoft Teams App Management](https://learn.microsoft.com/microsoftteams/manage-apps)
- [Microsoft Entra ID](https://learn.microsoft.com/entra/)
- [External OAuth](https://learn.microsoft.com/entra/identity-platform/v2-oauth2-auth-code-flow)

---

## License

This demo project is provided as-is for educational purposes. Snowflake and Microsoft trademarks are property of their respective owners.

**Snowflake Terms:** [snowflake.com/legal](https://www.snowflake.com/legal/)  
**Microsoft Terms:** [microsoft.com/servicesagreement](https://www.microsoft.com/servicesagreement/)

---

## Have Fun!

This demo proves that enterprise AI doesn't have to be serious all the time. Start with jokes, then transform your organization's data access with conversational AI.

**Questions? Issues? Feedback?**
- Check documentation in `docs/`
- Review troubleshooting sections
- Contact your Snowflake account team

**Now go generate some laughs!** 

