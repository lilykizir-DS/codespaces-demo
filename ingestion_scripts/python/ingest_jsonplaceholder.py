import snowflake.snowpark as snowpark
import requests
import json
from snowflake.snowpark.functions import lit, current_timestamp

def main(session: snowpark.Session):
    # The base URL we allowed in our Network Rule
    base_url = "https://jsonplaceholder.typicode.com"
    
    # We will fetch from these two endpoints
    endpoints = {
        "users": "/users",
        "posts": "/posts"
    }
    
    results = []

    for name, path in endpoints.items():
        url = f"{base_url}{path}"
        
        # 1. Fetch the data using standard Python requests
        response = requests.get(url)
        
        if response.status_code == 200:
            data = response.json()
            
            # 2. Convert the list of Python dicts into a Snowpark DataFrame
            # We wrap the data in a single-column list so Snowpark treats each dict as a row
            df = session.create_dataframe([[row] for row in data], schema=["RAW_PAYLOAD"])
            
            # 3. Add the ingestion timestamp column
            df_with_timestamp = df.withColumn("INGESTED_AT", current_timestamp())
            
            # 4. Save to the corresponding Bronze table
            table_name = f"RAW_{name.upper()}"
            
            # Write the data, appending to existing rows
            df_with_timestamp.write.mode("append").save_as_table(table_name)
            
            results.append(f"Successfully loaded {len(data)} records into {table_name}")
            
        else:
            results.append(f"Failed to fetch {name}: HTTP {response.status_code}")
            
    # Return a summary string to the caller
    return "\n".join(results)