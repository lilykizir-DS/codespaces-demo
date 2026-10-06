-- Set context
USE ROLE WORKSHOP_INGESTION_ROLE;
USE WAREHOUSE WORKSHOP_WH;
USE DATABASE WORKSHOP_DB;
USE SCHEMA RAW;

-- Register the Python code as a Snowflake Stored Procedure
CREATE OR REPLACE PROCEDURE fetch_placeholder_data()
  RETURNS STRING
  LANGUAGE PYTHON
  RUNTIME_VERSION = '3.10'
  PACKAGES = ('snowflake-snowpark-python', 'requests')
  EXTERNAL_ACCESS_INTEGRATIONS = (jsonplaceholder_integration)
  HANDLER = 'main'
AS
$$
import snowflake.snowpark as snowpark
import requests
import json
from snowflake.snowpark.functions import lit, current_timestamp

def main(session: snowpark.Session):
    base_url = "https://jsonplaceholder.typicode.com"
    endpoints = {"users": "/users", "posts": "/posts"}
    results = []

    for name, path in endpoints.items():
        url = f"{base_url}{path}"
        response = requests.get(url)
        
        if response.status_code == 200:
            data = response.json()
            df = session.create_dataframe([[row] for row in data], schema=["RAW_PAYLOAD"])
            df_with_timestamp = df.withColumn("INGESTED_AT", current_timestamp())
            table_name = f"RAW_{name.upper()}"
            df_with_timestamp.write.mode("append").save_as_table(table_name)
            results.append(f"Loaded {len(data)} into {table_name}")
        else:
            results.append(f"Failed {name}: HTTP {response.status_code}")
            
    return "\n".join(results)
$$;