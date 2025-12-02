# Data Model - Snowflake Cortex Agents for Microsoft Teams

Author: SE Community  
Last Updated: 2025-12-02  
Expires: 2026-01-01 (30 days from creation)  
Status: Reference Implementation

![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)

Reference Implementation: This code demonstrates production-grade architectural patterns and best practices. Review and customize security, networking, and logic for your organization's specific requirements before deployment.

## Overview

This diagram shows the database schema and object relationships for the Cortex Agents Teams integration demo. The demo uses a minimal schema focused on the AI joke generation function and Cortex Agent configuration. For production analytics use cases, the semantic view pattern (shown in dashed lines) demonstrates how to connect existing governed data assets.

## Diagram

```mermaid
erDiagram
    SNOWFLAKE_EXAMPLE ||--o{ CORTEX_DEMO : contains
    CORTEX_DEMO ||--|| GENERATE_SAFE_JOKE : "has function"
    CORTEX_DEMO ||--o| JOKE_ASSISTANT : "has agent"
    
    SNOWFLAKE_EXAMPLE {
        string database_name PK "SNOWFLAKE_EXAMPLE"
        string comment "Demo repository"
        date expires "2026-01-01"
    }
    
    CORTEX_DEMO {
        string schema_name PK "CORTEX_DEMO"
        string database_name FK "SNOWFLAKE_EXAMPLE"
        string comment "Agent objects"
        date expires "2026-01-01"
    }
    
    GENERATE_SAFE_JOKE {
        string function_name PK "GENERATE_SAFE_JOKE"
        string input_param "subject VARCHAR"
        string return_type "VARCHAR"
        string model "mistral-large"
        boolean guardrails "true"
    }
    
    JOKE_ASSISTANT {
        string agent_name PK "JOKE_ASSISTANT"
        string tool "joke_generator"
        string orchestration_model "claude-3-5-sonnet"
        string warehouse FK "SFE_CORTEX_AGENTS_WH"
    }
    
    SFE_CORTEX_AGENTS_WH {
        string warehouse_name PK "SFE_CORTEX_AGENTS_WH"
        string size "XSMALL"
        int auto_suspend "60 seconds"
        boolean auto_resume "true"
    }
    
    SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION {
        string integration_name PK
        string type "EXTERNAL_OAUTH"
        string oauth_type "AZURE"
        string user_mapping "upn to LOGIN_NAME"
    }
```

## Production Analytics Pattern (Optional)

For production use cases with semantic views:

```mermaid
erDiagram
    SEMANTIC_MODELS ||--o{ SV_SALES_CALL_ACTIVITY : contains
    SV_SALES_CALL_ACTIVITY ||--|| FACT_SALES_CALLS : "selects from"
    SALES_CALLS_ANALYST ||--|| SV_SALES_CALL_ACTIVITY : "queries via"
    
    SEMANTIC_MODELS {
        string schema_name PK "SEMANTIC_MODELS"
        string purpose "Cortex Analyst views"
    }
    
    SV_SALES_CALL_ACTIVITY {
        string view_name PK
        int customer_id FK
        int manufacturer_id FK
        date call_date
        decimal call_volume
        string plan_year
    }
    
    FACT_SALES_CALLS {
        string table_name PK
        string layer "Analytics"
        string source "ETL pipeline"
    }
    
    SALES_CALLS_ANALYST {
        string agent_name PK
        string tool_type "cortex_analyst_text_to_sql"
        string semantic_view FK
    }
```

## Component Descriptions

### Core Demo Objects

| Component | Purpose | Technology | Location |
|-----------|---------|------------|----------|
| SNOWFLAKE_EXAMPLE | Demo database namespace | Snowflake Database | Account-level |
| CORTEX_DEMO | Schema for agent objects | Snowflake Schema | `SNOWFLAKE_EXAMPLE.CORTEX_DEMO` |
| GENERATE_SAFE_JOKE | AI joke generation | SQL UDF + Cortex COMPLETE | `sql/01_setup/02_create_joke_function.sql` |
| JOKE_ASSISTANT | Cortex Agent for Teams | Cortex Agent | Created via UI/REST |
| SFE_CORTEX_AGENTS_WH | Compute for agent queries | Snowflake Warehouse | `sql/01_setup/01_create_demo_objects.sql` |
| SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION | OAuth with Microsoft | Security Integration | `sql/01_setup/04_create_security_integration.sql` |

### Production Pattern Objects (Optional)

| Component | Purpose | Technology | Location |
|-----------|---------|------------|----------|
| SEMANTIC_MODELS | Schema for semantic views | Snowflake Schema | Customer database |
| SV_SALES_CALL_ACTIVITY | Governed analytics view | Semantic View | Customer schema |
| SALES_CALLS_ANALYST | Production analytics agent | Cortex Agent | `sql/01_setup/03_create_cortex_agent.sql` (Option C) |

## Data Types Reference

| Object Type | Naming Convention | Example |
|-------------|-------------------|---------|
| Database | UPPER_SNAKE_CASE | `SNOWFLAKE_EXAMPLE` |
| Schema | UPPER_SNAKE_CASE | `CORTEX_DEMO` |
| Function | UPPER_SNAKE_CASE | `GENERATE_SAFE_JOKE` |
| Warehouse | SFE_ prefix + purpose | `SFE_CORTEX_AGENTS_WH` |
| Integration | SFE_ prefix + type | `SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION` |
| Semantic View | SV_ prefix + domain | `SV_SALES_CALL_ACTIVITY` |

## Change History

See `.cursor/DIAGRAM_CHANGELOG.md` for version history.

