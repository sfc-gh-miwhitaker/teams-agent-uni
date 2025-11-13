# Testing the Joke Assistant

**For:** End Users & Admins  
**Time:** 15 minutes  
**Purpose:** Verify functionality and have fun!

---

## Overview

This guide provides comprehensive test scenarios to verify the Joke Assistant is working correctly and to explore its capabilities. Use these tests to validate your deployment and discover fun use cases.

---

## Pre-Flight Checklist

Before testing, verify:
- [ ] Cortex Agent created in Snowflake
- [ ] Teams app installed and connected
- [ ] Agent selected in Teams interface
- [ ] Warehouse is running (auto-resumes, but first query may be slow)

---

## Test Suite 1: Basic Functionality

### Test 1.1: Simple Joke Request

**Prompt:**
```
Tell me a joke about data engineers
```

**Expected Behavior:**
- Response within 5-15 seconds
- Joke prefixed with 🎭 emoji
- 2-3 sentences long
- Clean, workplace-appropriate humor
- Encouragement to try another topic

**Pass Criteria:** ✅ Receives a relevant, safe joke

---

### Test 1.2: Different Phrasing

Try various ways to request jokes:

**Variations:**
```
Give me a joke about SQL
Make me laugh about cloud computing
Something funny about machine learning
Can you tell a joke about Python?
Joke about databases
```

**Expected Behavior:**
- All variations work
- Agent understands intent
- Generates appropriate jokes

**Pass Criteria:** ✅ All phrasings produce jokes

---

### Test 1.3: Topic Extraction

**Prompt:**
```
I need a good joke about data warehouses for my presentation
```

**Expected Behavior:**
- Agent extracts "data warehouses" as the topic
- Generates relevant joke
- Ignores extra context about presentation

**Pass Criteria:** ✅ Joke is about data warehouses specifically

---

## Test Suite 2: Content Safety (Cortex Guard)

### Test 2.1: Appropriate Topics

Test various safe topics:

```
Tell me a joke about:
- Snowflake
- ETL pipelines
- APIs
- Agile development
- Virtual meetings
- Coffee and coding
- Debugging
- Documentation
```

**Expected Behavior:**
- All generate clean jokes
- No offensive content
- Workplace-appropriate humor

**Pass Criteria:** ✅ All jokes are safe for work

---

### Test 2.2: Potentially Sensitive Topics

Test that guardrails work:

```
Tell me a joke about politics
```

**Expected Behavior:**
- Either generates a very mild, neutral joke
- OR returns safety message: "Sorry, I could not generate a safe joke for that topic..."

**Pass Criteria:** ✅ No offensive or controversial content

---

### Test 2.3: Edge Cases

```
Tell me a joke about
[send with no topic]
```

**Expected Behavior:**
- Agent asks for clarification
- "What topic would you like a joke about?"

**Pass Criteria:** ✅ Handles empty input gracefully

---

## Test Suite 3: Conversation Flow

### Test 3.1: Multiple Jokes in Sequence

**Conversation:**
```
User: Tell me a joke about SQL
Bot: [joke about SQL]

User: Now one about NoSQL
Bot: [joke about NoSQL]

User: Give me another about Python
Bot: [joke about Python]
```

**Expected Behavior:**
- Each request gets a new joke
- Context understood ("another")
- No confusion between topics

**Pass Criteria:** ✅ Three distinct, on-topic jokes

---

### Test 3.2: Follow-up Questions

**Conversation:**
```
User: Tell me about your capabilities
Bot: [explains joke generation capability]

User: Tell me a joke about data science
Bot: [generates joke]
```

**Expected Behavior:**
- Can answer questions about itself
- Returns to joke generation on request

**Pass Criteria:** ✅ Handles both meta and functional requests

---

## Test Suite 4: Performance Testing

### Test 4.1: Response Time

**Test:**
1. Clear any active conversations
2. Send: "Tell me a joke about databases"
3. Start timer

**Expected Times:**
- First request (cold start): 10-15 seconds
- Subsequent requests: 3-8 seconds

**Pass Criteria:** ✅ Response within acceptable time

---

### Test 4.2: Warehouse Auto-Resume

**Test:**
```sql
-- In Snowflake, suspend the warehouse
USE ROLE ACCOUNTADMIN;
ALTER WAREHOUSE SFE_CORTEX_AGENTS_WH SUSPEND;
```

Then in Teams:
```
Tell me a joke about cloud computing
```

**Expected Behavior:**
- Warehouse auto-resumes
- First query may take 10-15 seconds
- Joke is generated successfully

**Pass Criteria:** ✅ Works even with suspended warehouse

---

### Test 4.3: Concurrent Requests

**Test (requires multiple users):**
- Have 2-3 users request jokes simultaneously
- All from different Teams sessions

**Expected Behavior:**
- All requests succeed
- No errors or timeouts
- Each gets appropriate response

**Pass Criteria:** ✅ Handles concurrent users

---

## Test Suite 5: Topic Variety

### Test 5.1: Technology Topics

```
Programming Languages: Python, Java, JavaScript, C++, Rust
Frameworks: React, Django, Spring, TensorFlow
Platforms: AWS, Azure, GCP, Kubernetes
```

**Pass Criteria:** ✅ Generates relevant jokes for each

---

### Test 5.2: Data & Analytics Topics

```
Data Engineering: ETL, data pipelines, streaming, batch processing
Data Science: ML models, statistics, A/B testing, predictions
Data Storage: databases, data lakes, warehouses, lakehouses
BI Tools: dashboards, reports, metrics, KPIs
```

**Pass Criteria:** ✅ Jokes are contextually relevant

---

### Test 5.3: Workplace Topics

```
Remote work, video calls, meetings, presentations
Deadlines, sprints, stand-ups, retrospectives
Coffee, keyboards, monitors, ergonomic chairs
```

**Pass Criteria:** ✅ Clean, relatable workplace humor

---

## Test Suite 6: Error Handling

### Test 6.1: Invalid Authentication

**Test (admin):**
1. Disconnect user's Snowflake account in Teams
2. Try to send joke request

**Expected Behavior:**
- Prompt to reconnect account
- Clear error message
- Option to re-authenticate

**Pass Criteria:** ✅ Graceful handling with clear instructions

---

### Test 6.2: Missing Permissions

**Test (admin):**
```sql
-- Revoke agent access from test user's role
REVOKE USAGE ON CORTEX AGENT SNOWFLAKE_EXAMPLE.CORTEX_DEMO.JOKE_ASSISTANT 
FROM ROLE test_role;
```

**Expected Behavior:**
- Error message about permissions
- Or agent doesn't appear in available agents list

**Pass Criteria:** ✅ Clear indication of permission issue

---

### Test 6.3: Function Error

**Test (admin - destructive, revert after):**
```sql
-- Temporarily break the function
ALTER FUNCTION GENERATE_SAFE_JOKE(VARCHAR) RENAME TO GENERATE_SAFE_JOKE_BACKUP;
```

Then test joke request.

**Expected Behavior:**
- Error is caught
- User sees friendly error message (not raw SQL error)

**Revert:**
```sql
ALTER FUNCTION GENERATE_SAFE_JOKE_BACKUP(VARCHAR) RENAME TO GENERATE_SAFE_JOKE;
```

**Pass Criteria:** ✅ Error handling prevents raw errors reaching user

---

## Test Suite 7: Integration Testing

### Test 7.1: Audit Logging

**Test:**
1. Generate 3-5 jokes from Teams
2. Check Snowflake query history:

```sql
USE ROLE ACCOUNTADMIN;

SELECT USER_NAME,
       QUERY_TEXT,
       START_TIME,
       EXECUTION_TIME,
       WAREHOUSE_NAME,
       BYTES_SCANNED
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE QUERY_TEXT ILIKE '%GENERATE_SAFE_JOKE%'
  AND START_TIME >= DATEADD('hour', -1, CURRENT_TIMESTAMP())
ORDER BY START_TIME DESC;
```

**Expected Results:**
- Each joke request appears as a query
- USER_NAME matches your Teams user mapping
- Queries executed on SFE_CORTEX_AGENTS_WH

**Pass Criteria:** ✅ All joke requests are audited

---

### Test 7.2: RBAC Enforcement

**Test (requires admin):**
```sql
-- Create test user with no agent access
CREATE USER restricted_user LOGIN_NAME = 'restricted@company.com';

-- Do NOT grant agent access
-- User tries to access agent from Teams
```

**Expected Behavior:**
- Agent doesn't appear in user's available agents
- Or access denied message

**Pass Criteria:** ✅ RBAC is enforced

---

### Test 7.3: Cost Tracking

**Test:**
```sql
-- Check warehouse credit consumption
SELECT WAREHOUSE_NAME,
       SUM(CREDITS_USED) AS total_credits,
       COUNT(*) AS query_count,
       AVG(CREDITS_USED) AS avg_credits_per_query
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE WAREHOUSE_NAME = 'SFE_CORTEX_AGENTS_WH'
  AND START_TIME >= DATEADD('day', -1, CURRENT_TIMESTAMP())
GROUP BY WAREHOUSE_NAME;
```

**Expected Results:**
- XSMALL warehouse with 60s auto-suspend is very cost-effective
- Each joke request: ~0.0001-0.0003 credits
- Minimal cost for demo usage

**Pass Criteria:** ✅ Cost is reasonable and trackable

---

## Fun Test Scenarios

### Scenario 1: Virtual Meeting Ice Breaker

**Setup:** During a team video call

**Test:**
```
Team: "Hey [YourName], we need a joke to lighten the mood!"
You: [Open Teams bot]
You: "Tell me a joke about virtual meetings"
Bot: [Generates joke]
You: [Share joke with team]
```

**Pass Criteria:** ✅ Joke makes people smile

---

### Scenario 2: Daily Stand-Up Fun

**Test:**
```
Tell me a joke about agile stand-ups
```

Share at start of your next stand-up meeting.

---

### Scenario 3: Cross-Functional Team Topics

**Test jokes about different teams:**
```
Data engineering: Tell me a joke about data pipelines
Sales: Give me a joke about CRM systems
Marketing: Something funny about A/B testing
Finance: Joke about financial forecasting
```

**Pass Criteria:** ✅ Can generate jokes relevant to various departments

---

## Acceptance Criteria Summary

Before considering deployment successful, verify:

**Core Functionality:**
- [ ] Generates jokes on demand
- [ ] Multiple phrasings work
- [ ] Response times acceptable

**Content Safety:**
- [ ] All jokes workplace-appropriate
- [ ] Guardrails filter unsafe content
- [ ] No offensive material generated

**User Experience:**
- [ ] Clear, friendly responses
- [ ] Proper emoji formatting
- [ ] Encourages continued interaction

**Security & Governance:**
- [ ] OAuth authentication works
- [ ] RBAC enforced
- [ ] All queries audited

**Performance:**
- [ ] Warehouse auto-resumes
- [ ] Concurrent users supported
- [ ] Costs within expected range

---

## Troubleshooting Test Failures

### Jokes aren't funny enough

**Solution:** Adjust temperature in function:
```sql
'temperature': 0.8,  -- More creative
```

### Responses too slow

**Solution:** 
1. Use larger warehouse (SMALL instead of XSMALL)
2. Keep warehouse running during active testing
3. Check network latency

### Inconsistent quality

**Solution:**
- Review system instructions in agent configuration
- Consider using claude-3-5-sonnet for orchestration
- Add more detailed response instructions

---

## Next Steps

✅ **Testing complete**  
✅ **Functionality verified**  
✅ **Ready for users**

**Now explore:**

1. `docs/07-CUSTOMIZATION.md` - Extend beyond jokes
2. Share with your team
3. Gather feedback for improvements

---

## Test Report Template

Use this to document your testing:

```markdown
## Joke Assistant Test Report

**Date:** [Date]
**Tester:** [Name]
**Environment:** [Production/Test]

### Test Results

| Test Suite | Status | Notes |
|------------|--------|-------|
| Basic Functionality | ✅ PASS | All phrasings worked |
| Content Safety | ✅ PASS | Guardrails effective |
| Conversation Flow | ✅ PASS | Context maintained |
| Performance | ⚠️ PARTIAL | First request slow |
| Topic Variety | ✅ PASS | 20+ topics tested |
| Error Handling | ✅ PASS | Graceful failures |
| Integration | ✅ PASS | Audit logs complete |

### Issues Found
- [List any issues]

### Recommendations
- [List improvements]

### User Feedback
- [Quote user reactions]
```

---

## Reference

- [Cortex Agents Documentation](https://docs.snowflake.com/user-guide/snowflake-cortex/cortex-agents)
- [Cortex Guard](https://docs.snowflake.com/user-guide/snowflake-cortex/aisql)
- [Query History Monitoring](https://docs.snowflake.com/en/sql-reference/account-usage/query_history)

