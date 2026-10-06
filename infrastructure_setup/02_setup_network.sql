-- Set context (Requires AccountAdmin to create Network Rules and Integrations)
USE ROLE ACCOUNTADMIN;
USE DATABASE WORKSHOP_DB;
USE SCHEMA RAW;

-- 1. Create the Network Rule
-- This defines exactly which outbound destinations are allowed
CREATE OR REPLACE NETWORK RULE jsonplaceholder_api_network_rule
  MODE = EGRESS
  TYPE = HOST_PORT
  VALUE_LIST = ('jsonplaceholder.typicode.com');

-- 2. Create the External Access Integration
-- This binds the rule to a named integration that the Stored Procedure will use
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION jsonplaceholder_api_access_integration
  ALLOWED_NETWORK_RULES = (jsonplaceholder_api_network_rule)
  ENABLED = TRUE;

-- 3. Grant usage of this integration to the pipeline role
GRANT USAGE ON INTEGRATION jsonplaceholder_api_access_integration TO ROLE WORKSHOP_INGESTION_ROLE;