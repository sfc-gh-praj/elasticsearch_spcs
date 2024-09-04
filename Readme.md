# Running Elasticsearch in Snowpark Container Services

This README provides instructions on how to run Elasticsearch and Kibana in Snowpark Container Services.

## Notes

- This setup is configured for a single-node Elasticsearch cluster in SPCS.
- Security features are disabled for simplicity; enable them for production use.
- Adjust the storage size in the YAML file if you need more than 10GB.

For more information on Snowpark Container Services, refer to the official Snowflake documentation.


## Prerequisites

- Docker installed on your local machine (for building the custom image)
- Snowflake non-trail account


## Steps to Deploy

Download and unzip the file and you will see two subfolders(elasticsearch and kibana) along with Makefile and Readme.md file.

### 1. Setup

``` sql
USE ROLE ACCOUNTADMIN;

CREATE ROLE SPCS_PSE_ROLE;

CREATE DATABASE IF NOT EXISTS ESDemo;
GRANT OWNERSHIP ON DATABASE ESDemo TO ROLE SPCS_PSE_ROLE COPY CURRENT GRANTS;
GRANT OWNERSHIP ON ALL SCHEMAS IN DATABASE ESDemo  TO ROLE SPCS_PSE_ROLE COPY CURRENT GRANTS;

CREATE OR REPLACE WAREHOUSE small_warehouse WITH
  WAREHOUSE_SIZE='X-SMALL';

GRANT USAGE ON WAREHOUSE small_warehouse TO ROLE SPCS_PSE_ROLE;

CREATE SECURITY INTEGRATION IF NOT EXISTS snowservices_ingress_oauth
  TYPE=oauth
  OAUTH_CLIENT=snowservices_ingress
  ENABLED=true;

GRANT BIND SERVICE ENDPOINT ON ACCOUNT TO ROLE SPCS_PSE_ROLE;

-- Creating medium CPU compute pool
CREATE COMPUTE POOL PR_CPU_M
  MIN_NODES = 1
  MAX_NODES = 1
  INSTANCE_FAMILY = CPU_X64_M
  AUTO_RESUME = FALSE
  INITIALLY_SUSPENDED = FALSE
  COMMENT = 'For Elastics Search' ;

-- Below network rule and External Access INtegration is used to download sample data in Kabana.

 CREATE NETWORK RULE allow_all_rule
    TYPE = 'HOST_PORT'
    MODE= 'EGRESS'
    VALUE_LIST = ('0.0.0.0:443','0.0.0.0:80');

CREATE EXTERNAL ACCESS INTEGRATION allow_all_eai
  ALLOWED_NETWORK_RULES = (allow_all_rule)
  ENABLED = true

GRANT USAGE ON INTEGRATION allow_all_eai TO ROLE SPCS_PSE_ROLE;

GRANT USAGE, MONITOR ON COMPUTE POOL PR_CPU_M TO ROLE SPCS_PSE_ROLE;

-- Change the username
GRANT ROLE SPCS_PSE_ROLE TO USER <user_name>;

USE ROLE SPCS_PSE_ROLE;
USE DATABASE ESDemo;
USE WAREHOUSE small_warehouse;
USE SCHEMA PUBLIC;

CREATE IMAGE REPOSITORY IF NOT EXISTS IMAGES;

CREATE STAGE SPECS ENCRYPTION = (TYPE = 'SNOWFLAKE_SSE') ;

-- CHECK THE IMAGE RESGITRY URL

SHOW IMAGE REPOSITORIES;

Example output for the above query (image repository):
 <orgname>-<acctname>.registry.snowflakecomputing.com/ESDemo/public/images

```

### 2. Build and Push the Elastic Search and Kibana Docker Image to SPCS

Edit the Makefile and update the value for SNOWFLAKE_REPO? and IMAGE_REGISTRY. This should be your image repository URL. After making the required changes, run the following command from your terminal:

``` bash
make all
```

> Note: Above command will build the two images and pushes it to the SPCS image repositories.

### 3. Upload the following 

Edit the below two yaml files and update the image value( should be your image repository that you have created) and upload it to `specs` internal stage.

- elasticsearch/docker-compose.yml 
- kibana/kibana.yaml

### 4. Creating Services for Elastic Search and Kibana

Run the following commands to create Snowpark Container services for Elastic Search and Kibana

```sql
USE ROLE SPCS_PSE_ROLE;

-- Elastic Search Service
CREATE SERVICE elasticsearcg_svc
  IN COMPUTE POOL PR_CPU_M
  FROM @specs
  SPEC='elasticsearch-snowpark.yaml'
  MIN_INSTANCES=1
  MAX_INSTANCES=1;

-- Checking status of the service. Move ahead when the status is READY
SELECT SYSTEM$GET_SERVICE_STATUS('elasticsearcg_svc',1); 

-- Checking the logs of the ES container
SELECT value AS log_line
FROM TABLE(
 SPLIT_TO_TABLE(SYSTEM$GET_SERVICE_LOGS('elasticsearcg_svc', 0, 'elasticsearch'), '\n')
  );


-- Kibana Service

CREATE SERVICE kibana_svc
  IN COMPUTE POOL PR_CPU_M
  FROM @specs
  SPEC='kibana.yaml'
  EXTERNAL_ACCESS_INTEGRATIONS = (ALLOW_ALL_EAI)
  MIN_INSTANCES=1
  MAX_INSTANCES=1;

-- Checking status of the service. Move ahead when the status is READY

SELECT SYSTEM$GET_SERVICE_STATUS('kibana_svc',1); 

-- Checking the logs of the kibana container

SELECT value AS log_line
FROM TABLE(
 SPLIT_TO_TABLE(SYSTEM$GET_SERVICE_LOGS('kibana_svc', 0, 'kibana-container'), '\n')
  );
```

### 5. Access Elasticsearch

Once deployed, you can access Elasticsearch using the public endpoints. Run the following query in snowsight to get the endpoint URL.  Below query should give you endpoints in the ingress_url column.  Get the value for http.
```sql
show endpoints in service elasticsearcg_svc;
```
![endpoints](/endpoints.png)

When you access the endpoint after logging in, below is the type of the content you will see which implies ES is running fine.

```json
{
  "name" : "statefulset-0",
  "cluster_name" : "es_cluster",
  "cluster_uuid" : "oXGP1hTAQBqV8cSP1uZc5w",
  "version" : {
    "number" : "8.14.2",
    "build_flavor" : "default",
    "build_type" : "docker",
    "build_hash" : "2afe7caceec8a26ff53817e5ed88235e90592a1b",
    "build_date" : "2024-07-01T22:06:58.515911606Z",
    "build_snapshot" : false,
    "lucene_version" : "9.10.0",
    "minimum_wire_compatibility_version" : "7.17.0",
    "minimum_index_compatibility_version" : "7.0.0"
  },
  "tagline" : "You Know, for Search"
}
```

### 6. Launching Kibana

Run the following query in snowsight to get the endpoint URL of kibana.  Below query should give you endpoints in the ingress_url column.  Get the value for http.
```sql
show endpoints in service kibana_svc;
```

When you launch the endpoint after logging in you will be asked to `Configure Elastic` or enter the enrollment token. This is asked as we are not using any credentials for the Elastic Search. 

Here you can clik on `Configure manually` and enter `http://elasticsearcg-svc:9200`. After you provide the elastic search url it will prompt to enter the `Verification-code ` which you can find from the Kibana container logs.

```sql
SELECT value AS log_line
FROM TABLE(
 SPLIT_TO_TABLE(SYSTEM$GET_SERVICE_LOGS('kibana_svc', 0, 'kibana-container'), '\n')
  );
  ```

In the logs you will see a line at the end for the `verification code` and use that code and click on verify which will launch home page:

`Your verification code is:  124 602 `


By now you are all set to use Kibana and you can use sample data to load data into Elastic Search use dev tool to view the data from the same console.

### 7. Cleanup

```sql

drop service kibana_svc;

drop service elasticsearcg_svc FORCE; 

drop compute pool PR_CPU_M;

```