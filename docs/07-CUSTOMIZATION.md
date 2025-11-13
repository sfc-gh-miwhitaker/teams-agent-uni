# Customization & Real-World Use Cases

**For:** Snowflake Administrators & Developers  
**Audience:** Post-demo expansion  
**Purpose:** Transform joke bot into production analytics

---

## Overview

The Joke Assistant demonstrates Cortex Agents capabilities in a fun, safe way. This guide shows how to extend the same architecture for real business use cases: data querying, report generation, and intelligent analytics.

---

## From Jokes to Business Intelligence

### Architecture Pattern

The joke bot uses a simple, repeatable pattern:

```
User Question → Agent Orchestration → SQL Function/Tool → Cortex AI → Response
```

This **same pattern** powers enterprise analytics:

```
"What were Q4 sales?" → Agent → sales_data tool → Cortex Analyst → "Q4 sales: $2.3M"
```

---

## Use Case 1: Sales Analytics Agent

### Business Need

Sales team needs instant answers about revenue, pipeline, and performance without waiting for BI reports.

### Implementation

**Step 1: Create Semantic View (Cortex Analyst)**

```sql
-- Create base sales table (example)
CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.ANALYTICS.SALES_DATA (
    sale_id NUMBER,
    sale_date DATE,
    customer_name VARCHAR,
    product_name VARCHAR,
    quantity NUMBER,
    unit_price NUMBER(10,2),
    total_amount NUMBER(10,2),
    sales_rep VARCHAR,
    region VARCHAR
);

-- Create semantic model (YAML)
-- Save as: @SNOWFLAKE_EXAMPLE.ANALYTICS.STAGES/sales_semantic_model.yaml
```

**Semantic Model (sales_semantic_model.yaml):**
```yaml
name: "Sales Performance Model"
description: "Sales data for Q4 2024 through Q1 2025"

tables:
  - name: SALES_DATA
    description: "Daily sales transactions"
    base_table:
      database: SNOWFLAKE_EXAMPLE
      schema: ANALYTICS
      table: SALES_DATA
    
    dimensions:
      - name: sale_date
        synonyms: ["date", "transaction date", "when"]
        data_type: date
        description: "Date of sale"
      
      - name: customer_name
        synonyms: ["customer", "client", "account"]
        data_type: varchar
        description: "Customer who made purchase"
      
      - name: sales_rep
        synonyms: ["rep", "salesperson", "account executive"]
        data_type: varchar
        description: "Sales representative"
      
      - name: region
        synonyms: ["territory", "area", "market"]
        data_type: varchar
        description: "Sales region"
    
    measures:
      - name: total_amount
        synonyms: ["revenue", "sales", "amount"]
        data_type: number
        aggregation: sum
        description: "Total sales revenue"
      
      - name: quantity
        synonyms: ["units sold", "volume"]
        data_type: number
        aggregation: sum
        description: "Number of units sold"
    
    time_dimensions:
      - name: sale_date
        grain: day
```

**Step 2: Create Sales Agent**

In Snowsight:
1. Navigate to: AI & ML → Cortex Agents → Create
2. Name: `SALES_ASSISTANT`
3. Add Cortex Analyst tool with semantic view
4. Configure instructions:

```
System Instructions:
You are a sales analytics assistant. Answer questions about sales performance,
revenue, pipeline, and team metrics using the sales_data tool. Provide clear,
actionable insights with specific numbers and trends.

Response Instructions:
- Start with the direct answer
- Include relevant metrics and comparisons
- Format numbers with currency symbols ($) where appropriate
- Suggest follow-up questions if relevant
- Visualize trends when asked

Sample Questions:
- "What were total sales last quarter?"
- "Who are our top 5 customers by revenue?"
- "Show sales trend by region for the past 6 months"
- "Which products are underperforming?"
```

**Step 3: Grant Permissions**

```sql
-- Grant access to sales team role
GRANT USAGE ON CORTEX AGENT SNOWFLAKE_EXAMPLE.ANALYTICS.SALES_ASSISTANT 
    TO ROLE SALES_TEAM;

-- Grant underlying data access
GRANT SELECT ON TABLE SNOWFLAKE_EXAMPLE.ANALYTICS.SALES_DATA 
    TO ROLE SALES_TEAM;
```

**Step 4: Test in Teams**

```
User: "What were total sales last month?"
Agent: "Total sales for January 2025 were $2.34M, up 12% from December 2024 ($2.09M).
        
        Top performing regions:
        1. West: $890K (38%)
        2. East: $720K (31%)
        3. Central: $730K (31%)
        
        Would you like to see a breakdown by product or sales rep?"
```

---

## Use Case 2: Customer Support Agent

### Business Need

Support team needs instant access to customer data, ticket history, and product information.

### Implementation

**Step 1: Create Cortex Search Service**

```sql
-- Create customer knowledge base table
CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.SUPPORT.KNOWLEDGE_BASE (
    article_id NUMBER,
    title VARCHAR,
    content TEXT,
    category VARCHAR,
    tags ARRAY,
    created_date DATE,
    last_updated DATE
);

-- Create Cortex Search service
CREATE CORTEX SEARCH SERVICE SNOWFLAKE_EXAMPLE.SUPPORT.KB_SEARCH
    ON content
    ATTRIBUTES category, tags, title
    WAREHOUSE = SFE_CORTEX_AGENTS_WH
    TARGET_LAG = '1 hour'
AS (
    SELECT article_id,
           title,
           content,
           category,
           tags
    FROM SNOWFLAKE_EXAMPLE.SUPPORT.KNOWLEDGE_BASE
);
```

**Step 2: Create Support Agent**

```sql
-- Agent with Cortex Search tool (via Snowsight UI)
-- Name: SUPPORT_ASSISTANT
-- Tools:
--   1. Cortex Search: KB_SEARCH (knowledge base search)
--   2. SQL Execution: customer_lookup (find customer details)
--   3. SQL Execution: ticket_history (get support ticket history)
```

**Sample Interactions:**

```
User: "How do I reset a customer's password?"
Agent: "Based on our knowledge base:
        
        To reset a customer password:
        1. Navigate to Admin → Users
        2. Search for the customer
        3. Click 'Reset Password'
        4. Send the reset link via email
        
        [Source: Article #145 - 'Password Management']
        
        Need help finding a specific customer?"
```

---

## Use Case 3: HR Analytics Agent

### Business Need

HR team needs self-service access to headcount, turnover, and diversity metrics.

### Implementation

**Step 1: Create HR Views with Row-Level Security**

```sql
-- Base employee table (restricted)
CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.HR.EMPLOYEES (
    employee_id NUMBER,
    full_name VARCHAR,
    department VARCHAR,
    job_title VARCHAR,
    hire_date DATE,
    manager_id NUMBER,
    location VARCHAR,
    employment_status VARCHAR,
    salary NUMBER -- Masked by policy
);

-- Create row-level security policy
CREATE OR REPLACE ROW ACCESS POLICY SNOWFLAKE_EXAMPLE.HR.EMPLOYEE_ACCESS_POLICY
AS (current_user_role VARCHAR) RETURNS BOOLEAN ->
    CASE
        WHEN current_user_role = 'HR_ADMIN' THEN TRUE
        WHEN current_user_role = 'MANAGER' 
            THEN manager_id = (SELECT employee_id FROM employees WHERE login_name = CURRENT_USER())
        ELSE FALSE
    END;

-- Apply policy
ALTER TABLE SNOWFLAKE_EXAMPLE.HR.EMPLOYEES 
    ADD ROW ACCESS POLICY EMPLOYEE_ACCESS_POLICY ON (CURRENT_ROLE());

-- Create aggregate view for metrics
CREATE OR REPLACE SECURE VIEW SNOWFLAKE_EXAMPLE.HR.HR_METRICS AS
SELECT 
    department,
    COUNT(*) AS headcount,
    AVG(DATEDIFF('month', hire_date, CURRENT_DATE())) AS avg_tenure_months,
    COUNT(CASE WHEN employment_status = 'Active' THEN 1 END) AS active_count
FROM SNOWFLAKE_EXAMPLE.HR.EMPLOYEES
GROUP BY department;
```

**Step 2: Create HR Agent**

```
System Instructions:
You are an HR analytics assistant. Provide insights on headcount, 
turnover, and workforce metrics. Respect data governance policies - 
never show individual salary information.

Sample Questions:
- "What's our current headcount by department?"
- "Which departments have the highest turnover?"
- "Show hiring trends over the past year"
- "What's the average tenure in Engineering?"
```

**RBAC Enforcement:**
- Agent executes queries as the user's role
- Row-level security automatically applied
- Managers see only their teams
- HR admins see full data

---

## Use Case 4: Financial Reporting Agent

### Business Need

Finance team needs instant P&L summaries, variance analysis, and budget tracking.

### Implementation

**Step 1: Create Financial Data Model**

```sql
CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.FINANCE.GL_TRANSACTIONS (
    transaction_id NUMBER,
    transaction_date DATE,
    account_number VARCHAR,
    account_name VARCHAR,
    account_type VARCHAR, -- Revenue, Expense, Asset, Liability
    amount NUMBER(15,2),
    currency VARCHAR,
    cost_center VARCHAR,
    fiscal_year NUMBER,
    fiscal_quarter NUMBER
);

-- Create budget comparison view
CREATE OR REPLACE VIEW SNOWFLAKE_EXAMPLE.FINANCE.BUDGET_VS_ACTUAL AS
SELECT 
    fiscal_quarter,
    account_type,
    SUM(CASE WHEN transaction_type = 'Budget' THEN amount ELSE 0 END) AS budget,
    SUM(CASE WHEN transaction_type = 'Actual' THEN amount ELSE 0 END) AS actual,
    (actual - budget) AS variance,
    (variance / NULLIF(budget, 0)) * 100 AS variance_pct
FROM SNOWFLAKE_EXAMPLE.FINANCE.GL_TRANSACTIONS
GROUP BY fiscal_quarter, account_type;
```

**Step 2: Configure Financial Agent**

```
System Instructions:
You are a financial analyst assistant. Provide accurate P&L summaries, 
variance analysis, and budget tracking. Always format currency with $ 
and use accounting conventions (negatives in parentheses for losses).

When showing variance:
- Favorable variance: Green indicator
- Unfavorable variance: Red indicator
- Include both absolute ($) and percentage (%) changes

Sample Questions:
- "What's our Q4 net income?"
- "Show revenue vs budget by quarter"
- "Which cost centers are over budget?"
- "Compare this year's expenses to last year"
```

---

## Use Case 5: Data Quality Monitoring Agent

### Business Need

Data engineering team needs proactive alerts about data quality issues.

### Implementation

**Step 1: Create Data Quality Metrics**

```sql
CREATE OR REPLACE TABLE SNOWFLAKE_EXAMPLE.DATA_OPS.DQ_METRICS (
    check_id NUMBER,
    table_name VARCHAR,
    check_type VARCHAR, -- Completeness, Accuracy, Timeliness, Consistency
    check_timestamp TIMESTAMP,
    pass_fail VARCHAR,
    metric_value NUMBER,
    threshold NUMBER,
    details VARIANT
);

-- Create function to query data quality
CREATE OR REPLACE FUNCTION CHECK_DATA_QUALITY(table_pattern VARCHAR)
RETURNS TABLE (
    table_name VARCHAR,
    failing_checks NUMBER,
    last_check_time TIMESTAMP,
    severity VARCHAR
)
AS
$$
    SELECT table_name,
           COUNT(*) AS failing_checks,
           MAX(check_timestamp) AS last_check_time,
           MAX(CASE 
               WHEN metric_value < (threshold * 0.8) THEN 'Critical'
               WHEN metric_value < threshold THEN 'Warning'
               ELSE 'OK'
           END) AS severity
    FROM SNOWFLAKE_EXAMPLE.DATA_OPS.DQ_METRICS
    WHERE table_name LIKE table_pattern
      AND pass_fail = 'FAIL'
      AND check_timestamp >= DATEADD('day', -1, CURRENT_TIMESTAMP())
    GROUP BY table_name
$$;
```

**Step 2: Create Data Quality Agent**

```
System Instructions:
You are a data quality assistant. Alert users to data quality issues, 
explain their impact, and suggest remediation steps. Be proactive - 
if you detect critical issues, emphasize urgency.

Response Instructions:
- Severity levels: 🔴 Critical, 🟡 Warning, 🟢 OK
- Include affected tables, row counts, and check types
- Suggest root cause analysis steps
- Provide links to data lineage if available

Sample Questions:
- "Are there any data quality issues in the last 24 hours?"
- "Check the completeness of customer_data table"
- "Which tables failed timeliness checks?"
- "Show me critical data quality alerts"
```

---

## Advanced Customization Patterns

### Pattern 1: Multi-Tool Agents

Combine multiple tools for complex workflows:

```yaml
Agent: CUSTOMER_360_ASSISTANT

Tools:
  1. Cortex Analyst (customer_sales_history) - Sales data
  2. Cortex Search (support_tickets) - Support interactions
  3. SQL Execution (churn_prediction) - ML model inference
  4. SQL Execution (sentiment_analysis) - Text analysis

Orchestration:
When asked about customer health, the agent:
1. Queries sales history (Tool 1)
2. Searches support tickets (Tool 2)
3. Runs churn prediction (Tool 3)
4. Analyzes sentiment (Tool 4)
5. Synthesizes comprehensive customer health score
```

### Pattern 2: Scheduled Proactive Alerts

Create agents that proactively notify users:

```sql
-- Create task to check for anomalies
CREATE OR REPLACE TASK PROACTIVE_ANOMALY_DETECTION
    WAREHOUSE = SFE_CORTEX_AGENTS_WH
    SCHEDULE = 'USING CRON 0 8 * * * America/Los_Angeles'  -- 8 AM daily
AS
CALL SEND_TEAMS_NOTIFICATION(
    'Daily Metrics Alert',
    'Yesterday revenue was 15% below forecast. Details: ...'
);
```

### Pattern 3: Dynamic Context Injection

Pass user context to improve responses:

```sql
CREATE OR REPLACE FUNCTION PERSONALIZED_INSIGHT(user_role VARCHAR)
RETURNS VARCHAR
AS
$$
    SELECT SNOWFLAKE.CORTEX.COMPLETE(
        'claude-3-5-sonnet',
        [
            {'role': 'system', 'content': 'Tailor insights to user role: ' || user_role},
            {'role': 'user', 'content': 'What should I focus on today?'}
        ]
    )
$$;
```

---

## Best Practices for Production Agents

### 1. Security & Governance

```sql
-- Principle of Least Privilege
GRANT USAGE ON CORTEX AGENT prod_sales_agent TO ROLE sales_analyst;
-- NOT to PUBLIC

-- Audit agent usage
CREATE OR REPLACE VIEW AGENT_USAGE_LOG AS
SELECT USER_NAME,
       QUERY_TEXT,
       EXECUTION_TIME,
       ROWS_PRODUCED,
       START_TIME
FROM SNOWFLAKE.ACCOUNT_USAGE.QUERY_HISTORY
WHERE QUERY_TEXT LIKE '%CORTEX AGENT%';
```

### 2. Performance Optimization

```sql
-- Use appropriate warehouse size
CREATE WAREHOUSE PROD_AGENT_WH WITH
    WAREHOUSE_SIZE = 'SMALL'  -- Not XSMALL for production
    AUTO_SUSPEND = 300  -- 5 minutes for production
    AUTO_RESUME = TRUE;

-- Create result caching views
CREATE OR REPLACE VIEW CACHED_SALES_SUMMARY AS
SELECT * FROM sales_data
WHERE sale_date >= DATEADD('month', -3, CURRENT_DATE());
```

### 3. Error Handling

```sql
-- Add error handling to functions
CREATE OR REPLACE FUNCTION SAFE_QUERY_SALES(region VARCHAR)
RETURNS VARCHAR
AS
$$
DECLARE
    result VARCHAR;
BEGIN
    TRY
        SELECT total_sales INTO result
        FROM sales_summary
        WHERE sales_region = region;
        
        RETURN result;
    EXCEPTION
        WHEN statement_error THEN
            RETURN 'Unable to retrieve sales data. Please contact support.';
    END TRY;
END;
$$;
```

### 4. Cost Management

```sql
-- Monitor agent costs
SELECT WAREHOUSE_NAME,
       DATE_TRUNC('day', START_TIME) AS usage_date,
       SUM(CREDITS_USED) AS daily_credits
FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
WHERE WAREHOUSE_NAME LIKE '%AGENT%'
GROUP BY 1, 2
ORDER BY usage_date DESC;

-- Set resource monitors
CREATE RESOURCE MONITOR agent_monthly_budget WITH
    CREDIT_QUOTA = 100
    FREQUENCY = MONTHLY
    TRIGGERS
        ON 80 PERCENT DO NOTIFY
        ON 100 PERCENT DO SUSPEND;

ALTER WAREHOUSE PROD_AGENT_WH SET RESOURCE_MONITOR = agent_monthly_budget;
```

---

## Migration Checklist: Demo → Production

- [ ] Replace joke function with business logic
- [ ] Create semantic models for your data
- [ ] Configure Cortex Search for knowledge bases
- [ ] Implement row-level security policies
- [ ] Set up proper RBAC (no PUBLIC grants)
- [ ] Use dedicated production warehouse
- [ ] Configure resource monitors
- [ ] Enable query tagging for cost attribution
- [ ] Set up monitoring and alerting
- [ ] Document agent capabilities for end users
- [ ] Train users on agent interaction patterns
- [ ] Establish feedback mechanism

---

## Example: Complete Sales Agent Setup

**File: `sql/production/create_sales_agent.sql`**

```sql
-- Full production sales agent setup
USE ROLE ACCOUNTADMIN;

-- 1. Create schema
CREATE SCHEMA IF NOT EXISTS PROD.SALES_ANALYTICS;

-- 2. Create semantic view
CREATE SEMANTIC VIEW PROD.SALES_ANALYTICS.SALES_VIEW
    FROM PROD.RAW.SALES_DATA;

-- 3. Create agent
-- (Via Snowsight UI or REST API with production configuration)

-- 4. Grant access
GRANT USAGE ON CORTEX AGENT PROD.SALES_ANALYTICS.SALES_ASSISTANT
    TO ROLE SALES_ANALYST;

-- 5. Set up monitoring
CREATE ALERT sales_agent_high_usage
    WAREHOUSE = monitoring_wh
    SCHEDULE = '60 MINUTE'
IF (
    SELECT SUM(CREDITS_USED) 
    FROM SNOWFLAKE.ACCOUNT_USAGE.WAREHOUSE_METERING_HISTORY
    WHERE WAREHOUSE_NAME = 'SALES_AGENT_WH'
      AND START_TIME >= DATEADD('hour', -1, CURRENT_TIMESTAMP())
) > 10
THEN
    CALL SYSTEM$SEND_EMAIL(
        'snowflake-admins@company.com',
        'Sales Agent High Usage Alert',
        'Sales agent warehouse consumed >10 credits in the last hour'
    );
```

---

## Next Steps

✅ **Joke bot working**  
✅ **Production patterns understood**  
✅ **Ready to build real agents**

**Start your production agent:**

1. Identify high-value use case
2. Design data model and semantic view
3. Create pilot agent for small team
4. Gather feedback and iterate
5. Scale to broader organization

**Resources:**
- [Cortex Analyst Semantic Models](https://docs.snowflake.com/user-guide/snowflake-cortex/cortex-analyst)
- [Cortex Search](https://docs.snowflake.com/user-guide/snowflake-cortex/cortex-search)
- [Row-Level Security](https://docs.snowflake.com/user-guide/security-row)

---

**Remember:** The joke bot is just the beginning. The same architecture powers enterprise AI that transforms how your organization accesses and understands data. 🚀

