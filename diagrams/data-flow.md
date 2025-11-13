# Data Flow - Snowflake Cortex Agents for Microsoft Teams
Author: Michael Whitaker 
Last Updated: 2025-11-13 
Status: Reference Impl
![Snowflake](https://img.shields.io/badge/Snowflake-29B5E8?style=for-the-badge&logo=snowflake&logoColor=white)
Reference Impl: This code demonstrates prod-grade architectural patterns and best practice. review and customize security, networking, logic for your organization's specific requirements before deployment.
## Overview
This diagram shows how Teams-authenticated prompts flow through Microsoft Entra ID, the shared SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION, and into Snowflake. The Cortex agent and SQL function orchestrate Cortex COMPLETE + Cortex Guard, then return curated jokes to Teams.
## Diagram
```mermaid
graph LR
    Teams[Microsoft Teams<br/>AppSource client]
    Entra[Microsoft Entra ID<br/>OAuth issuer]
    Integration[SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION<br/>External OAuth]
    Snowflake[Snowflake<br/>SNOWFLAKE_EXAMPLE]
    Agent[JOKE_ASSISTANT Cortex Agent]
    Function[GENERATE_SAFE_JOKE()<br/>SQL function]
    CortexAI[Cortex COMPLETE<br/>(mistral-large)]
    Guard[Cortex Guard]
    Warehouse[SFE_CORTEX_AGENTS_WH<br/>Warehouse]
    Schema[SNOWFLAKE_EXAMPLE.CORTEX_DEMO]

    Teams -->|OAuth + JWT| Entra
    Entra -->|Issues JWT + role claims| Integration
    Integration -->|Validates tenant & tokens| Snowflake
    Snowflake --> Agent
    Agent -->|Invokes| Function
    Function -->|Calls API| CortexAI
    CortexAI --> Guard
    Guard --> Agent
    Function -->|Runs on| Warehouse
    Snowflake -->|Houses objects in| Schema
    Agent -->|Replies| Teams
```
## Component Descriptions
- Microsoft Teams App: Hosted in Teams / AppSource, this UI lets users trigger jokes and handles the OAuth redirect flow (docs/05-INSTALL-TEAMS-APP.md).
- Microsoft Entra ID: Provides tenant consent, handles MFA, and issues JWT tokens that Snowflake consumes via the OAuth integration (docs/02-ENTRA-ID-SETUP.md + config/entra_id_setup_guide.md).
- SFE_ENTRA_ID_CORTEX_AGENTS_INTEGRATION: External OAuth object that maps JWT claims to Snowflake roles and authorizes the Cortex agent (sql/01_setup/04_create_security_integration.sql).
- JOKE_ASSISTANT Cortex Agent: Orchestrates prompts, invokes the `joke_generator` tool, and enforces response instructions (sql/01_setup/03_create_cortex_agent.sql).
- GENERATE_SAFE_JOKE() SQL Function: Wraps Cortex COMPLETE + Cortex Guard and runs inside SNOWFLAKE_EXAMPLE.CORTEX_DEMO (sql/01_setup/02_create_joke_function.sql).
- Cortex AI + Guard: Cortex COMPLETE (mistral-large) generates jokes while Cortex Guard filters unsafe content before the agent responds (sql/01_setup/02_create_joke_function.sql).
- SFE_CORTEX_AGENTS_WH Warehouse: Dedicated XSMALL warehouse that hosts the SQL function and the Cortex agent tool calls (sql/01_setup/01_create_demo_objects.sql).
- Cleanup Script: `sql/99_cleanup/teardown_all.sql` removes the schema/function/warehouse when the demo is reset while leaving shared assets intact.
## Change History
See `.cursor/DIAGRAM_CHANGELOG.md` for vhistory.
