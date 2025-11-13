/*******************************************************************************
 * SECURITY INTEGRATION TEMPLATE
 * 
 * This is a template for creating the External OAuth security integration
 * required for the Cortex Agents Microsoft Teams integration.
 * 
 * INSTRUCTIONS:
 * 1. Find your Microsoft Entra ID Tenant ID (see config/entra_id_setup_guide.md)
 * 2. Replace YOUR_TENANT_ID in the script below (3 locations)
 * 3. Save as a new file or copy into sql/01_setup/04_create_security_integration.sql
 * 4. Execute in Snowflake as ACCOUNTADMIN
 ******************************************************************************/

-- ============================================================================
-- STEP 1: INSERT YOUR TENANT ID HERE
-- ============================================================================

-- ⚠️  REPLACE THIS VALUE:
-- Example: SET tenant_id = '12345678-90ab-cdef-1234-567890abcdef';

SET tenant_id = 'YOUR_TENANT_ID';

-- ============================================================================
-- STEP 2: CREATE SECURITY INTEGRATION
-- ============================================================================

USE ROLE ACCOUNTADMIN;

CREATE OR REPLACE SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION
  TYPE = EXTERNAL_OAUTH
  ENABLED = TRUE
  EXTERNAL_OAUTH_TYPE = AZURE
  EXTERNAL_OAUTH_ISSUER = CONCAT('https://login.microsoftonline.com/', $tenant_id, '/v2.0')
  EXTERNAL_OAUTH_JWS_KEYS_URL = CONCAT('https://login.microsoftonline.com/', $tenant_id, '/discovery/v2.0/keys')
  EXTERNAL_OAUTH_AUDIENCE_LIST = ('5a840489-78db-4a42-8772-47be9d833efe')
  EXTERNAL_OAUTH_TOKEN_USER_MAPPING_CLAIM = 'upn'
  EXTERNAL_OAUTH_SNOWFLAKE_USER_MAPPING_ATTRIBUTE = 'LOGIN_NAME'
  EXTERNAL_OAUTH_ANY_ROLE_MODE = 'ENABLE'
  COMMENT = 'DEMO: cortex-agents-teams - OAuth integration for Microsoft Teams bot authentication';

-- ============================================================================
-- STEP 3: VERIFY
-- ============================================================================

DESCRIBE SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION;

-- Check the issuer URL contains your tenant ID
SELECT 
    'Security integration created!' AS status,
    $tenant_id AS your_tenant_id,
    'Verify tenant ID appears in EXTERNAL_OAUTH_ISSUER above' AS verification_step;

-- ============================================================================
-- ALTERNATIVE: DIRECT STRING REPLACEMENT (NO VARIABLES)
-- ============================================================================

/*
 * If variable substitution doesn't work in your SQL client, use this version
 * with direct string replacement:

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

-- Find and replace ALL instances of YOUR_TENANT_ID with your actual tenant ID
*/

