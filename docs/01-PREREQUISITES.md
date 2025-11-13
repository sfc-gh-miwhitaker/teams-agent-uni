# Prerequisites

**Estimated Time:** 5 minutes (verification only)  
**Role Required:** Varies by system

---

## Overview

Before setting up the Snowflake Cortex Agents integration for Microsoft Teams, ensure you have the necessary access and permissions across both platforms.

---

## Snowflake Requirements

### 1. Snowflake Account Access

**Required:**
- Active Snowflake account
- Access via Snowsight web interface

**Verify Access:**
```
1. Navigate to your Snowflake account URL
   Format: https://<account>.snowflakecomputing.com
2. Log in successfully
3. Confirm you can access Snowsight (the modern UI)
```

### 2. Administrative Privileges

**Required Role:** `ACCOUNTADMIN` or `SECURITYADMIN`

**Why:**
- Create security integrations (OAuth with Entra ID)
- Create database objects (database, schema, warehouse)
- Grant permissions to users/roles

**Verify Privileges:**
```sql
-- Check your current role
SELECT CURRENT_ROLE();

-- Check if you can use ACCOUNTADMIN
USE ROLE ACCOUNTADMIN;

-- If successful, you have sufficient privileges
```

### 3. Cortex AI Access

**Required:**
- Snowflake Cortex functions enabled in your account
- Access to `SNOWFLAKE.CORTEX.COMPLETE` function

**Verify Access:**
```sql
-- Test Cortex AI access
SELECT SNOWFLAKE.CORTEX.COMPLETE(
  'mistral-large',
  'Say hello!'
);

-- If this returns a response, Cortex AI is available
```

**If Cortex AI is not available:**
- Contact your Snowflake account manager
- Check your account region (Cortex AI available in most regions)
- Ensure your account type supports Cortex features

### 4. Cortex Agents Feature

**Required:**
- Cortex Agents feature enabled (generally available as of 2024)
- Access to create Cortex Agent objects

**Verify Access:**
```
1. In Snowsight, navigate to: Projects → AI & ML
2. Look for "Cortex Agents" option
3. If visible, feature is enabled
```

---

## Microsoft Requirements

### 1. Microsoft Entra ID (Azure AD) Access

**Required:**
- Active Microsoft Entra ID tenant
- **Global Administrator** privileges (for one-time setup)

**Why:**
- Grant tenant-wide consent for Snowflake application
- Create security integrations

**Verify Access:**
```
1. Log into Azure Portal: https://portal.azure.com
2. Navigate to: Microsoft Entra ID
3. Check your role under "Overview" → "Users"
4. Confirm you have "Global Administrator" role
```

**Alternative:** If you're not a Global Administrator, coordinate with your Azure admin for the one-time consent step.

### 2. Microsoft Teams Access

**Required:**
- Microsoft Teams installed (desktop, web, or mobile)
- Organizational Teams account (not personal)
- Permission to install apps from Microsoft AppSource

**Verify Access:**
```
1. Open Microsoft Teams
2. Click "Apps" in the left sidebar
3. Verify you can browse AppSource
4. Check if app installations are blocked by policy
```

**If app installs are blocked:**
- Contact your Microsoft Teams administrator
- Request access to install apps from AppSource
- Or have admin install app tenant-wide

### 3. AppSource Permissions

**Required:**
- Permission to install apps from Microsoft AppSource
- Not blocked by Conditional Access policies

**Verify:**
```
1. Navigate to: https://appsource.microsoft.com
2. Sign in with your organizational account
3. Search for any app
4. Click "Get it now"
5. If you can proceed, you have access
```

---

## Network & Security Requirements

### 1. Network Policies

**Important:** The Cortex Agents Teams integration does **NOT** support Snowflake accounts with network policies enabled.

**Check if network policies are enabled:**
```sql
-- Check for network policies
SHOW NETWORK POLICIES;

-- Check if account has network policy set
DESCRIBE ACCOUNT;
```

**If network policies are active:**
```sql
-- Disable network policy (ACCOUNTADMIN required)
USE ROLE ACCOUNTADMIN;
ALTER ACCOUNT UNSET NETWORK_POLICY;
```

### 2. Private Link

**Important:** Private Link is **NOT** supported by the Teams integration.

**Check if Private Link is enabled:**
```
1. In Snowsight, go to: Admin → Accounts
2. Check account details for Private Link configuration
3. If Private Link is enabled, contact Snowflake support
```

**Workaround:** Use a separate Snowflake account without Private Link for the demo.

### 3. Firewall & Proxy

**Required:**
- Outbound HTTPS (port 443) access to:
  - `*.snowflakecomputing.com`
  - `*.microsoftonline.com`
  - `*.microsoft.com`
  - `appsource.microsoft.com`

**For corporate networks:** Ensure proxies allow traffic to these domains.

---

## Regional Considerations

### Snowflake Account Region

**Supported:** All public cloud regions (AWS, Azure, GCP)

**Not supported:**
- Sovereign cloud regions
- Government cloud instances

**Check your region:**
```sql
SELECT CURRENT_REGION();
```

### Data Processing Consent

**If your account is NOT in Azure US East 2:**
- You'll be prompted to consent to data processing in Azure US East 2
- This is for intermediate processing only (no storage)
- Required for the Teams integration to function

**What this means:**
- Bot messages transit through Snowflake's backend in Azure US East 2
- Your Snowflake data remains in your account's home region
- No data is stored outside your region

---

## User Requirements

### Entra ID to Snowflake User Mapping

For users to authenticate, their Entra ID identity must map to a Snowflake user.

**Option 1: Match by User Principal Name (UPN)**
- Snowflake `LOGIN_NAME` = Entra ID UPN (email)
- Example: `alice@company.com` in both systems

**Option 2: Match by Email**
- Snowflake `EMAIL_ADDRESS` = Entra ID email
- Requires security integration configuration change

**Verify your user mapping:**
```sql
-- Check current user details
SELECT USER_NAME,
       LOGIN_NAME,
       EMAIL
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE USER_NAME = CURRENT_USER();
```

**Create matching users if needed:**
```sql
-- Create user matching Entra ID UPN
CREATE USER alice_analyst
  LOGIN_NAME = 'alice@company.com'
  EMAIL = 'alice@company.com'
  MUST_CHANGE_PASSWORD = FALSE
  DEFAULT_ROLE = 'PUBLIC';
```

---

## Optional: Personal Access Token (PAT)

**For REST API usage:**
- If you want to create agents programmatically
- Required for automated deployment scripts

**Create PAT:**
```
1. In Snowsight, click your name (top right)
2. Select "Account" → "Personal Access Tokens"
3. Click "Generate New Token"
4. Name: "Cortex Agents API Access"
5. Expiration: Choose appropriate duration
6. Click "Generate Token"
7. Copy and save securely (shown only once)
```

---

## Checklist

Before proceeding to setup, verify you have:

**Snowflake:**
- [ ] ACCOUNTADMIN or SECURITYADMIN access
- [ ] Cortex AI functions available
- [ ] Cortex Agents feature enabled
- [ ] Network policies disabled (or none configured)
- [ ] Private Link not enabled (or separate account available)

**Microsoft:**
- [ ] Global Administrator access (or coordination with admin)
- [ ] Microsoft Teams access
- [ ] AppSource permissions
- [ ] Entra ID tenant ID available

**Users:**
- [ ] User mapping strategy defined (UPN or Email)
- [ ] Test users created in Snowflake if needed
- [ ] Users' default roles configured

---

## Troubleshooting

### "I don't have ACCOUNTADMIN access"

**Solution:**
- Request temporary ACCOUNTADMIN from your Snowflake admin
- Or have admin create objects on your behalf using provided scripts

### "Cortex AI is not available"

**Solution:**
- Check account region (not all regions have Cortex yet)
- Contact Snowflake support to enable Cortex features
- Verify account type/edition includes Cortex

### "I'm not a Global Administrator"

**Solution:**
- Send `config/entra_id_setup_guide.md` to your Azure admin
- Schedule 5-minute session for them to grant tenant consent
- They only need to do this once for your entire organization

### "Teams apps are blocked in my organization"

**Solution:**
- Work with Microsoft Teams administrator
- Request exception for "Snowflake Cortex Agents" from AppSource
- Or have admin install app tenant-wide for all users

---

## Next Steps

✅ **Prerequisites verified**

**Now proceed to:**
1. `docs/02-ENTRA-ID-SETUP.md` - Azure admin grants tenant consent (5 min)
2. `sql/01_setup/` - Run Snowflake setup scripts (5 min)
3. `docs/05-INSTALL-TEAMS-APP.md` - Install and test in Teams (5 min)

---

## Questions?

**Common questions:**
- **Can I use personal Microsoft account?** No, requires organizational account
- **Works with Microsoft 365 Copilot?** Yes, same integration supports both
- **Cost?** Standard Snowflake compute costs; no additional Teams licensing
- **Data security?** All data stays in Snowflake; RBAC fully enforced

**See also:**
- [Snowflake Cortex Agents Documentation](https://docs.snowflake.com/user-guide/snowflake-cortex/cortex-agents-teams-integration)
- [Microsoft Teams App Management](https://learn.microsoft.com/en-us/microsoftteams/manage-apps)

