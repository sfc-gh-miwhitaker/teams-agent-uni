/*******************************************************************************
 * DEMO METADATA (Machine-readable - Do not modify format)
 * PROJECT_NAME: teams-agent-uni
 * AUTHOR: SE Community
 * CREATED: 2025-12-02
 * EXPIRES: 2026-01-01
 * GITHUB_REPO: https://github.com/miwhitaker/teams-agent-uni
 * PURPOSE: Snowflake Cortex Agents for Microsoft Teams integration demo
 * 
 * DEPLOYMENT INSTRUCTIONS:
 * 1. Open Snowsight and create a new SQL worksheet
 * 2. Copy this entire script into the worksheet
 * 3. Click "Run All" (Ctrl+Shift+Enter)
 * 4. Review the expiration check result before proceeding
 * 5. Follow post-deployment steps in docs/04-CREATE-AGENT.md
 * 
 * PREREQUISITES:
 * - ACCOUNTADMIN role access
 * - Cortex AI enabled in your account
 * - Microsoft Entra ID tenant ID (for security integration)
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 ******************************************************************************/

-- ============================================================================
-- EXPIRATION CHECK (MANDATORY)
-- ============================================================================
-- This demo expires 30 days after creation.
-- If expired, deployment should be halted and the repository forked with updated dates.
-- Expiration date: 2026-01-01

-- Display expiration status
SELECT 
    '2026-01-01'::DATE AS expiration_date,
    CURRENT_DATE() AS current_date,
    DATEDIFF('day', CURRENT_DATE(), '2026-01-01'::DATE) AS days_remaining,
    CASE 
        WHEN DATEDIFF('day', CURRENT_DATE(), '2026-01-01'::DATE) < 0 
        THEN '🚫 EXPIRED - Do not deploy. Fork repository and update expiration date.'
        WHEN DATEDIFF('day', CURRENT_DATE(), '2026-01-01'::DATE) <= 7
        THEN '⚠️  EXPIRING SOON - ' || DATEDIFF('day', CURRENT_DATE(), '2026-01-01'::DATE) || ' days remaining'
        ELSE '✅ ACTIVE - ' || DATEDIFF('day', CURRENT_DATE(), '2026-01-01'::DATE) || ' days remaining'
    END AS demo_status;

-- ⚠️  MANUAL CHECK REQUIRED:
-- If the demo_status shows "EXPIRED", STOP HERE and do not proceed with deployment.
-- This demo uses Snowflake features current as of December 2025.
-- To use after expiration:
--   1. Fork: https://github.com/miwhitaker/teams-agent-uni
--   2. Update expiration_date in this file (line ~30)
--   3. Review/update for latest Snowflake syntax and features

-- ============================================================================
-- SETUP CONTEXT
-- ============================================================================

USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- 1. CREATE DATABASE (if not exists)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    COMMENT = 'DEMO: Repository for example/demo projects - NOT FOR PRODUCTION (Expires: 2026-01-01)';

-- ============================================================================
-- 2. CREATE SCHEMA FOR CORTEX AGENTS DEMO
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.CORTEX_DEMO
    COMMENT = 'DEMO: teams-agent-uni - Schema for Cortex Agents Teams integration demo (Expires: 2026-01-01)';

-- ============================================================================
-- 3. CREATE DEDICATED WAREHOUSE FOR AGENT QUERIES
-- ============================================================================

CREATE WAREHOUSE IF NOT EXISTS SFE_CORTEX_AGENTS_WH WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'DEMO: teams-agent-uni - Dedicated warehouse for Cortex Agent query execution (Expires: 2026-01-01)';

-- ============================================================================
-- 4. SET CONTEXT FOR SUBSEQUENT OPERATIONS
-- ============================================================================

USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA CORTEX_DEMO;
USE WAREHOUSE SFE_CORTEX_AGENTS_WH;

-- ============================================================================
-- 5. CREATE AI JOKE GENERATION FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION GENERATE_SAFE_JOKE(subject VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
COMMENT = 'DEMO: teams-agent-uni - Generate safe-for-work jokes using Cortex AI with guardrails (Expires: 2026-01-01)'
AS
$$
  SELECT SNOWFLAKE.CORTEX.COMPLETE(
    'mistral-large',
    [
      {
        'role': 'system', 
        'content': 'You are a professional comedian who specializes in clean, workplace-appropriate humor. Your jokes should be:
- Safe for work (no profanity, sexual content, or offensive material)
- Brief (2-3 sentences maximum)
- Clever and witty
- Relevant to the subject provided
- Family-friendly and inclusive'
      },
      {
        'role': 'user', 
        'content': 'Tell me a funny, workplace-appropriate joke about: ' || subject
      }
    ],
    {
      'guardrails': {
        'enabled': true, 
        'response_when_unsafe': 'Sorry, I could not generate a safe joke for that topic. Try something else like data engineering, SQL, or cloud computing!'
      },
      'temperature': 0.7,
      'max_tokens': 150
    }
  ):choices[0]:messages
$$;

-- ============================================================================
-- 6. CREATE SECURITY INTEGRATION FOR ENTRA ID
-- ============================================================================

-- ⚠️  IMPORTANT: Replace YOUR_TENANT_ID with your Microsoft Entra ID tenant ID
-- Find your tenant ID: Azure Portal → Microsoft Entra ID → Overview → Tenant ID
-- Format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx

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
  COMMENT = 'DEMO: teams-agent-uni - OAuth integration for Microsoft Teams bot authentication (Expires: 2026-01-01)';

-- ============================================================================
-- 7. GRANT PERMISSIONS
-- ============================================================================

-- Grant database and schema usage to PUBLIC (demo - use specific roles in production)
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_DEMO TO ROLE PUBLIC;

-- Grant warehouse usage
GRANT USAGE ON WAREHOUSE SFE_CORTEX_AGENTS_WH TO ROLE PUBLIC;

-- Grant function execution
GRANT USAGE ON FUNCTION SNOWFLAKE_EXAMPLE.CORTEX_DEMO.GENERATE_SAFE_JOKE(VARCHAR) TO ROLE PUBLIC;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Show created objects
SHOW DATABASES LIKE 'SNOWFLAKE_EXAMPLE';
SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE;
SHOW WAREHOUSES LIKE 'SFE_CORTEX_AGENTS_WH';
SHOW USER FUNCTIONS LIKE 'GENERATE_SAFE_JOKE';
SHOW SECURITY INTEGRATIONS LIKE 'SFE_ENTRA_ID%';

-- Test the joke function
SELECT 'Function Test' AS test_type, GENERATE_SAFE_JOKE('Snowflake') AS result;

-- Final status
SELECT 
    '✅ Deployment complete!' AS status,
    CURRENT_DATABASE() AS current_database,
    CURRENT_SCHEMA() AS current_schema,
    CURRENT_WAREHOUSE() AS current_warehouse,
    '2026-01-01' AS expires;

/*******************************************************************************
 * POST-DEPLOYMENT STEPS:
 * 
 * 1. SECURITY INTEGRATION:
 *    - Replace YOUR_TENANT_ID in the security integration (lines ~143-144)
 *    - Re-run just that CREATE statement with your actual tenant ID
 *    - Verify: DESCRIBE SECURITY INTEGRATION SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION;
 * 
 * 2. CREATE CORTEX AGENT:
 *    - Follow docs/04-CREATE-AGENT.md to create the agent via Snowsight UI
 *    - Or use the REST API template in sql/01_setup/03_create_cortex_agent.sql
 * 
 * 3. GRANT AGENT ACCESS:
 *    - After agent creation, grant access:
 *      GRANT USAGE ON CORTEX AGENT SNOWFLAKE_EXAMPLE.CORTEX_DEMO.JOKE_ASSISTANT TO ROLE PUBLIC;
 * 
 * 4. INSTALL TEAMS APP:
 *    - Follow docs/05-INSTALL-TEAMS-APP.md
 * 
 * CLEANUP:
 *    Run sql/99_cleanup/teardown_all.sql to remove all demo objects
 ******************************************************************************/

