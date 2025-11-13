/*******************************************************************************
 * DEMO PROJECT: Snowflake Cortex Agents for Microsoft Teams
 * Script: Grant Permissions for Cortex Agent Access
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Grants the necessary permissions for users/roles to access the Cortex
 *   Agent and underlying resources (database, schema, warehouse, function).
 * 
 * SECURITY CONSIDERATIONS:
 *   This demo grants access to PUBLIC role for simplicity. In production,
 *   grant to specific roles based on your RBAC model.
 * 
 * DEPENDENCIES:
 *   - All previous setup scripts (01-04) must be run first
 *   - Cortex Agent JOKE_ASSISTANT must exist
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 *
 * EXECUTION TIME:
 *   < 10 seconds
 ******************************************************************************/

USE ROLE ACCOUNTADMIN;

-- ============================================================================
-- OPTION 1: GRANT TO PUBLIC (DEMO - BROADEST ACCESS)
-- ============================================================================

/*
 * This grants access to all users in your Snowflake account.
 * Suitable for demos and testing environments.
 */

-- Grant database and schema usage
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE PUBLIC;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_DEMO TO ROLE PUBLIC;

-- Grant warehouse usage
GRANT USAGE ON WAREHOUSE SFE_CORTEX_AGENTS_WH TO ROLE PUBLIC;

-- Grant function execution
GRANT USAGE ON FUNCTION SNOWFLAKE_EXAMPLE.CORTEX_DEMO.GENERATE_SAFE_JOKE(VARCHAR) TO ROLE PUBLIC;

-- Grant Cortex Agent access
-- Note: Replace with actual grant syntax when agent is created
-- GRANT USAGE ON CORTEX AGENT SNOWFLAKE_EXAMPLE.CORTEX_DEMO.JOKE_ASSISTANT TO ROLE PUBLIC;

SELECT 'Permissions granted to PUBLIC role' AS status;

-- ============================================================================
-- OPTION 2: GRANT TO SPECIFIC ROLE (PRODUCTION PATTERN)
-- ============================================================================

/*
 * For production, create a dedicated role and grant access to specific users.
 * Uncomment and customize the following:
 */

/*
-- Create a dedicated role for Cortex Agent users
CREATE ROLE IF NOT EXISTS CORTEX_AGENT_USERS
    COMMENT = 'Users authorized to interact with Cortex Agents in Teams';

-- Grant database and schema usage
GRANT USAGE ON DATABASE SNOWFLAKE_EXAMPLE TO ROLE CORTEX_AGENT_USERS;
GRANT USAGE ON SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_DEMO TO ROLE CORTEX_AGENT_USERS;

-- Grant warehouse usage
GRANT USAGE ON WAREHOUSE SFE_CORTEX_AGENTS_WH TO ROLE CORTEX_AGENT_USERS;

-- Grant function execution
GRANT USAGE ON FUNCTION SNOWFLAKE_EXAMPLE.CORTEX_DEMO.GENERATE_SAFE_JOKE(VARCHAR) 
    TO ROLE CORTEX_AGENT_USERS;

-- Grant Cortex Agent access
GRANT USAGE ON CORTEX AGENT SNOWFLAKE_EXAMPLE.CORTEX_DEMO.JOKE_ASSISTANT 
    TO ROLE CORTEX_AGENT_USERS;

-- Grant the role to specific users
GRANT ROLE CORTEX_AGENT_USERS TO USER alice_analyst;
GRANT ROLE CORTEX_AGENT_USERS TO USER bob_engineer;

-- Make it a secondary role for convenience
ALTER USER alice_analyst SET DEFAULT_SECONDARY_ROLES = ('ALL');
ALTER USER bob_engineer SET DEFAULT_SECONDARY_ROLES = ('ALL');

SELECT 'Permissions granted to CORTEX_AGENT_USERS role' AS status;
*/

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Show grants on database
SHOW GRANTS ON DATABASE SNOWFLAKE_EXAMPLE;

-- Show grants on schema
SHOW GRANTS ON SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_DEMO;

-- Show grants on warehouse
SHOW GRANTS ON WAREHOUSE SFE_CORTEX_AGENTS_WH;

-- Show grants on function
SHOW GRANTS ON FUNCTION SNOWFLAKE_EXAMPLE.CORTEX_DEMO.GENERATE_SAFE_JOKE(VARCHAR);

-- Show grants on Cortex Agent (uncomment after agent is created)
-- SHOW GRANTS ON CORTEX AGENT SNOWFLAKE_EXAMPLE.CORTEX_DEMO.JOKE_ASSISTANT;

-- ============================================================================
-- IMPORTANT: DEFAULT ROLE CONFIGURATION
-- ============================================================================

/*
 * CRITICAL FOR TEAMS INTEGRATION:
 * --------------------------------
 * The Cortex Agents Teams integration executes queries using each user's
 * DEFAULT ROLE. Ensure users' default roles have the necessary permissions.
 * 
 * VERIFY USER'S DEFAULT ROLE:
 */

SELECT USER_NAME,
       DEFAULT_ROLE,
       DEFAULT_SECONDARY_ROLES
FROM SNOWFLAKE.ACCOUNT_USAGE.USERS
WHERE USER_NAME = CURRENT_USER();

/*
 * SET DEFAULT ROLE (if needed):
 * 
 * -- Option A: Change user's primary default role
 * ALTER USER alice_analyst SET DEFAULT_ROLE = 'CORTEX_AGENT_USERS';
 * 
 * -- Option B: Use secondary roles (recommended)
 * GRANT ROLE CORTEX_AGENT_USERS TO USER alice_analyst;
 * ALTER USER alice_analyst SET DEFAULT_SECONDARY_ROLES = ('ALL');
 * 
 * With secondary roles set to 'ALL', the user can use the combined
 * privileges of their default role plus all granted secondary roles.
 */

-- ============================================================================
-- MONITORING ACCESS
-- ============================================================================

/*
 * Query to see which roles can access the agent:
 */

-- Show all role grants
SHOW GRANTS TO ROLE PUBLIC;

-- Check specific user's effective roles
-- SHOW GRANTS TO USER alice_analyst;

-- ============================================================================
-- ADDITIONAL SECURITY CONSIDERATIONS
-- ============================================================================

/*
 * ROW-LEVEL SECURITY:
 * -------------------
 * If the agent queries tables with row-level security policies, ensure
 * users' roles are granted appropriate access.
 * 
 * DYNAMIC DATA MASKING:
 * ---------------------
 * Masking policies are enforced automatically. Users will see masked data
 * according to their role's privileges.
 * 
 * NETWORK POLICIES:
 * -----------------
 * ⚠️  The Cortex Agents Teams integration does NOT support network policies.
 * If your account has network policies enabled, you must disable them:
 * 
 * -- List network policies
 * SHOW NETWORK POLICIES;
 * 
 * -- Disable network policy on account (if needed)
 * ALTER ACCOUNT UNSET NETWORK_POLICY;
 * 
 * PRIVATE LINK:
 * -------------
 * ⚠️  Private Link is NOT supported. Disable if configured.
 */

SELECT 'Permission grants complete!' AS status,
       'Users can now access the agent from Microsoft Teams' AS next_step,
       'See docs/05-INSTALL-TEAMS-APP.md for installation steps' AS documentation;

/*
 * NEXT STEPS:
 * -----------
 * 1. Verify users' default roles have necessary grants
 * 2. Install Cortex Agents app from Microsoft AppSource
 * 3. Connect Snowflake account in Teams
 * 4. Select JOKE_ASSISTANT agent
 * 5. Start chatting!
 * 
 * TESTING:
 * --------
 * Before deploying to users, test with a single user account:
 * 1. Have test user install Teams app
 * 2. Authenticate with Entra ID
 * 3. Verify agent appears in available agents list
 * 4. Test joke generation: "Tell me a joke about data engineers"
 * 5. Verify proper RBAC enforcement
 */

