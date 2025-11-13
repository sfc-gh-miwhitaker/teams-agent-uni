/*******************************************************************************
 * DEMO PROJECT: Snowflake Cortex Agents for Microsoft Teams
 * Script: Create Entra ID OAuth Security Integration
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Creates an External OAuth security integration that enables the Cortex
 *   Agents Microsoft Teams bot to authenticate users via Microsoft Entra ID
 *   (formerly Azure Active Directory).
 * 
 * PREREQUISITES:
 *   - Microsoft tenant with Global Administrator access
 *   - Tenant-wide consent granted for Snowflake app (see docs/02-ENTRA-ID-SETUP.md)
 *   - Your Microsoft Entra ID tenant ID
 * 
 * OBJECTS CREATED:
 *   - SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION (Security Integration)
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 *
 * EXECUTION TIME:
 *   < 10 seconds
 ******************************************************************************/

-- ============================================================================
-- STEP 1: FIND YOUR MICROSOFT TENANT ID
-- ============================================================================

/*
 * OPTION A: Via Azure Portal
 * ---------------------------
 * 1. Log into https://portal.azure.com
 * 2. Navigate to: Azure Active Directory (or Microsoft Entra ID)
 * 3. Select "Overview" from left menu
 * 4. Your Tenant ID is displayed under "Tenant ID"
 *    (Format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
 * 
 * OPTION B: Via PowerShell
 * -------------------------
 * Run: Connect-AzureAD; (Get-AzureADTenantDetail).ObjectId
 * 
 * OPTION C: Via Microsoft 365 Admin Center
 * -----------------------------------------
 * 1. Log into https://admin.microsoft.com
 * 2. Navigate to: Settings → Domains
 * 3. Click on your domain name
 * 4. Tenant ID is displayed in the properties
 */

-- ============================================================================
-- STEP 2: REPLACE PLACEHOLDER WITH YOUR TENANT ID
-- ============================================================================

-- ⚠️  IMPORTANT: Replace YOUR_TENANT_ID below with your actual tenant ID
-- Example: 12345678-90ab-cdef-1234-567890abcdef

-- ============================================================================
-- STEP 3: CREATE SECURITY INTEGRATION
-- ============================================================================

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
  EXTERNAL_OAUTH_ALLOWED_ROLES_LIST = ()
  EXTERNAL_OAUTH_BLOCKED_ROLES_LIST = ()
  COMMENT = 'DEMO: cortex-agents-teams - OAuth integration for Microsoft Teams bot authentication';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Describe the security integration to verify configuration
DESCRIBE SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION;

-- Verify the integration is enabled
SELECT 
    'Security integration created successfully!' AS status,
    'SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION' AS integration_name;

-- ============================================================================
-- CONFIGURATION DETAILS
-- ============================================================================

/*
 * PARAMETER EXPLANATIONS:
 * -----------------------
 * 
 * TYPE = EXTERNAL_OAUTH
 *   Specifies this is an external OAuth integration
 * 
 * EXTERNAL_OAUTH_TYPE = AZURE
 *   Indicates Microsoft Azure AD / Entra ID as the identity provider
 * 
 * EXTERNAL_OAUTH_ISSUER
 *   The OAuth issuer URL for your Microsoft tenant
 *   Format: https://login.microsoftonline.com/{tenant-id}/v2.0
 * 
 * EXTERNAL_OAUTH_JWS_KEYS_URL
 *   URL where Snowflake retrieves the public keys to validate JWT tokens
 *   Format: https://login.microsoftonline.com/{tenant-id}/discovery/v2.0/keys
 * 
 * EXTERNAL_OAUTH_AUDIENCE_LIST
 *   Application ID of the Snowflake Cortex Agents bot
 *   Fixed value: 5a840489-78db-4a42-8772-47be9d833efe
 * 
 * EXTERNAL_OAUTH_TOKEN_USER_MAPPING_CLAIM
 *   JWT claim used to map Entra ID users to Snowflake users
 *   'upn' = User Principal Name (email address)
 * 
 * EXTERNAL_OAUTH_SNOWFLAKE_USER_MAPPING_ATTRIBUTE
 *   Snowflake user attribute to match against the UPN
 *   'LOGIN_NAME' = matches the user's login name
 * 
 * EXTERNAL_OAUTH_ANY_ROLE_MODE = 'ENABLE'
 *   Allows users to assume any role they're granted in Snowflake
 *   Required for Cortex Agents integration
 * 
 * EXTERNAL_OAUTH_ALLOWED_ROLES_LIST / BLOCKED_ROLES_LIST
 *   Optional role filtering (empty = all roles allowed except blocked)
 */

-- ============================================================================
-- USER MAPPING CONSIDERATIONS
-- ============================================================================

/*
 * ENSURING PROPER USER MAPPING:
 * ------------------------------
 * 
 * For authentication to work, Snowflake users must match Entra ID users:
 * 
 * Option 1: Match by UPN (Recommended)
 *   - Snowflake LOGIN_NAME should equal Entra ID UPN (email)
 *   - Example: user@company.com in both systems
 * 
 * Option 2: Match by Email
 *   - Change EXTERNAL_OAUTH_TOKEN_USER_MAPPING_CLAIM to 'email'
 *   - Change EXTERNAL_OAUTH_SNOWFLAKE_USER_MAPPING_ATTRIBUTE to 'EMAIL_ADDRESS'
 *   - Ensure Snowflake users have EMAIL_ADDRESS property set
 * 
 * VERIFY USER MAPPING:
 */

-- Check current user's login name
SELECT CURRENT_USER() AS snowflake_user,
       USER_NAME,
       LOGIN_NAME,
       EMAIL
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE USER_NAME = CURRENT_USER();

/*
 * If using Option 2 (email mapping), modify the security integration:
 * 
 * ALTER SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION SET
 *   EXTERNAL_OAUTH_TOKEN_USER_MAPPING_CLAIM = 'email'
 *   EXTERNAL_OAUTH_SNOWFLAKE_USER_MAPPING_ATTRIBUTE = 'EMAIL_ADDRESS';
 */

-- ============================================================================
-- TROUBLESHOOTING
-- ============================================================================

/*
 * COMMON ERRORS:
 * 
 * Error 390303: Invalid OAuth access token
 *   → Verify YOUR_TENANT_ID is correct in both URLs above
 *   → Check that tenant-wide consent was granted in Entra ID
 * 
 * Error 390304: Incorrect username or password
 *   → User mapping mismatch between Entra ID and Snowflake
 *   → Verify LOGIN_NAME or EMAIL_ADDRESS matches Entra ID UPN/email
 * 
 * Error 390317: Role not listed in access token
 *   → EXTERNAL_OAUTH_ANY_ROLE_MODE must be 'ENABLE'
 * 
 * Error 390186: Role not granted to user
 *   → Check EXTERNAL_OAUTH_ALLOWED_ROLES_LIST includes user's default role
 *   → Or ensure default role is not in BLOCKED_ROLES_LIST
 * 
 * For detailed troubleshooting, see:
 * docs/03-SNOWFLAKE-SECURITY-INTEGRATION.md
 */

SELECT 'Security integration complete!' AS status,
       'Next: Run 05_grant_permissions.sql' AS next_step;

