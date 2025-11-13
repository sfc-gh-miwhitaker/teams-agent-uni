# Create Cortex Agent

**For:** Snowflake ACCOUNTADMIN  
**Time:** 10 minutes  
**Frequency:** Once per agent

---

## Overview

This guide walks through creating a Cortex Agent object in Snowflake that generates safe-for-work jokes using AI. The agent will be accessible from Microsoft Teams and uses Snowflake Cortex AI with guardrails for content safety.

---

## Prerequisites

Before you begin:
- [ ] Security integration created (see `docs/03-SNOWFLAKE-SECURITY-INTEGRATION.md`)
- [ ] ACCOUNTADMIN access to Snowflake
- [ ] Snowsight access (for UI method)

---

## Step 1: Create Foundation Objects

Run the setup scripts in order:

### 1.1 Create Database, Schema, Warehouse

```sql
-- Execute: sql/01_setup/01_create_demo_objects.sql
```

In Snowsight:
1. Open new SQL worksheet
2. Click "..." → "Load Script"
3. Select `sql/01_setup/01_create_demo_objects.sql`
4. Click "Run All"

**Verify:**
```sql
USE DATABASE SNOWFLAKE_EXAMPLE;
USE SCHEMA CORTEX_DEMO;
USE WAREHOUSE SFE_CORTEX_AGENTS_WH;

SELECT CURRENT_DATABASE(), CURRENT_SCHEMA(), CURRENT_WAREHOUSE();
```

### 1.2 Create Joke Generation Function

```sql
-- Execute: sql/01_setup/02_create_joke_function.sql
```

This creates the `GENERATE_SAFE_JOKE(VARCHAR)` function that wraps Cortex AI.

**Test the function:**
```sql
SELECT GENERATE_SAFE_JOKE('data engineers');
SELECT GENERATE_SAFE_JOKE('SQL databases');
SELECT GENERATE_SAFE_JOKE('Snowflake');
```

**Expected output:** Clean, workplace-appropriate jokes (2-3 sentences each).

---

## Step 2: Create Cortex Agent

You have two options: Snowsight UI (recommended) or REST API (advanced).

---

## Option A: Create Agent via Snowsight UI (Recommended)

### Step 2.1: Navigate to Cortex Agents

1. Log into Snowsight
2. Ensure you're using ACCOUNTADMIN role
3. Navigate to: **Projects** → **AI & ML** → **Cortex Agents**
4. Click **"+ Agent"** or **"Create"**

### Step 2.2: Configure Basic Details

**Agent Name:**
```
JOKE_ASSISTANT
```

**Database:**
```
SNOWFLAKE_EXAMPLE
```

**Schema:**
```
CORTEX_DEMO
```

**Display Name:**
```
Joke Assistant
```

**Description:**
```
I'm your friendly AI assistant powered by Snowflake Cortex AI! Ask me for a joke about any topic, and I'll generate a clean, workplace-appropriate joke just for you. Try me with subjects like data engineering, SQL, cloud computing, or anything else!
```

**Comment:**
```
DEMO: cortex-agents-teams - AI-powered joke bot with content safety guardrails
```

### Step 2.3: Add Sample Questions

Click **"+ Add question"** and add these sample questions:

1. `Tell me a joke about data engineers`
2. `Give me a joke about SQL databases`
3. `Make me laugh about cloud computing`
4. `Tell me something funny about Snowflake`
5. `Can you joke about Python programming?`

These help users understand what to ask.

### Step 2.4: Configure Agent Instructions

**System Instructions:**
```
You are a friendly, enthusiastic AI comedian specializing in tech humor. Your job is to:
1. Generate workplace-appropriate jokes on any topic using the joke_generator tool
2. Be upbeat and encouraging
3. Add emojis to make responses fun and engaging
4. If asked about your capabilities, explain you can tell jokes about any subject
5. Always use the joke_generator tool when users request jokes

Keep your personality cheerful and professional.
```

**Response Instructions:**
```
When delivering jokes:
- Prefix each joke with the 🎭 emoji
- Keep responses brief (just the joke, no long explanations)
- If users ask for multiple jokes, generate one at a time
- Encourage users to try different topics after each joke
- If the joke generator returns an unsafe response message, politely suggest a different topic

Examples of good responses:
"🎭 [The joke here]"
"Want another one? Try asking about a different topic!"
```

**Orchestration Instructions (Advanced - Optional):**
```
When a user message indicates they want a joke:
1. Extract the subject/topic from their message
2. Call the joke_generator tool with that subject
3. Return the result with appropriate formatting
4. If no clear subject is provided, ask them what topic they'd like

User intent patterns that indicate joke requests:
- "tell me a joke about X"
- "give me a joke"
- "make me laugh about X"
- "something funny about X"
- "can you joke about X"
```

### Step 2.5: Add Custom SQL Tool

Click **"Add tool"** → **"Custom SQL"**

**Tool Name:**
```
joke_generator
```

**Tool Type:**
```
SQL Execution
```

**Description:**
```
Generates safe, workplace-appropriate jokes about any subject using Snowflake Cortex AI with content safety guardrails
```

**SQL Query:**
```sql
SELECT GENERATE_SAFE_JOKE(?)
```

**Warehouse:**
```
SFE_CORTEX_AGENTS_WH
```

**Query Timeout (seconds):**
```
30
```

**Parameter Mapping:**
- Input Parameter 1: `subject` (type: STRING)

### Step 2.6: Configure Model (Optional)

**Orchestration Model (Recommended):**
```
claude-3-5-sonnet
```

This provides the best quality for intent understanding and response generation.

**Alternative models:**
- `llama3.3-70b` (good balance of speed/quality)
- `mistral-large` (fast responses)

### Step 2.7: Review and Create

1. Review all settings
2. Click **"Create Agent"**
3. Wait for confirmation message

**Verify:**
```sql
SHOW CORTEX AGENTS IN SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_DEMO;
```

You should see `JOKE_ASSISTANT` listed.

---

## Option B: Create Agent via REST API (Advanced)

For automation or programmatic deployment:

### Step 2.1: Set Up Environment

```bash
# Export your Snowflake account URL
export SNOWFLAKE_ACCOUNT_BASE_URL="https://<account>.snowflakecomputing.com"

# Generate a Personal Access Token in Snowsight:
# User icon → Account → Personal Access Tokens → Generate New Token
export PAT="your_personal_access_token"
```

### Step 2.2: Create Agent via API

```bash
curl -X POST "$SNOWFLAKE_ACCOUNT_BASE_URL/api/v2/databases/SNOWFLAKE_EXAMPLE/schemas/CORTEX_DEMO/agents" \
--header 'Content-Type: application/json' \
--header 'Accept: application/json' \
--header "Authorization: Bearer $PAT" \
--data '{
  "name": "JOKE_ASSISTANT",
  "comment": "DEMO: cortex-agents-teams - AI-powered joke bot",
  "profile": {
    "display_name": "Joke Assistant",
    "avatar": "🎭"
  },
  "models": {
    "orchestration": "claude-3-5-sonnet"
  },
  "instructions": {
    "system": "You are a friendly, enthusiastic AI comedian specializing in tech humor. When users ask for jokes, use the joke_generator tool with their subject. Be upbeat and add emojis!",
    "response": "Prefix jokes with 🎭 emoji. Keep responses brief. Encourage users to try different topics.",
    "orchestration": "Extract subject from user message and call joke_generator tool.",
    "sample_questions": [
      "Tell me a joke about data engineers",
      "Give me a joke about SQL databases",
      "Make me laugh about cloud computing",
      "Tell me something funny about Snowflake"
    ]
  },
  "tools": [
    {
      "tool_spec": {
        "type": "sql_execution",
        "name": "joke_generator",
        "description": "Generates safe, workplace-appropriate jokes using AI"
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
```

**Verify:**
```bash
curl -X GET "$SNOWFLAKE_ACCOUNT_BASE_URL/api/v2/databases/SNOWFLAKE_EXAMPLE/schemas/CORTEX_DEMO/agents/JOKE_ASSISTANT" \
--header "Authorization: Bearer $PAT"
```

---

## Step 3: Grant Permissions

Run the permissions script to allow users to access the agent:

```sql
-- Execute: sql/01_setup/05_grant_permissions.sql
```

This grants:
- Database and schema USAGE
- Warehouse USAGE
- Function execution rights
- Agent access (to PUBLIC role by default)

**For production:** Modify script to grant to specific roles instead of PUBLIC.

---

## Step 4: Test the Agent

### Test via Snowsight (if available)

1. In Snowsight, navigate to: **Projects** → **AI & ML** → **Cortex Agents**
2. Click on **JOKE_ASSISTANT**
3. In the test panel, try:

```
Tell me a joke about data engineers
```

**Expected response:**
```
🎭 Why do data engineers prefer dark mode? 
Because light attracts bugs, and they've got enough in their pipelines already! 😄

Want another one? Try asking about a different topic!
```

### Test via SQL (Direct Function Call)

```sql
-- Test the underlying function directly
SELECT GENERATE_SAFE_JOKE('machine learning') AS joke;
SELECT GENERATE_SAFE_JOKE('databases') AS joke;
SELECT GENERATE_SAFE_JOKE('Python') AS joke;
```

### Verify Guardrails

Test that unsafe content is filtered:

```sql
-- This should return the safety message, not an unsafe joke
SELECT GENERATE_SAFE_JOKE('inappropriate topic') AS joke;
```

**Expected:** Safety filter message like "Sorry, I could not generate a safe joke..."

---

## Customizing the Agent

### Adjust Temperature for Joke Quality

More creative (higher temperature):
```sql
-- Edit the function to change temperature
CREATE OR REPLACE FUNCTION GENERATE_SAFE_JOKE(subject VARCHAR)
...
'temperature': 0.9,  -- More random/creative (was 0.7)
...
```

More consistent (lower temperature):
```sql
'temperature': 0.5,  -- More deterministic
```

### Change LLM Model

For faster responses:
```sql
-- Edit function to use different model
SELECT SNOWFLAKE.CORTEX.COMPLETE(
  'llama3.3-70b',  -- Faster than mistral-large
  ...
)
```

### Add More Sample Questions

In Snowsight:
1. Edit agent
2. Add sample questions specific to your industry:
   - "Tell me a joke about retail analytics"
   - "Give me a joke about healthcare data"
   - "Make me laugh about financial modeling"

---

## Troubleshooting

### Agent doesn't appear in Cortex Agents list

**Solution:**
```sql
-- Verify agent exists
SHOW CORTEX AGENTS IN SCHEMA SNOWFLAKE_EXAMPLE.CORTEX_DEMO;

-- Check you're in the right context
SELECT CURRENT_DATABASE(), CURRENT_SCHEMA(), CURRENT_ROLE();
```

### "Function does not exist" error

**Solution:**
```sql
-- Verify function exists
SHOW USER FUNCTIONS LIKE 'GENERATE_SAFE_JOKE';

-- Grant usage if needed
GRANT USAGE ON FUNCTION SNOWFLAKE_EXAMPLE.CORTEX_DEMO.GENERATE_SAFE_JOKE(VARCHAR) 
  TO ROLE PUBLIC;
```

### Jokes are too similar or repetitive

**Solution:** Increase temperature in function:
```sql
'temperature': 0.8,  -- More variety
```

### Agent doesn't use the tool

**Solution:** Update orchestration instructions to be more explicit:
```
When user asks for a joke, ALWAYS call joke_generator tool with their subject.
```

---

## Next Steps

✅ **Agent created**  
✅ **Permissions granted**  
✅ **Agent tested**

**Now proceed to:**

1. `docs/05-INSTALL-TEAMS-APP.md` - Install Cortex Agents in Microsoft Teams
2. Connect your Snowflake account
3. Start chatting with the Joke Assistant!

---

## Reference

- [Cortex Agents Documentation](https://docs.snowflake.com/user-guide/snowflake-cortex/cortex-agents)
- [Cortex AI Functions](https://docs.snowflake.com/user-guide/snowflake-cortex/aisql)
- [Agent REST API](https://docs.snowflake.com/user-guide/snowflake-cortex/cortex-agents/rest-api)

