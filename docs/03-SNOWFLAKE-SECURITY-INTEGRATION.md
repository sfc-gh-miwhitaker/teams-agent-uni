# Snowflake Security Integration Setup

**For:** Snowflake ACCOUNTADMIN  
**Time:** 5 minutes  
**Frequency:** Once per Snowflake account

---

## Overview

This step creates an External OAuth security integration in Snowflake that enables the Cortex Agents Microsoft Teams bot to authenticate users via Microsoft Entra ID. This integration links your Snowflake account to your Microsoft tenant for secure, seamless Single Sign-On.

---

## Prerequisites

Before you begin:
- [ ] Snowflake ACCOUNTADMIN or SECURITYADMIN access (to create the integration itself)
- [ ] A dedicated, non-administrative Snowflake role that will be used as the default (or secondary) role for the Teams setup user; do not use `ACCOUNTADMIN` or `SECURITYADMIN` as the default role because security integrations block those roles by default
- [ ] Entra ID tenant-wide consent granted (see `docs/02-ENTRA-ID-SETUP.md`)
- [ ] Your Microsoft Entra ID Tenant ID

---

## Step 1: Locate Your Tenant ID

If you haven't already, find your Microsoft Entra ID Tenant ID:

**Option A: Azure Portal**
```
1. Navigate to: https://portal.azure.com
2. Click: Microsoft Entra ID
3. Click: Overview
4. Copy: Tenant ID (UUID format)
```

**Option B: PowerShell**
```powershell
Connect-AzureAD
(Get-AzureADTenantDetail).ObjectId
```

**Save your Tenant ID:**  
Format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`

---

## Step 2: Create Security Integration

### Option A: Using the Template

1. Open `config/security_integration_template.sql`
2. Replace `YOUR_TENANT_ID` with your actual Tenant ID (3 locations)
3. Execute in Snowflake Snowsight:

```sql
USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION
  TYPE = EXTERNAL_OAUTH
  ENABLED = TRUE
  EXTERNAL_OAUTH_TYPE = AZURE
  EXTERNAL_OAUTH_ISSUER = 'https://login.microsoftonline.com/YOUR_TENANT_ID/v2.0'
  EXTERNAL_OAUTH_JWS_KEYS_URL = 'https://login.microsoftonline.com/YOUR_TENANT_ID/discovery/v2.0/keys'
  EXTERNAL_OAUTH_AUDIENCE_LIST = ('5a840489-78db-4a42-8772-47be9d833efe')
  EXTERNAL_OAUTH_TOKEN_USER_MAPPING_CLAIM = 'upn'
  EXTERNAL_OAUTH_SNOWFLAKE_USER_MAPPING_ATTRIBUTE = 'LOGIN_NAME'
  EXTERNAL_OAUTH_ANY_ROLE_MODE = 'ENABLE'
  COMMENT = 'DEMO: cortex-agents-teams - OAuth integration for Microsoft Teams bot authentication';
```

### Option B: Run the Setup Script

```bash
# Edit the script first to add your Tenant ID
# Then execute:
```

In Snowsight:
1. Open new SQL worksheet
2. Load file: `sql/01_setup/04_create_security_integration.sql`
3. Find and replace `YOUR_TENANT_ID` (3 locations)
4. Click "Run All"

---

## Step 3: Verify Integration

Run verification queries:

```sql
-- Describe the integration
DESCRIBE SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION;

-- Verify key properties
SELECT 
    'EXTERNAL_OAUTH_TYPE' AS property, 
    'AZURE' AS expected_value;
    
-- Verify issuer contains your tenant ID
SHOW SECURITY INTEGRATIONS LIKE 'SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION';
```

**Expected output:**
- TYPE: EXTERNAL_OAUTH
- EXTERNAL_OAUTH_TYPE: AZURE
- ENABLED: true
- EXTERNAL_OAUTH_ISSUER: Contains your tenant ID
- EXTERNAL_OAUTH_ANY_ROLE_MODE: ENABLE

---

## Configuration Parameter Explanations

### Core OAuth Settings

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `TYPE` | `EXTERNAL_OAUTH` | Specifies external OAuth provider |
| `EXTERNAL_OAUTH_TYPE` | `AZURE` | Identifies Microsoft Entra ID as IdP |
| `ENABLED` | `TRUE` | Activates the integration |

### Token Validation

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `EXTERNAL_OAUTH_ISSUER` | `https://login.microsoftonline.com/{tenant-id}/v2.0` | URL of token issuer |
| `EXTERNAL_OAUTH_JWS_KEYS_URL` | `https://login.microsoftonline.com/{tenant-id}/discovery/v2.0/keys` | Public keys for JWT validation |
| `EXTERNAL_OAUTH_AUDIENCE_LIST` | `5a840489-78db-4a42-8772-47be9d833efe` | Snowflake bot application ID |

### User Mapping

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `EXTERNAL_OAUTH_TOKEN_USER_MAPPING_CLAIM` | `upn` | JWT claim to use (User Principal Name) |
| `EXTERNAL_OAUTH_SNOWFLAKE_USER_MAPPING_ATTRIBUTE` | `LOGIN_NAME` | Snowflake attribute to match |

This configuration maps:
- Entra ID User Principal Name (email) → Snowflake LOGIN_NAME

### Role Management

| Parameter | Value | Purpose |
|-----------|-------|---------|
| `EXTERNAL_OAUTH_ANY_ROLE_MODE` | `ENABLE` | Allows user to assume any granted role |

This is **required** for Cortex Agents integration.

---

## User Mapping Strategies

### Strategy 1: Match by UPN (Recommended)

**Configuration:**
```sql
EXTERNAL_OAUTH_TOKEN_USER_MAPPING_CLAIM = 'upn'
EXTERNAL_OAUTH_SNOWFLAKE_USER_MAPPING_ATTRIBUTE = 'LOGIN_NAME'
```

**Requirements:**
- Each Entra ID user maps to exactly one Snowflake user (strict one-to-one mapping)
- Snowflake LOGIN_NAME must equal Entra ID UPN
- Example: `alice@company.com` in both systems

**Verify mapping:**
```sql
SELECT USER_NAME, LOGIN_NAME
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE LOGIN_NAME LIKE '%@%';  -- Should show email-style logins
```

**Create matching user:**
```sql
CREATE USER alice_analyst
  LOGIN_NAME = 'alice@company.com'
  DEFAULT_ROLE = 'PUBLIC';
```

### Strategy 2: Match by Email

**Configuration:**
```sql
ALTER SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION SET
  EXTERNAL_OAUTH_TOKEN_USER_MAPPING_CLAIM = 'email'
  EXTERNAL_OAUTH_SNOWFLAKE_USER_MAPPING_ATTRIBUTE = 'EMAIL_ADDRESS';
```

**Requirements:**
- Snowflake EMAIL_ADDRESS property must be set
- Example: `alice@company.com` in Snowflake user's EMAIL property

**Verify mapping:**
```sql
SELECT USER_NAME, EMAIL
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE EMAIL IS NOT NULL;
```

**Set email for user:**
```sql
ALTER USER alice_analyst SET EMAIL = 'alice@company.com';
```

---

## Testing User Mapping

### Test Specific User

```sql
-- Check if user exists and has correct mapping
SELECT USER_NAME,
       LOGIN_NAME,
       EMAIL,
       DEFAULT_ROLE,
       DISABLED
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE LOGIN_NAME = 'alice@company.com';  -- Replace with test user UPN

-- If user doesn't exist, create:
CREATE USER test_user_teams
  LOGIN_NAME = 'test.user@yourcompany.com'
  EMAIL = 'test.user@yourcompany.com'
  DEFAULT_ROLE = 'PUBLIC'
  MUST_CHANGE_PASSWORD = FALSE
  COMMENT = 'Test user for Teams bot integration';
  
-- Grant necessary permissions
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO USER test_user_teams;
```

### Verify Default Role

**Important:** The Teams integration uses each user's DEFAULT ROLE, and security integrations block the main administrative roles by default. Do not use `ACCOUNTADMIN` or `SECURITYADMIN` as the default role for the user that sets up the Teams bot. Instead, create a dedicated, non-admin role with the required grants and either make it the default role or grant it as a secondary role.

```sql
-- Check default roles
SELECT USER_NAME,
       DEFAULT_ROLE
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE USER_NAME = 'TEST_USER_TEAMS';

-- Set default role for the Teams integration (non-admin role)
ALTER USER test_user_teams SET DEFAULT_ROLE = 'CORTEX_TEAMS_INTEGRATION_ROLE';

-- OR use secondary roles for additional privileges without changing the primary default
GRANT ROLE CORTEX_TEAMS_INTEGRATION_ROLE TO USER test_user_teams;
ALTER USER test_user_teams SET DEFAULT_SECONDARY_ROLES = ('ALL');
```

---

## Troubleshooting

### Error 390303: Invalid OAuth access token

**Symptom:** Authentication fails with invalid token error.

**Causes:**
1. Tenant ID is incorrect in integration URLs
2. Tenant-wide consent not granted in Entra ID
3. Token issuer URL malformed

**Solutions:**
```sql
-- 1. Verify tenant ID in integration
DESCRIBE SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION;

-- Check EXTERNAL_OAUTH_ISSUER contains correct tenant ID

-- 2. Update with correct tenant ID
ALTER SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION SET
  EXTERNAL_OAUTH_ISSUER = 'https://login.microsoftonline.com/CORRECT_TENANT_ID/v2.0'
  EXTERNAL_OAUTH_JWS_KEYS_URL = 'https://login.microsoftonline.com/CORRECT_TENANT_ID/discovery/v2.0/keys';

-- 3. Verify tenant consent in Azure Portal
-- Enterprise applications → Snowflake Cortex Agents → Permissions
```

### Error 390304: Incorrect username or password

**Symptom:** User mapping fails.

**Causes:**
1. Snowflake user doesn't exist
2. LOGIN_NAME or EMAIL doesn't match Entra ID UPN/email
3. Multiple Snowflake users with same email

**Solutions:**
```sql
-- 1. Check if user exists
SELECT USER_NAME, LOGIN_NAME, EMAIL
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE LOGIN_NAME ILIKE '%failing.user%'
   OR EMAIL ILIKE '%failing.user%';

-- 2. Create user with matching LOGIN_NAME
CREATE USER failing_user
  LOGIN_NAME = 'failing.user@company.com'  -- Must match Entra ID UPN
  EMAIL = 'failing.user@company.com'
  DEFAULT_ROLE = 'PUBLIC';

-- 3. Check for duplicate emails
SELECT EMAIL, COUNT(*) AS user_count
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE EMAIL IS NOT NULL
GROUP BY EMAIL
HAVING COUNT(*) > 1;

-- Each user must have unique email if using email mapping
```

### Error 390317: Role not listed in access token

**Symptom:** Role assignment fails.

**Cause:** `EXTERNAL_OAUTH_ANY_ROLE_MODE` is not enabled.

**Solution:**
```sql
ALTER SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION SET
  EXTERNAL_OAUTH_ANY_ROLE_MODE = 'ENABLE';

-- Verify
DESCRIBE SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION;
```

### Error 390186: Role not granted to user

**Symptom:** User's role is blocked or not allowed.

**Cause:** Role filtering is too restrictive.

**Solution:**
```sql
-- Check role filters
DESCRIBE SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION;

-- Look at:
-- EXTERNAL_OAUTH_ALLOWED_ROLES_LIST
-- EXTERNAL_OAUTH_BLOCKED_ROLES_LIST

-- To allow all roles:
ALTER SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION SET
  EXTERNAL_OAUTH_ALLOWED_ROLES_LIST = ()
  EXTERNAL_OAUTH_BLOCKED_ROLES_LIST = ();
```

---

## Advanced Configuration

### Restrict to Specific Roles

To limit which roles can be used via Teams integration:

```sql
-- Allow only specific roles
ALTER SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION SET
  EXTERNAL_OAUTH_ALLOWED_ROLES_LIST = ('PUBLIC', 'ANALYST', 'DATA_SCIENTIST');

-- Block specific roles (allow all others)
ALTER SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION SET
  EXTERNAL_OAUTH_BLOCKED_ROLES_LIST = ('ACCOUNTADMIN', 'SECURITYADMIN');
```

### Multiple Microsoft Tenants

For organizations with multiple Microsoft tenants:

```sql
-- Create separate integrations for each tenant
CREATE SECURITY INTEGRATION entra_id_tenant_A_integration
  TYPE = EXTERNAL_OAUTH
  EXTERNAL_OAUTH_ISSUER = 'https://login.microsoftonline.com/TENANT_A_ID/v2.0'
  ...;

CREATE SECURITY INTEGRATION entra_id_tenant_B_integration
  TYPE = EXTERNAL_OAUTH
  EXTERNAL_OAUTH_ISSUER = 'https://login.microsoftonline.com/TENANT_B_ID/v2.0'
  ...;
```

### Token Refresh Settings

```sql
-- Adjust token refresh behavior (optional)
ALTER SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION SET
  EXTERNAL_OAUTH_TOKEN_USER_MAPPING_CLAIM = 'upn'
  EXTERNAL_OAUTH_ALLOWED_ROLES_LIST = ()
  EXTERNAL_OAUTH_SNOWFLAKE_USER_MAPPING_ATTRIBUTE = 'LOGIN_NAME';
```

---

## Security Best Practices

### 1. Principle of Least Privilege

```sql
-- Don't grant ACCOUNTADMIN via Teams
ALTER SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION SET
  EXTERNAL_OAUTH_BLOCKED_ROLES_LIST = ('ACCOUNTADMIN', 'SECURITYADMIN');
```

### 2. Audit OAuth Usage

```sql
-- Monitor OAuth authentications
SELECT USER_NAME,
       CLIENT_APPLICATION_ID,
       AUTHENTICATION_METHOD,
       IS_SUCCESS,
       EVENT_TIMESTAMP
FROM SNOWFLAKE.ACCOUNT_USAGE.LOGIN_HISTORY
WHERE AUTHENTICATION_METHOD = 'OAUTH'
ORDER BY EVENT_TIMESTAMP DESC
LIMIT 100;
```

### 3. Regular Access Reviews

```sql
-- List users with Teams access
SELECT u.USER_NAME,
       u.LOGIN_NAME,
       u.EMAIL,
       u.DEFAULT_ROLE,
       u.DISABLED,
       u.LAST_SUCCESS_LOGIN
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS u
WHERE u.LOGIN_NAME LIKE '%@%'
  AND u.DISABLED = FALSE
ORDER BY u.LAST_SUCCESS_LOGIN DESC NULLS LAST;
```

---

## Next Steps

✅ **Security integration created**  
✅ **User mapping configured**  
✅ **Integration tested**

**Now proceed to:**

1. `docs/04-CREATE-AGENT.md` - Create the Cortex Agent
2. Run `sql/01_setup/01_create_demo_objects.sql`
3. Run `sql/01_setup/02_create_joke_function.sql`
4. Run `sql/01_setup/03_create_cortex_agent.sql` (or use Snowsight UI)

---

## Reference

- [Snowflake External OAuth Documentation](https://docs.snowflake.com/en/user-guide/oauth-azure)
- [Cortex Agents Teams Integration](https://docs.snowflake.com/user-guide/snowflake-cortex/cortex-agents-teams-integration)
- [Microsoft Entra ID Tokens](https://learn.microsoft.com/en-us/entra/identity-platform/access-tokens)

