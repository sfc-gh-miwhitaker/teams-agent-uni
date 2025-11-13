# Microsoft Entra ID Setup Guide

**For:** Azure Global Administrator  
**Time:** 5 minutes  
**One-time:** Yes (per tenant)

---

## Overview

This guide walks through the one-time tenant-wide setup required to enable the Snowflake Cortex Agents integration for Microsoft Teams. This step grants consent for Snowflake's Teams application within your Microsoft Entra ID (formerly Azure Active Directory) tenant.

## Prerequisites

- Microsoft tenant with Global Administrator privileges
- Organizational approval to authorize third-party applications
- Microsoft AppSource access (not blocked by conditional access policies)

---

## Step 1: Find Your Tenant ID

You'll need your Microsoft Entra ID tenant ID for the Snowflake security integration.

### Option A: Azure Portal

1. Navigate to [Azure Portal](https://portal.azure.com)
2. Click **Microsoft Entra ID** (or **Azure Active Directory**)
3. Select **Overview** from the left menu
4. Copy the **Tenant ID** (format: `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx`)
5. Save this value - you'll need it for `sql/01_setup/04_create_security_integration.sql`

### Option B: PowerShell

```powershell
Connect-AzureAD
(Get-AzureADTenantDetail).ObjectId
```

### Option C: Microsoft 365 Admin Center

1. Navigate to [Microsoft 365 Admin Center](https://admin.microsoft.com)
2. Go to **Settings** → **Domains**
3. Click on your primary domain
4. Tenant ID is displayed in the properties panel

**Save your Tenant ID:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

---

## Step 2: Grant Tenant-Wide Consent

This step authorizes the Snowflake Cortex Agents application to authenticate users from your organization via OAuth 2.0.

### What This Does

- Allows users in your organization to sign in to the Snowflake Teams bot using their corporate credentials
- Enables Single Sign-On (SSO) with Multi-Factor Authentication (MFA) support
- Respects all Conditional Access policies configured in your tenant

### What This Does NOT Do

- Does NOT grant Snowflake access to any Microsoft 365 data (email, files, etc.)
- Does NOT allow data to leave Snowflake's secure boundary
- Does NOT bypass any Snowflake RBAC permissions

### Consent Method

The tenant-wide consent is granted automatically when an admin installs the Snowflake Cortex Agents app from Microsoft AppSource.

**Admin Installation Steps:**

1. Navigate to [Microsoft AppSource](https://appsource.microsoft.com/)
2. Search for **"Snowflake Cortex Agents"**
3. Click **"Get it now"**
4. Sign in as a Global Administrator
5. Review the permissions requested:
   - `User.Read` - Read user profile
   - `openid` - Sign in and read profile
   - `profile` - View basic profile
   - `email` - View email address
6. Click **"Accept"** to grant tenant-wide consent
7. Select **"Add to Teams"**

**You will see a consent prompt like this:**

```
Snowflake Cortex Agents wants to:
  ✓ Sign you in and read your profile
  ✓ Read your email address

This app will have access to this information for all users.
Consenting on behalf of your organization.

[ Accept ] [ Cancel ]
```

Click **"Accept"** to proceed.

---

## Step 3: Verify Consent Granted

### Via Azure Portal

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to **Microsoft Entra ID** → **Enterprise applications**
3. Search for **"Snowflake"** or **"Cortex Agents"**
4. You should see the application listed
5. Click on it and select **"Permissions"**
6. Verify **"Admin consent granted for [Your Organization]"** shows a green checkmark

### Via PowerShell

```powershell
Connect-AzureAD
Get-AzureADServicePrincipal -Filter "DisplayName eq 'Snowflake Cortex Agents'"
```

If the command returns results, consent is granted.

---

## Step 4: Configure User Access (Optional)

By default, the app is available to all users in your tenant. To restrict access:

### Option A: Require Assignment

1. In **Enterprise applications**, select the Snowflake app
2. Go to **Properties**
3. Set **"User assignment required"** to **"Yes"**
4. Click **"Save"**
5. Go to **"Users and groups"**
6. Click **"Add user/group"**
7. Select specific users or groups who can use the Teams bot

### Option B: Conditional Access

Create a Conditional Access policy to control when/how users can access the bot:

1. Navigate to **Microsoft Entra ID** → **Security** → **Conditional Access**
2. Create a new policy
3. Target: **Cloud apps** → Select **"Snowflake Cortex Agents"**
4. Configure conditions (e.g., require MFA, compliant device, specific locations)
5. Enable the policy

---

## Troubleshooting

### "Need admin approval" error

**Symptom:** Users see "Need admin approval" when trying to connect in Teams.

**Solution:** 
- Ensure you granted consent as Global Administrator
- Check that consent wasn't revoked
- Verify in Enterprise applications that admin consent shows as granted

### Application not appearing in Enterprise apps

**Symptom:** Cannot find Snowflake app in Enterprise applications list.

**Solution:**
- Ensure you completed the AppSource installation
- Try searching for the application ID: `5a840489-78db-4a42-8772-47be9d833efe`
- Wait 5-10 minutes for Azure AD sync

### Consent page doesn't appear during installation

**Symptom:** No consent prompt shown when installing from AppSource.

**Solution:**
- Clear browser cache and cookies
- Try a different browser or incognito mode
- Ensure you're signed in as Global Administrator
- Check tenant's consent settings aren't blocking consent flows

---

## Data Processing Consent (Non-Azure East US 2 Regions)

If your Snowflake account is **not** in Azure US East 2, you'll see an additional consent during the Teams app setup:

```
Data Processing Notice

Use of this integration requires an intermediate processing (but not storage) 
step in Snowflake's Azure East US 2 region, regardless of the region where 
your Snowflake account is located.

By proceeding, you are authorizing Snowflake to process your data within 
Snowflake's Azure East US 2 region.

[ I Accept ] [ Cancel ]
```

**What this means:**
- User prompts and bot responses transit through Snowflake's bot backend in Azure US East 2
- No data is **stored** in that region, only **processed** in transit
- Your Snowflake data remains in your account's home region
- This is required for the Teams integration to function

To proceed, click **"I Accept"**.

To withdraw consent later, disconnect your account in the Teams app settings.

---

## Security Considerations

### What Gets Authenticated

- **User identity:** Microsoft Entra ID verifies who the user is
- **Access token:** Short-lived JWT tokens issued for each session
- **MFA respected:** All MFA and Conditional Access policies apply

### What Stays Secure

- **Snowflake data:** Never leaves Snowflake's environment
- **RBAC enforced:** Users can only access data their Snowflake role permits
- **Audit logs:** All queries logged in Snowflake's `QUERY_HISTORY`

### Revoking Access

**To revoke an individual user's access:**
1. In Teams app, have user disconnect their Snowflake account
2. Or remove user from the app in Enterprise applications

**To revoke tenant-wide consent:**
1. Go to **Enterprise applications**
2. Select **"Snowflake Cortex Agents"**
3. Click **"Delete"**
4. All users will lose access immediately

---

## Next Steps

✅ **Tenant consent granted**  
✅ **Tenant ID saved**

**Now proceed to:**
1. `sql/01_setup/04_create_security_integration.sql` - Configure Snowflake OAuth integration (use your Tenant ID)
2. `docs/05-INSTALL-TEAMS-APP.md` - Install and connect the Teams app

---

## Reference

- [Microsoft Entra ID Documentation](https://learn.microsoft.com/en-us/entra/)
- [Snowflake Cortex Agents Teams Integration](https://docs.snowflake.com/user-guide/snowflake-cortex/cortex-agents-teams-integration)
- [Azure AD App Consent](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/user-admin-consent-overview)

