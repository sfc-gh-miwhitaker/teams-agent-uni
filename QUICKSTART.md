# Snowflake Cortex Agents for Microsoft Teams - Quick Start Guide

**Get AI-powered jokes in Teams in 15 minutes!**

---

## Introduction

This guide provides a complete, illustrated walkthrough to set up the Snowflake Cortex Agents Microsoft Teams integration using a fun joke generator example.

**What you'll build:**
- AI-powered chatbot in Microsoft Teams
- Generates workplace-appropriate jokes on any topic
- Uses Snowflake Cortex AI with content safety guardrails
- Zero custom code - official integration from AppSource

**Time investment:**
- Azure Admin: 5 minutes (one-time tenant consent)
- Snowflake Admin: 10 minutes (create objects and agent)
- End Users: 2 minutes (install Teams app)

---

## Architecture Overview

```
┌─────────────────┐
│ Microsoft Teams │
│   (User Chat)   │
└────────┬────────┘
         │ OAuth
         ↓
┌─────────────────────────┐
│ Microsoft Entra ID      │
│ (Authentication)        │
└────────┬────────────────┘
         │ JWT Token
         ↓
┌─────────────────────────┐      ┌──────────────────┐
│ Snowflake Cortex Agent  │─────→│ Cortex AI        │
│ (Joke Assistant)        │      │ (mistral-large)  │
└────────┬────────────────┘      └──────────────────┘
         │
         ↓
┌─────────────────────────┐      ┌──────────────────┐
│ SQL Function            │─────→│ Cortex Guard     │
│ GENERATE_SAFE_JOKE()    │      │ (Safety Filter)  │
└─────────────────────────┘      └──────────────────┘
```

**Flow:**
1. User asks for joke in Teams
2. Teams authenticates user via Entra ID (SSO)
3. Request sent to Snowflake Cortex Agent
4. Agent calls SQL function
5. Function uses Cortex AI to generate joke
6. Cortex Guard filters unsafe content
7. Joke returned to Teams

---

## Prerequisites Checklist

Before starting, ensure you have:

### Microsoft Side
- [ ] Organizational Microsoft account (not personal)
- [ ] Microsoft Entra ID Global Administrator access (for step 1 only)
- [ ] Microsoft Teams installed (desktop, web, or mobile)
- [ ] Permission to install apps from AppSource

### Snowflake Side
- [ ] Snowflake account with ACCOUNTADMIN access
- [ ] Cortex AI features enabled (check: can you run SNOWFLAKE.CORTEX.COMPLETE?)
- [ ] Cortex Agents feature available (check: Projects → AI & ML → Cortex Agents exists)
- [ ] No network policies or Private Link enabled

### Time
- [ ] 20 minutes uninterrupted time
- [ ] Azure admin and Snowflake admin can coordinate (or same person)

---

## Step 1: Azure Admin - Grant Tenant Consent

**Who:** Microsoft Entra ID Global Administrator  
**Time:** 5 minutes  
**Frequency:** Once per organization

### 1.1: Find Your Tenant ID

1. Log into [Azure Portal](https://portal.azure.com)
2. Navigate to **Microsoft Entra ID**
3. Click **Overview**
4. Copy **Tenant ID** (looks like: `12345678-90ab-cdef-1234-567890abcdef`)
5. Save it - you'll need it in Step 2

**Screenshot location:** Properties panel on right side of Overview page.

### 1.2: Install Snowflake App from AppSource

1. Go to [Microsoft AppSource](https://appsource.microsoft.com/)
2. Search: **"Snowflake Cortex Agents"**
3. Click on the app card
4. Click **"Get it now"**
5. Sign in as Global Administrator
6. Review permissions requested:
   -  Sign you in and read your profile
   -  Read your email address
   -  View your basic profile
7. Check **"Consent on behalf of your organization"**
8. Click **"Accept"**

### 1.3: Verify Consent

1. Back in Azure Portal
2. Go to **Microsoft Entra ID** → **Enterprise applications**
3. Search for: **"Snowflake"**
4. Click **"Snowflake Cortex Agents"**
5. Go to **"Permissions"**
6. Verify: **"Admin consent granted for [Your Organization]"** shows green checkmark

**Step 1 Complete!** Azure admin's work is done.

---

## Step 2: Snowflake Admin - Create Objects

**Who:** Snowflake ACCOUNTADMIN  
**Time:** 10 minutes  
**Frequency:** Once per Snowflake account

### 2.1: Create Foundation Objects

Open Snowsight and execute these scripts in order:

**Script 1: Create Database, Schema, Warehouse**

```sql
-- File: sql/01_setup/01_create_demo_objects.sql
-- Copy all contents and run in Snowsight
```

In Snowsight:
1. Click **"+"** to open new worksheet
2. Click **"..."** → **"Load Script"**
3. Navigate to `sql/01_setup/01_create_demo_objects.sql`
4. Click **"Run All"** (or Ctrl+Enter)

**Expected output:**
```
Demo objects created successfully!
Current Database: SNOWFLAKE_EXAMPLE
Current Schema: CORTEX_DEMO
Current Warehouse: SFE_CORTEX_AGENTS_WH
```

** Created:**
- Database: `SNOWFLAKE_EXAMPLE`
- Schema: `CORTEX_DEMO`
- Warehouse: `SFE_CORTEX_AGENTS_WH` (XSMALL, auto-suspend 60s)

---

### 2.2: Create AI Joke Function

**Script 2: Create Function with Cortex AI**

```sql
-- File: sql/01_setup/02_create_joke_function.sql
-- Load and run in new worksheet
```

This creates: `GENERATE_SAFE_JOKE(subject VARCHAR)`

**Test the function:**
```sql
SELECT GENERATE_SAFE_JOKE('data engineers');
```

**Expected output:** A clean, 2-3 sentence joke about data engineers.

**Example:**
```
Why do data engineers prefer dark mode? 
Because light attracts bugs, and they've already got 
enough of those in their pipelines! 
```

** Created:**
- Function: `GENERATE_SAFE_JOKE(VARCHAR)`
- Uses: Cortex AI (mistral-large model)
- Safety: Cortex Guard enabled

---

### 2.3: Create Security Integration

**Script 3: OAuth Integration with Entra ID**

**IMPORTANT:** You need your Tenant ID from Step 1.1!

1. Open `sql/01_setup/04_create_security_integration.sql`
2. Find line: `SET tenant_id = 'YOUR_TENANT_ID';`
3. Replace `YOUR_TENANT_ID` with your actual Tenant ID
4. Run the script

**Example:**
```sql
SET tenant_id = '12345678-90ab-cdef-1234-567890abcdef';
```

**Verify:**
```sql
DESCRIBE SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION;
```

Look for:
- `EXTERNAL_OAUTH_TYPE`: AZURE
- `ENABLED`: true
- `EXTERNAL_OAUTH_ISSUER`: Contains your tenant ID

** Created:**
- Security Integration: `SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION`
- Type: External OAuth (Azure)
- Purpose: Authenticates Teams users via Entra ID

---

### 2.4: Create Cortex Agent

**Option A: Via Snowsight UI (Recommended)**

1. In Snowsight, navigate to: **Projects** → **AI & ML** → **Cortex Agents**
2. Click **"+ Agent"** or **"Create"**

**Basic Configuration:**
```
Name: JOKE_ASSISTANT
Database: SNOWFLAKE_EXAMPLE
Schema: CORTEX_DEMO
Display Name: Joke Assistant

Description:
I'm your friendly AI assistant powered by Snowflake Cortex AI! 
Ask me for a joke about any topic, and I'll generate a clean, 
workplace-appropriate joke just for you. Try me with subjects 
like data engineering, SQL, or cloud computing!
```

**Sample Questions (click "+ Add question" for each):**
```
1. Tell me a joke about data engineers
2. Give me a joke about SQL databases
3. Make me laugh about cloud computing
4. Tell me something funny about Snowflake
5. Can you joke about Python programming?
```

**System Instructions:**
```
You are a friendly, enthusiastic AI comedian specializing in tech humor. 
When users ask for jokes, always use the joke_generator tool with their 
subject. Be upbeat and add emojis to make responses fun! Keep responses 
brief and cheerful. Encourage users to try different topics.
```

**Response Instructions:**
```
Prefix each joke with the  emoji. Keep responses brief (just the joke). 
If users ask for multiple jokes, generate them one at a time. Always 
encourage users to try different topics after each joke.
```

**Add Tool:**
- Click **"Add tool"** → **"Custom SQL"**
- Tool Name: `joke_generator`
- Description: `Generates safe, workplace-appropriate jokes using AI`
- SQL Query: `SELECT GENERATE_SAFE_JOKE(?)`
- Warehouse: `SFE_CORTEX_AGENTS_WH`
- Query Timeout: `30` seconds

**Model (Optional but Recommended):**
- Orchestration Model: `claude-3-5-sonnet`

**Create Agent:**
- Review settings
- Click **"Create"**
- Wait for "Agent created successfully"

**Option B: Via SQL/REST API**

See `sql/01_setup/03_create_cortex_agent.sql` for automated approach.

** Created:**
- Cortex Agent: `JOKE_ASSISTANT`
- Tool: `joke_generator` (calls GENERATE_SAFE_JOKE function)
- Status: Ready for Teams integration

---

### 2.5: Grant Permissions

**Script 4: Grant Access**

```sql
-- File: sql/01_setup/05_grant_permissions.sql
-- Run to grant access to users
```

This grants:
- Database and schema USAGE to PUBLIC
- Warehouse USAGE to PUBLIC
- Function execution rights
- Agent access (commented - grant via UI after agent creation)

**For production:** Change grants from PUBLIC to specific roles.

** Permissions granted** - users can now access the agent!

---

## Step 3: End User - Install & Test

**Who:** Any Microsoft Teams user in your organization  
**Time:** 2 minutes  
**Frequency:** Once per user

### 3.1: Install Snowflake App in Teams

**In Microsoft Teams:**

1. Click **"Apps"** in the left sidebar
2. Search: **"Snowflake Cortex Agents"**
3. Click on the app card
4. Click **"Add"**
5. Click **"Open"**

**The app opens in Teams.**

### 3.2: Connect Snowflake Account

**First-time setup:**

1. Click **"Connect Account"**
2. **Select Region:** Choose your Snowflake account region
   - Example: "AWS US East (N. Virginia)"
3. **Enter Account:** Your Snowflake account identifier
   - Option 1: Account locator (e.g., `xy12345`)
   - Option 2: Full name (e.g., `xy12345.us-east-1.aws`)
   - Option 3: URL (e.g., `https://xy12345.snowflakecomputing.com`)

**Find your account identifier in Snowflake:**
```sql
SELECT CURRENT_ACCOUNT(), CURRENT_ACCOUNT_NAME(), CURRENT_REGION();
```

4. Click **"Continue"**
5. **Authenticate:** You are redirected to Microsoft login
   - Sign in with your organizational account
   - Complete any MFA challenges
6. **Grant Consent (if prompted):**
   - If your account is NOT in Azure US East 2, you'll see data processing consent
   - Click **"I Accept"**
7. **Success:** "Account connected successfully"

**Important role note:**  
The integration runs under each user's default (or allowed secondary) role, and security integrations block core administrative roles (such as `ACCOUNTADMIN` and `SECURITYADMIN`) by default. For the first user who connects the Teams app to Snowflake, use a dedicated non-admin role with the required grants (for example, `CORTEX_TEAMS_INTEGRATION_ROLE`) set as the default role or granted via `DEFAULT_SECONDARY_ROLES`, rather than using an administrative role as the default.

### 3.3: Select Agent

1. You'll see a list of available agents
2. Find **"Joke Assistant"** or **"JOKE_ASSISTANT"**
3. Click to select

**You'll see the description:**
```
 Joke Assistant

I'm your friendly AI assistant powered by Snowflake Cortex AI! 
Ask me for a joke about any topic, and I'll generate a clean, 
workplace-appropriate joke just for you.
```

### 3.4: Test Your First Joke!

**Try these prompts:**

**Test 1:**
```
Tell me a joke about data engineers
```

**Expected response:**
```
 Why do data engineers prefer dark mode? 
Because light attracts bugs, and they've already got 
enough of those in their pipelines! 

Want another one? Try asking about a different topic!
```

**Test 2:**
```
Give me a joke about SQL
```

**Test 3:**
```
Make me laugh about Snowflake
```

**Test 4:**
```
Something funny about machine learning
```

**Success!** You are getting AI-generated, safe-for-work jokes in Teams!

---

## Success Criteria

You know it's working when:

- [ ] You can open Snowflake bot in Teams
- [ ] Your Snowflake account shows as connected
- [ ] Joke Assistant appears in agent list
- [ ] Asking for a joke returns a response within 5-15 seconds
- [ ] Jokes are relevant to the topic requested
- [ ] Each request generates a different joke

---

## What's Happening Behind the Scenes

When you type "Tell me a joke about data engineers":

1. **Teams** captures your message
2. **OAuth** authenticates you via Entra ID (transparent SSO)
3. **Agent** receives your prompt in Snowflake
4. **Orchestration** (claude model) extracts "data engineers" as the subject
5. **Tool call** executes: `SELECT GENERATE_SAFE_JOKE('data engineers')`
6. **Warehouse** auto-resumes if suspended
7. **Function** calls Cortex AI: `SNOWFLAKE.CORTEX.COMPLETE(...)`
8. **Cortex AI** (mistral-large) generates joke text
9. **Cortex Guard** checks if content is safe
10. **Response** formatted and returned through agent
11. **Teams** displays the joke

**All in 3-10 seconds!**

**Security enforced:**
- Query runs as YOUR Snowflake user
- RBAC permissions checked
- Audit log created
- No data leaves Snowflake

---

## Try These Topics

**Technology:**
- Python, JavaScript, Java, Rust, Go
- React, Django, Kubernetes, Docker
- AWS, Azure, GCP, serverless

**Data & Analytics:**
- SQL, NoSQL, databases, data warehouses
- ETL pipelines, streaming, batch processing
- Data science, machine learning, AI
- BI tools, dashboards, reports

**Workplace:**
- Remote work, video calls, meetings
- Agile, sprints, stand-ups, retrospectives
- Coffee, keyboards, debugging, documentation
- Deadlines, deployments, incidents

**Snowflake-Specific:**
- Snowflake, data sharing, virtual warehouses
- Semi-structured data, cloning, Time Travel
- Streams, tasks, Snowpipe, Cortex

---

## Troubleshooting

### "Need admin approval"

**Cause:** Tenant consent not granted in Step 1.

**Solution:** Have Azure Global Admin complete Step 1.2-1.3.

---

### "No agents available"

**Cause:** Agent not created or no permissions.

**Solutions:**
1. Verify agent exists in Snowsight: AI & ML → Cortex Agents
2. Grant permissions: Run `sql/01_setup/05_grant_permissions.sql`
3. Check your default role:
```sql
SELECT CURRENT_ROLE();
-- Should have USAGE on agent
```

---

### Bot doesn't respond

**Causes & Solutions:**

1. **First request slow:** Warehouse is cold-starting (10-15s is normal)
2. **Subsequent requests slow:** Check warehouse is XSMALL (should be fast)
3. **No response at all:**
   ```sql
   -- Check warehouse status
   ALTER WAREHOUSE SFE_CORTEX_AGENTS_WH RESUME;
   ```

---

### "Sorry, I could not generate a safe joke..."

**Cause:** Cortex Guard filtered the topic as potentially unsafe.

**Solution:** Try a more neutral topic.

 Good: "data science", "SQL", "cloud computing"
 Filtered: controversial, political, or sensitive topics

---

### User mapping fails

**Symptom:** "Incorrect username or password" or authentication errors.

**Cause:** Your Entra ID email doesn't match a Snowflake user.

**Solution:**
```sql
-- Admin creates matching user
CREATE USER your_name
  LOGIN_NAME = 'your.email@company.com'  -- Must match Entra ID UPN
  EMAIL = 'your.email@company.com'
  DEFAULT_ROLE = 'PUBLIC';

-- Grant necessary access
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO USER your_name;
```

---

## Cost Monitoring

Check how much the demo is costing:

```sql
-- Daily credit usage
SELECT DATE_TRUNC('day', START_TIME) AS date,
       SUM(CREDITS_USED) AS credits,
       COUNT(*) AS queries
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE WAREHOUSE_NAME = 'SFE_CORTEX_AGENTS_WH'
  AND START_TIME >= DATEADD('day', -7, CURRENT_TIMESTAMP())
GROUP BY date
ORDER BY date DESC;
```

**Expected costs:**
- 1,000 jokes ≈ 0.3 credits ≈ $0.90 (compute + Cortex AI)
- Very minimal for demo/testing

---

## Next Steps

### Share with Your Team

- Post a joke in a Teams channel
- Demo during a team meeting
- Create a "joke of the day" tradition

### Explore Capabilities

- Try 20+ different topics
- Test content safety (try questionable topics - they'll be filtered)
- Check different phrasings

### Read Advanced Guides

- `docs/06-TESTING.md` - Comprehensive test scenarios
- `docs/07-CUSTOMIZATION.md` - Transform to production use cases
- `README.md` - Complete reference

### Build Production Agents

Use the same architecture for real business use cases:
- Sales analytics agents
- Customer support knowledge bases
- Financial reporting agents
- Data quality monitors

**The joke bot proves the pattern. Production analytics is just a different SQL function!**

---

## Complete Cleanup

When you're done with the demo:

```bash
# Run in Snowsight:
sql/99_cleanup/teardown_all.sql
```

**This removes:**
-  All Snowflake objects
-  Security integration
-  Warehouse

**Manual removal:**
- Uninstall Teams app: Teams → Apps → Snowflake Cortex Agents → Uninstall

**Time:** < 1 minute

---

## Reference

**Documentation:**
- All guides in `docs/` folder
- SQL scripts in `sql/` folder
- [Snowflake Cortex Agents Docs](https://docs.snowflake.com/user-guide/snowflake-cortex/cortex-agents-teams-integration)

**Support:**
- Check troubleshooting sections
- Review query logs in Snowflake
- Contact Snowflake support if needed

---

##  Congratulations!

You've successfully set up an AI-powered chatbot in Microsoft Teams using Snowflake Cortex Agents!

**What you've learned:**
-  How to integrate Snowflake with Microsoft Teams
-  OAuth with Entra ID for enterprise SSO
-  Cortex AI for natural language generation
-  Cortex Guard for content safety
-  Zero-code agent deployment

**Now go have fun and share some jokes!** 

---

**Questions? See `README.md` for full documentation and references.**

