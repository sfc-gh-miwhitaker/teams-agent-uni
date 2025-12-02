/*******************************************************************************
 * DEMO PROJECT: Snowflake Cortex Agents for Microsoft Teams
 * Script: Schema-Level Teardown (keeps SNOWFLAKE_EXAMPLE + shared SFE_* integration)
 * Author: SE Community
 * Expires: 2026-01-01
 * 
 * ⚠️  DESTRUCTIVE OPERATION - THIS WILL DELETE AGENT-RELATED RESOURCES
 * 
 * PURPOSE:
 *   Drops the agent, function, schema, warehouse, and grants created by the demo,
 *   while preserving the shared SNOWFLAKE_EXAMPLE database and the
 *   SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION API integration for reuse.
 * 
 * WHEN TO USE:
 *   - Demo/testing complete
 *   - Resetting the schema/warehouse for a fresh install
 *   - Prepping the account for another demo while keeping shared assets
 * 
 * EXECUTION:
 *   Copy this entire script into Snowsight and click "Run All"
 * 
 * EXECUTION TIME:
 *   < 1 minute
 * 
 * BACKUP RECOMMENDATION:
 *   Before running, consider cloning the schema if you want to preserve data:
 *   CREATE DATABASE SNOWFLAKE_EXAMPLE_BACKUP CLONE SNOWFLAKE_EXAMPLE;
 ******************************************************************************/

-- ============================================================================
-- WHAT THIS SCRIPT WILL DELETE
-- ============================================================================

/*
 * ⚠️  WARNING: This script will permanently delete:
 * 
 * 1. JOKE_ASSISTANT Cortex Agent (manual deletion required)
 * 2. SALES_CALLS_ANALYST Cortex Agent (if created, manual deletion required)
 * 3. GENERATE_SAFE_JOKE function
 * 4. CORTEX_DEMO schema (CASCADE)
 * 5. SFE_CORTEX_AGENTS_WH warehouse
 * 6. Custom roles: CORTEX_AGENT_USERS, SALES_CALLS_AGENT_ROLE
 * 
 * PRESERVED (not deleted):
 * - SNOWFLAKE_EXAMPLE database
 * - SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION security integration
 */

-- ============================================================================
-- STEP 1: REVOKE ALL GRANTS
-- ============================================================================

USE ROLE ACCOUNTADMIN;

SELECT 'Step 1: Revoking grants...' AS status;

-- Revoke grants from PUBLIC role
REVOKE USAGE ON DATABASE SNOWFLAKE_EXAMPLE FROM ROLE PUBLIC IGNORE FAILURE;
REVOKE USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_DEMO FROM ROLE PUBLIC IGNORE FAILURE;
REVOKE USAGE ON WAREHOUSE SFE_CORTEX_AGENTS_WH FROM ROLE PUBLIC IGNORE FAILURE;
REVOKE USAGE ON FUNCTION SNOWFLAKE_EXAMPLE.CORTEX_DEMO.GENERATE_SAFE_JOKE(VARCHAR) FROM ROLE PUBLIC IGNORE FAILURE;

-- If you created custom roles, revoke their grants
REVOKE USAGE ON DATABASE SNOWFLAKE_EXAMPLE FROM ROLE CORTEX_AGENT_USERS IGNORE FAILURE;
REVOKE USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_DEMO FROM ROLE CORTEX_AGENT_USERS IGNORE FAILURE;
REVOKE USAGE ON WAREHOUSE SFE_CORTEX_AGENTS_WH FROM ROLE CORTEX_AGENT_USERS IGNORE FAILURE;
REVOKE USAGE ON FUNCTION SNOWFLAKE_EXAMPLE.CORTEX_DEMO.GENERATE_SAFE_JOKE(VARCHAR) FROM ROLE CORTEX_AGENT_USERS IGNORE FAILURE;
REVOKE USAGE ON CORTEX AGENT SNOWFLAKE_EXAMPLE.CORTEX_DEMO.JOKE_ASSISTANT FROM ROLE CORTEX_AGENT_USERS IGNORE FAILURE;

REVOKE USAGE ON DATABASE SNOWFLAKE_EXAMPLE FROM ROLE SALES_CALLS_AGENT_ROLE IGNORE FAILURE;
REVOKE USAGE ON WAREHOUSE SFE_CORTEX_AGENTS_WH FROM ROLE SALES_CALLS_AGENT_ROLE IGNORE FAILURE;
REVOKE USAGE ON CORTEX AGENT SNOWFLAKE_EXAMPLE.CORTEX_DEMO.SALES_CALLS_ANALYST FROM ROLE SALES_CALLS_AGENT_ROLE IGNORE FAILURE;

DROP ROLE IF EXISTS SALES_CALLS_AGENT_ROLE;
DROP ROLE IF EXISTS CORTEX_AGENT_USERS;

SELECT 'Grants revoked' AS status;

-- ============================================================================
-- STEP 2: DROP CORTEX AGENT (MANUAL)
-- ============================================================================

SELECT 'Step 2: Cortex Agents require manual deletion...' AS status;

/*
 * DELETE AGENTS VIA SNOWSIGHT UI:
 * 1. Navigate to: Projects → AI & ML → Cortex Agents
 * 2. Find JOKE_ASSISTANT (and SALES_CALLS_ANALYST if created)
 * 3. Click "..." menu → Delete
 * 
 * OR USE REST API:
 * curl -X DELETE "$SNOWFLAKE_ACCOUNT_BASE_URL/api/v2/databases/SNOWFLAKE_EXAMPLE/schemas/CORTEX_DEMO/agents/JOKE_ASSISTANT" \
 *   --header "Authorization: Bearer $PAT"
 */

SELECT 'Delete Cortex Agents manually via Snowsight UI before proceeding' AS action_required;

-- ============================================================================
-- STEP 3: DROP FUNCTION
-- ============================================================================

SELECT 'Step 3: Dropping function...' AS status;

DROP FUNCTION IF EXISTS SNOWFLAKE_EXAMPLE.CORTEX_DEMO.GENERATE_SAFE_JOKE(VARCHAR);

SELECT 'Function dropped' AS status;

-- ============================================================================
-- STEP 4: DROP SCHEMA
-- ============================================================================

SELECT 'Step 4: Dropping schema...' AS status;

DROP SCHEMA IF EXISTS SNOWFLAKE_EXAMPLE.CORTEX_DEMO CASCADE;

SELECT 'Schema dropped' AS status;

-- ============================================================================
-- STEP 5: RETAIN DATABASE (per cleanup policy)
-- ============================================================================

SELECT 'Step 5: Keeping SNOWFLAKE_EXAMPLE database per cleanup policy' AS status;

-- ============================================================================
-- STEP 6: DROP WAREHOUSE
-- ============================================================================

SELECT 'Step 6: Dropping warehouse...' AS status;

DROP WAREHOUSE IF EXISTS SFE_CORTEX_AGENTS_WH;

SELECT 'Warehouse dropped' AS status;

-- ============================================================================
-- STEP 7: RETAIN SECURITY INTEGRATION (per cleanup policy)
-- ============================================================================

SELECT 'Step 7: Retaining SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION for shared use' AS status;

-- ============================================================================
-- STEP 8: UNINSTALL TEAMS APP (MANUAL)
-- ============================================================================

/*
 * REMOVE FROM MICROSOFT TEAMS:
 * 
 * Per-User Removal:
 * 1. Open Microsoft Teams
 * 2. Click "Apps" in the left sidebar
 * 3. Find "Snowflake Cortex Agents" in your installed apps
 * 4. Right-click → "Uninstall" or click "..." → "Uninstall"
 * 
 * Tenant-Wide Removal (Admin):
 * 1. Go to Microsoft Teams Admin Center
 * 2. Navigate to: Teams apps → Manage apps
 * 3. Search for "Snowflake Cortex Agents"
 * 4. Select the app → "Block" or "Delete"
 */

-- ============================================================================
-- STEP 9: REVOKE ENTRA ID CONSENT (OPTIONAL)
-- ============================================================================

/*
 * REMOVE TENANT-WIDE CONSENT (if desired):
 * 
 * 1. Log into Azure Portal as Global Administrator
 * 2. Navigate to: Microsoft Entra ID → Enterprise applications
 * 3. Search for "Snowflake Cortex Agents"
 * 4. Select the application
 * 5. Click "Delete" in the Overview pane
 * 6. Confirm deletion
 * 
 * This removes the tenant-wide consent and all user sign-ins.
 */

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'Step 8: Verifying cleanup...' AS status;

-- Check that objects are gone (except for preserved shared assets)
SHOW DATABASES LIKE 'SNOWFLAKE_EXAMPLE';  -- Should still return the demo namespace
SHOW WAREHOUSES LIKE 'SFE_CORTEX_AGENTS_WH';  -- Should return no results
SHOW SECURITY INTEGRATIONS LIKE 'SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION';  -- Should still exist

-- ============================================================================
-- CLEANUP COMPLETE
-- ============================================================================

SELECT 
    '✅ Cleanup complete!' AS status,
    'Schema-level resources removed; SNOWFLAKE_EXAMPLE retained' AS snowflake_status,
    'Remember to uninstall Teams app manually' AS teams_status,
    'Entra ID consent can be revoked in Azure Portal (optional)' AS azure_status;

/*
 * SUMMARY
 * -------
 * 
 * DELETED:
 * - Function: GENERATE_SAFE_JOKE(VARCHAR)
 * - Schema: SNOWFLAKE_EXAMPLE.CORTEX_DEMO
 * - Warehouse: SFE_CORTEX_AGENTS_WH
 * - Roles: CORTEX_AGENT_USERS, SALES_CALLS_AGENT_ROLE
 * - Grants revoked for PUBLIC and custom roles
 *
 * RETAINED:
 * - Database: SNOWFLAKE_EXAMPLE
 * - Security Integration: SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION
 *
 * MANUAL CLEANUP REQUIRED:
 * - Delete Cortex Agents via Snowsight UI (Step 2)
 * - Uninstall Teams app (Step 8)
 * - Revoke Entra ID consent (optional, Step 9)
 *
 * TIME TRAVEL RECOVERY:
 * - Schema and warehouse can be undropped per your retention settings
 * - Use: UNDROP SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_DEMO;
 */

SELECT 'To start over, run deploy_all.sql or scripts in sql/01_setup/' AS next_steps;
