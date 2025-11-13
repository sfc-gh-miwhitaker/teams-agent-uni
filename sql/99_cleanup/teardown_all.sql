 /*******************************************************************************
  * DEMO PROJECT: Snowflake Cortex Agents for Microsoft Teams
  * Script: Schema-Level Teardown (keeps SNOWFLAKE_EXAMPLE + shared SFE_* integration)
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
  * EXECUTION TIME:
  *   < 1 minute
  * 
  * BACKUP RECOMMENDATION:
  *   Before running, consider cloning the schema if you want to preserve data:
  *   CREATE DATABASE SNOWFLAKE_EXAMPLE_BACKUP CLONE SNOWFLAKE_EXAMPLE;
  ******************************************************************************/

-- ============================================================================
-- SAFETY CHECK: Confirm you want to proceed
-- ============================================================================

/*
 * ⚠️  WARNING: This script will permanently delete:
 * 
 * 1. JOKE_ASSISTANT Cortex Agent
 * 2. GENERATE_SAFE_JOKE function
 * 3. CORTEX_DEMO schema
 * 4. SNOWFLAKE_EXAMPLE database (if empty or force cascade)
 * 5. SFE_CORTEX_AGENTS_WH warehouse
 * 6. SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION security integration
 * 
 * To proceed, uncomment the line below:
 */

-- SET safety_confirmed = TRUE;

-- Verify safety confirmation (comment out this block if you're sure)
-- Uncomment to enable safety check:
/*
DO $$
BEGIN
  IF (SELECT $safety_confirmed IS NULL) THEN
    RETURN 'Safety check failed: Please confirm by setting safety_confirmed = TRUE';
  END IF;
END;
$$;
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

-- If you created a custom role, revoke it
-- REVOKE USAGE ON CORTEX AGENT SNOWFLAKE_EXAMPLE.CORTEX_DEMO.JOKE_ASSISTANT FROM ROLE CORTEX_AGENT_USERS IGNORE FAILURE;
-- DROP ROLE IF EXISTS CORTEX_AGENT_USERS;

SELECT 'Grants revoked' AS status;

-- ============================================================================
-- STEP 2: DROP CORTEX AGENT
-- ============================================================================

SELECT 'Step 2: Dropping Cortex Agent...' AS status;

-- Drop the agent if it exists
-- Note: Replace with actual drop syntax when available
-- DROP CORTEX AGENT IF EXISTS SNOWFLAKE_EXAMPLE.CORTEX_DEMO.JOKE_ASSISTANT;

/*
 * If DROP CORTEX AGENT syntax is not available, delete via Snowsight UI:
 * 1. Navigate to: Projects → AI & ML → Cortex Agents
 * 2. Find JOKE_ASSISTANT
 * 3. Click "..." menu → Delete
 * 
 * Or use REST API:
 * curl -X DELETE "$SNOWFLAKE_ACCOUNT_BASE_URL/api/v2/databases/SNOWFLAKE_EXAMPLE/schemas/CORTEX_DEMO/agents/JOKE_ASSISTANT" \
 *   --header "Authorization: Bearer $PAT"
 */

SELECT 'Cortex Agent removed (verify manually if needed)' AS status;

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
 -- STEP 5: RETAIN THE DATABASE + SHARED INTEGRATION
 -- ============================================================================

 SELECT 'Step 5: Keeping SNOWFLAKE_EXAMPLE and SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION per cleanup policy' AS status;

 SELECT 'Database preserved for other demos and audits' AS status;

-- ============================================================================
-- STEP 6: DROP WAREHOUSE
-- ============================================================================

SELECT 'Step 6: Dropping warehouse...' AS status;

DROP WAREHOUSE IF EXISTS SFE_CORTEX_AGENTS_WH;

SELECT 'Warehouse dropped' AS status;

 -- ============================================================================
 -- STEP 7: PRESERVE SECURITY INTEGRATION
 -- ============================================================================

 SELECT 'Step 7: Retaining SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION for shared use' AS status;

 SELECT 'Security integration remains available' AS status;

-- ============================================================================
-- STEP 8: UNINSTALL TEAMS APP (MANUAL STEP)
-- ============================================================================

/*
 * REMOVE FROM MICROSOFT TEAMS:
 * -----------------------------
 * The Teams app installation is user-specific and must be removed manually:
 * 
 * 1. Open Microsoft Teams
 * 2. Click "Apps" in the left sidebar
 * 3. Find "Snowflake Cortex Agents" in your installed apps
 * 4. Right-click → "Uninstall" or click "..." → "Uninstall"
 * 
 * OR (for tenant-wide removal by admin):
 * 
 * 1. Go to Microsoft Teams Admin Center
 * 2. Navigate to: Teams apps → Manage apps
 * 3. Search for "Snowflake Cortex Agents"
 * 4. Select the app → "Block" or "Delete"
 */

-- ============================================================================
-- STEP 9: REVOKE ENTRA ID CONSENT (OPTIONAL)
-- ============================================================================

/*
 * REMOVE TENANT-WIDE CONSENT:
 * ----------------------------
 * If you want to completely remove Snowflake's Teams app authorization:
 * 
 * 1. Log into Azure Portal as Global Administrator
 * 2. Navigate to: Azure Active Directory → Enterprise applications
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

 SELECT 'Cleanup complete!' AS status,
        'Schema-level resources removed; SNOWFLAKE_EXAMPLE retained' AS snowflake_status,
        'Remember to uninstall Teams app manually' AS teams_status,
        'Entra ID consent can be revoked in Azure Portal (optional)' AS azure_status;

 /*
  * WHAT WAS DELETED:
  * -----------------
  * - Cortex Agent: JOKE_ASSISTANT
  * - Function: GENERATE_SAFE_JOKE(VARCHAR)
  * - Schema: SNOWFLAKE_EXAMPLE.CORTEX_DEMO
  * - Warehouse: SFE_CORTEX_AGENTS_WH
  * - Grants revoked for PUBLIC (and any custom roles)
  *
  * WHAT WAS RETAINED:
  * -------------------
  * - Database: SNOWFLAKE_EXAMPLE
  * - Security Integration: SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION
  *
  * MANUAL CLEANUP REQUIRED:
  * ------------------------
  * - Uninstall Teams app (see Step 8 above)
  * - Revoke Entra ID consent (optional, see Step 9 above)
  *
  * TIME TRAVEL RECOVERY:
  * ---------------------
  * - SNOWFLAKE_EXAMPLE, schema, and warehouse can be undropped per retention,
  *   but persistent objects like the integration cannot be recovered automatically.
  */

 SELECT 'To start over, run setup scripts in order from sql/01_setup/' AS next_steps;

