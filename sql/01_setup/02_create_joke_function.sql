/*******************************************************************************
 * DEMO PROJECT: Snowflake Cortex Agents for Microsoft Teams
 * Script: Create AI-Powered Joke Generation Function
 * 
 * ⚠️  NOT FOR PRODUCTION USE - EXAMPLE IMPLEMENTATION ONLY
 * 
 * PURPOSE:
 *   Creates a SQL function that uses Snowflake Cortex AI to generate
 *   safe-for-work jokes on any subject. Uses Cortex Guard to filter
 *   potentially unsafe content.
 * 
 * OBJECTS CREATED:
 *   - GENERATE_SAFE_JOKE(VARCHAR) - Function that wraps CORTEX.COMPLETE
 * 
 * DEPENDENCIES:
 *   - Requires SNOWFLAKE.CORTEX.COMPLETE function access
 *   - Requires 01_create_demo_objects.sql to be run first
 * 
 * CLEANUP:
 *   See sql/99_cleanup/teardown_all.sql
 *
 * EXECUTION TIME:
 *   < 10 seconds
 ******************************************************************************/

-- Ensure we're in the correct context
USE ROLE ACCOUNTADMIN;
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA CORTEX_DEMO;
USE WAREHOUSE SFE_CORTEX_AGENTS_WH;

-- ============================================================================
-- CREATE JOKE GENERATION FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION GENERATE_SAFE_JOKE(subject VARCHAR)
RETURNS VARCHAR
LANGUAGE SQL
COMMENT = 'DEMO: cortex-agents-teams - Generate safe-for-work jokes using Cortex AI with guardrails'
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
-- TEST THE FUNCTION
-- ============================================================================

-- Test 1: Data engineering joke
SELECT 'Test 1: Data Engineers' AS test_case,
       GENERATE_SAFE_JOKE('data engineers') AS joke;

-- Test 2: SQL joke
SELECT 'Test 2: SQL Queries' AS test_case,
       GENERATE_SAFE_JOKE('SQL queries') AS joke;

-- Test 3: Snowflake joke
SELECT 'Test 3: Snowflake' AS test_case,
       GENERATE_SAFE_JOKE('Snowflake database') AS joke;

-- Test 4: Cloud computing joke
SELECT 'Test 4: Cloud Computing' AS test_case,
       GENERATE_SAFE_JOKE('cloud computing') AS joke;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify function was created
SHOW USER FUNCTIONS LIKE 'GENERATE_SAFE_JOKE';

-- Display function details
DESCRIBE FUNCTION GENERATE_SAFE_JOKE(VARCHAR);

SELECT 'Joke generation function created and tested successfully!' AS status;

/*
 * USAGE EXAMPLES:
 * ---------------
 * SELECT GENERATE_SAFE_JOKE('Python programming');
 * SELECT GENERATE_SAFE_JOKE('machine learning');
 * SELECT GENERATE_SAFE_JOKE('databases');
 * 
 * NEXT STEPS:
 * -----------
 * 1. Run 03_create_cortex_agent.sql to create the Cortex Agent
 * 2. The agent will use this function as a tool for joke generation
 */

