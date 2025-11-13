/*******************************************************************************
 * DEMO PROJECT: Snowflake Cortex Agents for Microsoft Teams
 * Script: Create Core Demo Objects
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Creates the foundational Snowflake objects needed for the Cortex Agents
 *   Teams integration demo: database, schema, and warehouse.
 * 
 * OBJECTS CREATED:
 *   - SNOWFLAKE_EXAMPLE (Database) - Demo namespace
 *   - SNOWFLAKE_EXAMPLE.CORTEX_DEMO (Schema) - Agent objects
 *   - SFE_CORTEX_AGENTS_WH (Warehouse) - Compute for agent queries
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 *
 * EXECUTION TIME:
 *   < 30 seconds
 ******************************************************************************/

-- Switch to ACCOUNTADMIN for object creation
USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- 1. CREATE DATABASE (if not exists)
-- ============================================================================

CREATE DATABASE IF NOT EXISTS SNOWFLAKE_EXAMPLE
    COMMENT = 'DEMO: Repository for example/demo projects - NOT FOR PRODUCTION';

-- Verify database creation
SHOW DATABASES LIKE 'SNOWFLAKE_EXAMPLE';

-- ============================================================================
-- 2. CREATE SCHEMA FOR CORTEX AGENTS DEMO
-- ============================================================================

CREATE SCHEMA IF NOT EXISTS SNOWFLAKE_EXAMPLE.CORTEX_DEMO
    COMMENT = 'DEMO: cortex-agents-teams - Schema for Cortex Agents Teams integration demo';

-- Verify schema creation
SHOW SCHEMAS IN DATABASE SNOWFLAKE_EXAMPLE;

-- ============================================================================
-- 3. CREATE DEDICATED WAREHOUSE FOR AGENT QUERIES
-- ============================================================================

CREATE WAREHOUSE IF NOT EXISTS SFE_CORTEX_AGENTS_WH WITH
    WAREHOUSE_SIZE = 'XSMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE
    COMMENT = 'DEMO: cortex-agents-teams - Dedicated warehouse for Cortex Agent query execution';

-- Verify warehouse creation
SHOW WAREHOUSES LIKE 'SFE_CORTEX_AGENTS_WH';

-- ============================================================================
-- 4. SET CONTEXT FOR SUBSEQUENT SCRIPTS
-- ============================================================================

USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA CORTEX_DEMO;
USE WAREHOUSE SFE_CORTEX_AGENTS_WH;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

SELECT 'Demo objects created successfully!' AS status,
       CURRENT_DATABASE() AS current_database,
       CURRENT_SCHEMA() AS current_schema,
       CURRENT_WAREHOUSE() AS current_warehouse;

/*
 * NEXT STEPS:
 * -----------
 * 1. Run 02_create_joke_function.sql to create the AI-powered joke generator
 * 2. Run 03_create_cortex_agent.sql to create the Cortex Agent object
 * 3. Run 04_create_security_integration.sql for Entra ID OAuth integration
 * 4. Run 05_grant_permissions.sql to grant access to users/roles
 */

