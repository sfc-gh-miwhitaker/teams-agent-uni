/*******************************************************************************
 * DEMO PROJECT: Snowflake Cortex Agents for Microsoft Teams
 * Script: Create Cortex Agent Configuration
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Provides instructions for creating a Cortex Agent object that will be
 *   used by the Microsoft Teams integration. The agent uses the joke
 *   generation function as a tool.
 * 
 * NOTE:
 *   As of the current Snowflake release, Cortex Agents are created via the
 *   Snowsight UI or REST API. This file provides both approaches.
 * 
 * OBJECTS CREATED:
 *   - JOKE_ASSISTANT (Cortex Agent) - Agent accessible from Teams
 * 
 * DEPENDENCIES:
 *   - Requires 01_create_demo_objects.sql
 *   - Requires 02_create_joke_function.sql
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 ******************************************************************************/

-- ============================================================================
-- OPTION A: CREATE AGENT USING SNOWSIGHT UI (RECOMMENDED)
-- ============================================================================

/*
 * STEPS TO CREATE AGENT IN SNOWSIGHT:
 * 
 * 1. Log into Snowsight as ACCOUNTADMIN
 * 
 * 2. Navigate to: Projects → AI & ML → Cortex Agents
 * 
 * 3. Click "Create Agent"
 * 
 * 4. Configure Agent Details:
 *    - Name: JOKE_ASSISTANT
 *    - Database: SNOWFLAKE_EXAMPLE
 *    - Schema: CORTEX_DEMO
 *    - Description: "I'm your friendly AI assistant that generates safe-for-work jokes on any topic! Just ask me for a joke about anything."
 * 
 * 5. Add Sample Questions:
 *    - "Tell me a joke about data engineers"
 *    - "Give me a joke about SQL"
 *    - "Make me laugh about cloud computing"
 *    - "Tell me something funny about Snowflake"
 * 
 * 6. Configure Agent Instructions:
 *    System Instructions:
 *    "You are a friendly, cheerful AI assistant that tells jokes. When users
 *     ask for a joke, always use the joke_generator tool with the subject
 *     they provide. Be enthusiastic and add emojis to make responses fun!"
 *    
 *    Response Instructions:
 *    "Keep responses brief and upbeat. When delivering a joke, prefix it 
 *     with a 🎭 emoji. If users ask for multiple jokes, generate them one
 *     at a time. Always encourage users to try different topics."
 * 
 * 7. Add Tool - Custom SQL Execution:
 *    - Tool Name: joke_generator
 *    - Tool Type: SQL Execution
 *    - Description: "Generates safe, workplace-appropriate jokes about any subject using AI"
 *    - SQL Query: SELECT GENERATE_SAFE_JOKE(?)
 *    - Warehouse: SFE_CORTEX_AGENTS_WH
 *    - Query Timeout: 30 seconds
 * 
 * 8. Set Model (Optional):
 *    - Orchestration Model: claude-3-5-sonnet (recommended for best quality)
 * 
 * 9. Click "Create"
 * 
 * 10. Grant Access (see 05_grant_permissions.sql for details)
 */

-- ============================================================================
-- OPTION B: CREATE AGENT USING REST API (ADVANCED)
-- ============================================================================

/*
 * For programmatic creation, use the Snowflake REST API with curl:
 * 
 * PREREQUISITES:
 * 1. Generate a Personal Access Token (PAT) in Snowsight
 * 2. Export environment variables:
 *    export SNOWFLAKE_ACCOUNT_BASE_URL="https://<account>.snowflakecomputing.com"
 *    export PAT="your_personal_access_token"
 * 
 * REST API CALL:
 */

-- Example REST API payload (for reference - execute via curl, not SQL):

/*
curl -X POST "$SNOWFLAKE_ACCOUNT_BASE_URL/api/v2/databases/SNOWFLAKE_EXAMPLE/schemas/CORTEX_DEMO/agents" \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--header "Authorization: Bearer $PAT" \
--data '{
  "name": "JOKE_ASSISTANT",
  "comment": "DEMO: cortex-agents-teams - AI joke bot powered by Cortex",
  "profile": {
    "display_name": "Joke Assistant",
    "avatar": "🎭"
  },
  "models": {
    "orchestration": "claude-3-5-sonnet"
  },
  "instructions": {
    "system": "You are a friendly, cheerful AI assistant that tells jokes. When users ask for a joke, always use the joke_generator tool with the subject they provide. Be enthusiastic and add emojis to make responses fun!",
    "response": "Keep responses brief and upbeat. When delivering a joke, prefix it with a 🎭 emoji. If users ask for multiple jokes, generate them one at a time. Always encourage users to try different topics.",
    "orchestration": "Detect when users request jokes and route to the joke_generator tool. Extract the subject from their message.",
    "sample_questions": [
      "Tell me a joke about data engineers",
      "Give me a joke about SQL",
      "Make me laugh about cloud computing",
      "Tell me something funny about Snowflake"
    ]
  },
  "tools": [
    {
      "tool_spec": {
        "type": "sql_execution",
        "name": "joke_generator",
        "description": "Generates safe, workplace-appropriate jokes about any subject using AI"
      }
    }
  ],
  "tool_resources": {
    "joke_generator": {
      "sql_query": "SELECT GENERATE_SAFE_JOKE(?)",
      "execution_environment": {
        "type": "warehouse",
        "warehouse": "SFE_CORTEX_AGENTS_WH"
      },
      "query_timeout": 30
    }
  }
}'
*/

-- ============================================================================
-- OPTION C: PRODUCTION ANALYTICS AGENT TEMPLATE (SEMANTIC VIEW)
-- ============================================================================

/*
 * Use this pattern when your customer already maintains a Cortex Analyst
 * semantic view (for example, VW_CORTEX_ANALYST_SALES_CALL_ACTIVITY) and the
 * Teams agent must answer governed analytics questions against it.
 *
 * 1. Verify the semantic view is accessible:
 *
 *    USE ROLE <DATA_OWNER_ROLE>;
 *    USE WAREHOUSE <ANALYST_WH>;
 *    DESCRIBE VIEW <DB>.<SCHEMA>.VW_CORTEX_ANALYST_SALES_CALL_ACTIVITY;
 *
 *    SELECT COUNT(*) AS sample_rowcount
 *    FROM <DB>.<SCHEMA>.VW_CORTEX_ANALYST_SALES_CALL_ACTIVITY
 *    WHERE PLAN_YEAR = 2024
 *    LIMIT 1;
 *
 *    (Adjust the predicate to a sargable filter that matches your data quality
 *    checks; avoid forcing full scans.)
 *
 * 2. Ensure the Teams-facing role has:
 *      - USAGE on the database and schema that host the semantic view
 *      - SELECT on underlying tables/views referenced by the semantic view
 *      - USAGE on the execution warehouse (for example, SFE_CORTEX_AGENTS_WH)
 *      - USAGE on the Cortex Agent object after creation
 *
 * 3. Create or update the agent via REST to add a Cortex Analyst tool
 *    referencing the semantic view:
 *
 * curl -X POST \"$SNOWFLAKE_ACCOUNT_BASE_URL/api/v2/databases/SNOWFLAKE_EXAMPLE/schemas/CORTEX_DEMO/agents\" \\
 * --header 'Content-Type: application/json' \\
 * --header 'Accept: application/json' \\
 * --header \"Authorization: Bearer $PAT\" \\
 * --data '{
 *   \"name\": \"SALES_CALLS_ANALYST\",
 *   \"comment\": \"DEMO: cortex-agents-teams - Sales call activity analyst\",
 *   \"models\": {
 *     \"orchestration\": \"claude-4-sonnet\"
 *   },
 *   \"instructions\": {
 *     \"system\": \"You are a revenue operations analyst. Answer questions about sales call activity using the configured semantic view. Respect RBAC and disclose data freshness timestamps when available.\",
 *     \"response\": \"Lead with the requested metric, then provide supporting context (time period, distributor, manufacturer) and cite the semantic view name in a Sources section.\",
 *     \"orchestration\": \"Plan your steps before querying. Prefer a single SQL statement per prompt and reuse results when possible.\",
 *     \"sample_questions\": [
 *       \"Show quarterly call volume by manufacturer for 2024\",
 *       \"Which distributors had a 10 percent decline in call activity year over year?\",
 *       \"List planned sales programs tied to MFR_SKU 10045\"
 *     ]
 *   },
 *   \"tools\": [
 *     {
 *       \"tool_spec\": {
 *         \"type\": \"cortex_analyst_text_to_sql\",
 *         \"name\": \"sales_calls_analyst\",
 *         \"description\": \"Structured analytics over VW_CORTEX_ANALYST_SALES_CALL_ACTIVITY\"
 *       }
 *     }
 *   ],
 *   \"tool_resources\": {
 *     \"sales_calls_analyst\": {
 *       \"semantic_view\": \"<DB>.<SCHEMA>.VW_CORTEX_ANALYST_SALES_CALL_ACTIVITY\",
 *       \"execution_environment\": {
 *         \"type\": \"warehouse\",
 *         \"warehouse\": \"SFE_CORTEX_AGENTS_WH\"
 *       },
 *       \"query_timeout\": 90
 *     }
 *   }
 * }'
 *
 *    Replace <DB>.<SCHEMA> with the production location for the semantic view
 *    (for example, CUSTOMER_ANALYTICS.CORTEX_SEMANTICS). Increase the timeout
 *    if the underlying datasets are large.
 *
 *    Smoke test the agent with the agent:run endpoint (requires Teams-linked
 *    OAuth token or PAT with appropriate scopes):
 *
 * curl -X POST \"$SNOWFLAKE_ACCOUNT_BASE_URL/api/v2/cortex/agent:run\" \\
 * --header 'Content-Type: application/json' \\
 * --header 'Accept: application/json' \\
 * --header \"Authorization: Bearer $PAT\" \\
 * --data '{
 *   \"agent_id\": {
 *     \"database\": \"SNOWFLAKE_EXAMPLE\",
 *     \"schema\": \"CORTEX_DEMO\",
 *     \"name\": \"SALES_CALLS_ANALYST\"
 *   },
 *   \"messages\": [
 *     {
 *       \"role\": \"user\",
 *       \"content\": [
 *         {
 *           \"type\": \"text\",
 *           \"text\": \"Which manufacturers increased call volume by at least 5 percent quarter over quarter?\"
 *         }
 *       ]
 *     }
 *   ]
 * }'
 *
 * 4. Grant the Teams-facing role access to the agent:
 *
 *    GRANT USAGE ON CORTEX AGENT SNOWFLAKE_EXAMPLE.CORTEX_DEMO.SALES_CALLS_ANALYST
 *        TO ROLE <SALES_CALLS_AGENT_ROLE>;
 *
 * Capture any deviations (multiple semantic views, additional Cortex Search
 * tools, different warehouses) in your runbook so the cleanup script can remove
 * the same grants.
 */

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Set context
USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA CORTEX_DEMO;

-- List all Cortex Agents in this schema
SHOW CORTEX AGENTS IN SCHEMA CORTEX_DEMO;

-- If agent was created successfully, you should see JOKE_ASSISTANT listed

SELECT 'Agent configuration script completed!' AS status,
       'Follow the instructions above to create the agent via Snowsight UI or REST API' AS next_step;

/*
 * NEXT STEPS:
 * -----------
 * 1. Run 04_create_security_integration.sql for Entra ID OAuth setup
 * 2. Run 05_grant_permissions.sql to grant access to users
 * 3. Follow docs/05-INSTALL-TEAMS-APP.md to install from AppSource
 */

