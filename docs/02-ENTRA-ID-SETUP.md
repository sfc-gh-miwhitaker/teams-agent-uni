# Microsoft Entra ID Setup

**For:** Azure Global Administrator  
**Time:** 5 minutes  
**Frequency:** One-time per tenant

---

## Overview

This step grants tenant-wide consent for the Snowflake Cortex Agents application in your Microsoft Entra ID tenant. This enables users in your organization to authenticate to the Snowflake Teams bot using their corporate credentials with full SSO and MFA support.

**What this does:** Authorizes OAuth 2.0 authentication between Microsoft and Snowflake  
**What this does NOT do:** Grant access to any Microsoft 365 data or bypass Snowflake RBAC

---

## Before You Begin

Ensure you have:
- [ ] Microsoft Entra ID Global Administrator privileges
- [ ] Organizational approval to authorize third-party apps
- [ ] Access to Azure Portal or Microsoft AppSource

---

## Method 1: Grant Consent via AppSource (Recommended)

This is the simplest method and automatically grants tenant-wide consent.

### Step 1: Navigate to AppSource

1. Open browser and go to: https://appsource.microsoft.com/
2. Click **"Sign in"** (top right)
3. Sign in with your Global Administrator account

### Step 2: Find Snowflake Cortex Agents

1. In the search bar, type: **"Snowflake Cortex Agents"**
2. Press Enter
3. Click on the **"Snowflake Cortex Agents"** app card

### Step 3: Get the App

1. Click the **"Get it now"** button
2. Fill in any required contact information
3. Click **"Continue"**

### Step 4: Review Permissions

You'll see a consent screen showing the permissions requested:

```
Snowflake Cortex Agents wants to:
  ✓ Sign you in and read your profile (openid, profile)
  ✓ Read your email address (email)
  ✓ View your basic profile (User.Read)

This app will have access to this information for all users in your organization.
Consenting on behalf of your organization.
```

**What these permissions mean:**
- **openid, profile:** Enable Single Sign-On
- **email:** Map your email to Snowflake user identity
- **User.Read:** Read basic profile info (name, email, UPN)

**What these do NOT grant:**
- ❌ Access to emails, files, or calendar
- ❌ Access to other users' data
- ❌ Ability to modify Microsoft 365 data
- ❌ Bypass of any Snowflake permissions

### Step 5: Grant Consent

1. Review the permissions carefully
2. Check the box: **"Consent on behalf of your organization"**
3. Click **"Accept"**

**You should see:** "App added successfully" or automatic redirect to Teams.

### Step 6: Verify Consent in Azure Portal

1. Navigate to: https://portal.azure.com
2. Go to **Microsoft Entra ID** → **Enterprise applications**
3. Search for: **"Snowflake"**
4. Click on **"Snowflake Cortex Agents"**
5. Go to **"Permissions"** in left menu
6. Verify you see: **"Admin consent granted for [Your Organization]"** with green checkmark

---

## Method 2: Grant Consent via Azure Portal (Advanced)

Use this if AppSource installation fails or you want more control.

### Step 1: Get Application ID

The Snowflake Cortex Agents application ID is:
```
5a840489-78db-4a42-8772-47be9d833efe
```

### Step 2: Construct Consent URL

Create the admin consent URL (replace `YOUR_TENANT_ID`):

```
https://login.microsoftonline.com/YOUR_TENANT_ID/adminconsent?client_id=5a840489-78db-4a42-8772-47be9d833efe
```

**Find your Tenant ID:**
- Azure Portal → Microsoft Entra ID → Overview → Tenant ID

### Step 3: Navigate to Consent URL

1. Open the URL you constructed in a browser
2. Sign in as Global Administrator
3. Review the permissions (same as Method 1)
4. Click **"Accept"**

### Step 4: Verify

Check Enterprise applications (same as Method 1, Step 6).

---

## Method 3: PowerShell (Automation)

For automated deployments or script-based consent:

```powershell
# Connect to Azure AD
Connect-AzureAD

# Get the service principal (creates if doesn't exist)
$sp = Get-AzureADServicePrincipal -Filter "AppId eq '5a840489-78db-4a42-8772-47be9d833efe'"

if ($null -eq $sp) {
    # Create service principal if it doesn't exist
    $sp = New-AzureADServicePrincipal -AppId "5a840489-78db-4a42-8772-47be9d833efe"
}

# Grant admin consent for the app
# Note: Manual consent via portal/AppSource is still recommended
Write-Host "Service Principal created. Complete consent via Azure Portal."
Write-Host "Navigate to: Enterprise applications -> Snowflake Cortex Agents -> Permissions"
```

---

## Verification Steps

### 1. Check Enterprise Applications

```
Azure Portal → Microsoft Entra ID → Enterprise applications
→ Search "Snowflake" → Snowflake Cortex Agents
→ Permissions → Verify "Admin consent granted"
```

### 2. Check Application Properties

```
In Snowflake app properties:
  ✓ User assignment required: No (or Yes if you want to restrict)
  ✓ Visible to users: Yes
  ✓ Enabled for users to sign-in: Yes
```

### 3. Test User Access (Optional)

Have a test user attempt to:
1. Install Snowflake Cortex Agents in Teams
2. Click "Connect Account"
3. Authenticate with their credentials
4. Should succeed without "Need admin approval" error

---

## Regional Data Processing Consent

### For Accounts Outside Azure US East 2

If your Snowflake account is in a region **other than Azure US East 2**, users will see an additional consent during their first Teams app connection:

```
Data Processing Notice

Use of this integration requires an intermediate processing 
(but not storage) step in Snowflake's Azure East US 2 region.

By proceeding, you authorize Snowflake to process your data 
within Azure East US 2 for bot communication.

[ I Accept ] [ Cancel ]
```

**Key points:**
- User prompts and bot responses are **processed** (not stored) in Azure US East 2
- Your Snowflake data **remains** in your account's home region
- No data is **stored** outside your region
- Required for the integration to function

**To proceed:** Users must individually accept this consent.

**To withdraw:** Users can disconnect their account in Teams app settings.

---

## Optional: Restrict User Access

By default, all users in your tenant can use the app. To restrict access:

### Option A: Require User Assignment

```
Enterprise applications → Snowflake Cortex Agents → Properties
→ Set "User assignment required" to "Yes"
→ Save
→ Go to "Users and groups"
→ Add specific users/groups who can access
```

### Option B: Conditional Access Policies

Create policies to control when/how users access the bot:

```
Microsoft Entra ID → Security → Conditional Access
→ Create new policy
→ Target: Cloud apps → Select "Snowflake Cortex Agents"
→ Conditions: Configure (location, device, MFA, etc.)
→ Grant: Require MFA, compliant device, etc.
→ Enable policy
```

**Example policy:** Require MFA for Snowflake bot access from non-corporate networks.

---

## Save Your Tenant ID

You'll need this for the Snowflake security integration setup.

**Find Tenant ID:**
```
Azure Portal → Microsoft Entra ID → Overview
→ Copy "Tenant ID" (format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
```

**Save it here:** \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

Or save to a file:
```powershell
# PowerShell
(Get-AzureADTenantDetail).ObjectId | Out-File tenant_id.txt
```

---

## Troubleshooting

### Error: "Need admin approval"

**Symptom:** Users see this when trying to connect in Teams.

**Cause:** Consent wasn't properly granted or was revoked.

**Solution:**
1. Re-do consent steps above
2. Verify consent in Enterprise applications
3. Check application isn't blocked by Conditional Access

### Error: "Application not found in directory"

**Symptom:** Can't find app in Enterprise applications.

**Cause:** App wasn't installed or consent wasn't completed.

**Solution:**
1. Complete AppSource installation first
2. Wait 5-10 minutes for Azure AD sync
3. Search by Application ID: `5a840489-78db-4a42-8772-47be9d833efe`

### Error: "You don't have permission to consent"

**Symptom:** Consent page shows error.

**Cause:** Not logged in as Global Administrator.

**Solution:**
1. Sign out of Azure Portal
2. Sign in with Global Administrator account
3. Retry consent process

### Consent page doesn't appear

**Symptom:** No consent prompt during installation.

**Cause:** Browser cache or consent flow issue.

**Solution:**
1. Clear browser cache and cookies
2. Use InPrivate/Incognito mode
3. Try different browser
4. Use Method 2 (direct consent URL)

---

## Security Considerations

### What Gets Authorized

✅ **OAuth 2.0 authentication flow**  
✅ **User identity verification**  
✅ **Short-lived access tokens (JWT)**  
✅ **MFA and Conditional Access respected**

### What Stays Secure

✅ **Snowflake data never leaves Snowflake**  
✅ **RBAC enforced on all queries**  
✅ **No access to Microsoft 365 data**  
✅ **Audit logs in Snowflake QUERY_HISTORY**

### Revoking Consent

**To revoke for one user:**
```
User disconnects account in Teams app settings
```

**To revoke tenant-wide:**
```
Azure Portal → Enterprise applications 
→ Snowflake Cortex Agents 
→ Delete
```

All users will immediately lose access.

---

## Next Steps

✅ **Tenant consent granted**  
✅ **Tenant ID saved**

**Now proceed to:**

1. `docs/03-SNOWFLAKE-SECURITY-INTEGRATION.md` - Configure Snowflake OAuth
2. Run `sql/01_setup/04_create_security_integration.sql` with your Tenant ID
3. Continue with agent setup

---

## Reference

- [Microsoft Entra ID Admin Consent](https://learn.microsoft.com/en-us/entra/identity/enterprise-apps/grant-admin-consent)
- [Snowflake External OAuth](https://docs.snowflake.com/en/user-guide/oauth-azure)
- [Teams Apps Management](https://learn.microsoft.com/en-us/microsoftteams/manage-apps)

