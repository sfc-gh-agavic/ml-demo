/*-----------------------------------------------------------------------------																																				
																																				
HOL Setup																																				
																																				
Initial Creator : Mike Harding																																				
Modified By: Aaron Gavic																																				
																																				
-----------------------------------------------------------------------------*/																																				
																																				
																																				
																																				
-- RUN THIS ONE-TIME-SETUP AS ACCOUNTADMIN IN THE MAIN HOL ACCOUNT to create multiple users																																				
-- create the setup_wh & utility DB																																				
USE ROLE ACCOUNTADMIN;
create or replace warehouse setup_wh with warehouse_size = 'xsmall' auto_suspend = 300;																																				
grant ownership on warehouse setup_wh to role securityadmin;																																				
grant usage on warehouse setup_wh to role securityadmin;																																				
create or replace database utility;																																				

-- create a SP to loop queries for N users																																				
-- it replaces the placeholder XXX with N in the supplied query																																				
create or replace procedure utility.public.loopquery (QRY STRING, N FLOAT)																																				
returns float																																				
language javascript																																				
strict																																				
as																																				
$$																																				
for (i = 0; i <= N; i++) {																																				
snowflake.execute({sqlText: QRY.replace(/XXX/g, i)});																																				
}																																				
																																				
return i-1;																																				
$$;																																				
																																				
grant usage on procedure utility.public.loopquery (string, float) to role securityadmin;																																				
grant usage on database utility to role securityadmin;																																				
grant usage on schema utility.public to role securityadmin;																																				

-- Network Rule — allow egress to PyPI
CREATE OR REPLACE NETWORK RULE utility.public.pypi_network_rule
  MODE        = EGRESS
  TYPE        = HOST_PORT
VALUE_LIST = ('pypi.org', 'pypi.python.org', 'pythonhosted.org', 'files.pythonhosted.org');

-- External Access Integration — expose PyPI to notebooks / SPCS services
CREATE OR REPLACE EXTERNAL ACCESS INTEGRATION pypi_access_integration
  ALLOWED_NETWORK_RULES = (pypi_network_rule)
  ENABLED               = TRUE;

-- Network Rule — allow egress to GitHub (for git integration)
CREATE OR REPLACE NETWORK RULE github_network_rule
  MODE        = EGRESS
  TYPE        = HOST_PORT
  VALUE_LIST  = ('github.com');

-- API Integration — allow Snowflake to access the HOL GitHub repo
CREATE OR REPLACE API INTEGRATION github_api_integration
  API_PROVIDER         = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/')
  ALLOWED_AUTHENTICATION_SECRETS = ()
  ENABLED              = TRUE;


-- Compute Pools

-- XS CPU — light EDA, prototyping, small dataframes, quick scripts
CREATE COMPUTE POOL IF NOT EXISTS ML_TEAM_CPU_XS
  MIN_NODES        = 1
  MAX_NODES        = 20
  INSTANCE_FAMILY  = CPU_X64_XS
  AUTO_RESUME      = TRUE
  AUTO_SUSPEND_SECS = 300;

-- S CPU — feature engineering, moderate-size dataframes, light training
CREATE COMPUTE POOL IF NOT EXISTS ML_TEAM_CPU_S
  MIN_NODES        = 1
  MAX_NODES        = 20
  INSTANCE_FAMILY  = CPU_X64_S
  AUTO_RESUME      = TRUE
  AUTO_SUSPEND_SECS = 300;

-- High-Memory M CPU — wide tables, large in-memory transforms, HPO
CREATE COMPUTE POOL IF NOT EXISTS ML_TEAM_CPU_HIGHMEM_M
  MIN_NODES        = 1
  MAX_NODES        = 20
  INSTANCE_FAMILY  = HIGHMEM_X64_M
  AUTO_RESUME      = TRUE
  AUTO_SUSPEND_SECS = 300;

-- GPU (A100-class) — DL training, fine-tuning, GPU-heavy inference
CREATE COMPUTE POOL IF NOT EXISTS ML_TEAM_GPU_A100
  MIN_NODES        = 1
  MAX_NODES        = 20
  INSTANCE_FAMILY  = GPU_NV_M
  AUTO_RESUME      = TRUE
  AUTO_SUSPEND_SECS = 300;




----------------------------------------------------------------------------------																																				
-- Set up the HOL environment for the first time																																				
----------------------------------------------------------------------------------																																				
set num_users = 20; --> adjust number of attendees here																																				
set lab_pwd = 'Welcome123'; --> enter an attendee password here																																				
																																				
-- Cleanup																																				
call utility.public.loopquery('drop database if exists HOL;', $num_users);																																				
call utility.public.loopquery('drop user if exists userXXX;', $num_users);																																				
call utility.public.loopquery('drop role if exists roleXXX;', $num_users);																																				
call utility.public.loopquery('drop warehouse if exists WHXXX;', $num_users);																																				
																																				
-- set up the roles																																				
use role securityadmin;																																				
create or replace role hol_parent comment = "HOL parent role";																																				
grant role hol_parent to role accountadmin;																																				
call utility.public.loopquery('create or replace role roleXXX comment = "HOL User RoleXXX";', $num_users);																																				
																																			
-- Create role Cortex																																				
use role securityadmin;																																				
CREATE or replace ROLE cortex_user_role;																																				
use role accountadmin;																																				
GRANT DATABASE ROLE SNOWFLAKE.CORTEX_USER TO ROLE cortex_user_role;																																				
call utility.public.loopquery('GRANT ROLE cortex_user_role TO ROLE roleXXX', $num_users);																																				
																																	
-- set up the users																																				
call utility.public.loopquery('create or replace user userXXX default_role=roleXXX password="' || $lab_pwd || '";', $num_users);																																				
call utility.public.loopquery('grant role roleXXX to user userXXX;', $num_users);																																				
call utility.public.loopquery('grant role roleXXX to role hol_parent;', $num_users);																																				
call utility.public.loopquery('grant role roleXXX to role accountadmin;', $num_users);																																				
																																				
-- grant account permissions																																				
use role accountadmin;																																				
grant create warehouse on account to role hol_parent;																																				
grant usage on warehouse setup_wh to role hol_parent;																																				
																																				
-- set up the warehouses and grant permissions																																				
call utility.public.loopquery('create or replace warehouse whXXX warehouse_size = \'xsmall\' AUTO_SUSPEND = 60;', $num_users);																																				
call utility.public.loopquery('grant all on warehouse whXXX to role roleXXX;', $num_users);																																				
call utility.public.loopquery('GRANT usage ON warehouse whXXX TO ROLE roleXXX', $num_users);																																				
call utility.public.loopquery('alter user userXXX set default_warehouse = whXXX;', $num_users);																																				

use role accountadmin;																																				
create or replace database ML_HOL_DB;																																				
																																				
-- set up the schemas and grant permissions																																				
call utility.public.loopquery('create or replace schema ML_HOL_DB.ML_SCHEMAXXX;', $num_users);																																				
call utility.public.loopquery('grant usage, modify on database ML_HOL_DB to role roleXXX;', $num_users);																																				
call utility.public.loopquery('grant usage on schema ML_HOL_DB.PUBLIC to role roleXXX;', $num_users);																																				
call utility.public.loopquery('grant ownership on schema ML_HOL_DB.ML_SCHEMAXXX to role roleXXX;', $num_users);																																				
call utility.public.loopquery('grant usage, modify on future schemas in database ML_HOL_DB to role roleXXX;', $num_users);																																				
call utility.public.loopquery('grant all on all tables in schema ML_HOL_DB.ML_SCHEMAXXX to role roleXXX;', $num_users);																																				
call utility.public.loopquery('grant all on future tables in schema ML_HOL_DB.ML_SCHEMAXXX to role roleXXX;', $num_users);																																				
call utility.public.loopquery('grant all on all views in schema ML_HOL_DB.ML_SCHEMAXXX to role roleXXX;', $num_users);																																				
call utility.public.loopquery('grant all on future views in schema ML_HOL_DB.ML_SCHEMAXXX to role roleXXX;', $num_users);																																				
call utility.public.loopquery('GRANT usage ON schema ML_HOL_DB.ML_SCHEMAXXX TO ROLE roleXXX', $num_users);																																				
call utility.public.loopquery('GRANT create stage ON schema ML_HOL_DB.ML_SCHEMAXXX TO ROLE roleXXX', $num_users);																																																																																																											
																																				
																																				
-- if using Snowflake Notebooks, ensure you run the following:																																				
call utility.public.loopquery('GRANT create notebook ON schema ML_HOL_DB.ML_SCHEMAXXX TO ROLE roleXXX', $num_users);																																				
call utility.public.loopquery('grant create notebook ON schema ML_HOL_DB.ML_SCHEMAXXX TO ROLE accountadmin', $num_users);																																																																							
call utility.public.loopquery('GRANT VIEW LINEAGE ON ACCOUNT TO ROLE roleXXX', $num_users);																																				
call utility.public.loopquery('GRANT CREATE STREAMLIT ON SCHEMA ML_HOL_DB.ML_SCHEMAXXX TO ROLE roleXXX', $num_users);																																				

-- Compute pool access
call utility.public.loopquery('GRANT USAGE ON COMPUTE POOL ML_TEAM_CPU_XS TO ROLE roleXXX', $num_users);
call utility.public.loopquery('GRANT USAGE ON COMPUTE POOL ML_TEAM_CPU_S TO ROLE roleXXX', $num_users);
call utility.public.loopquery('GRANT USAGE ON COMPUTE POOL ML_TEAM_CPU_HIGHMEM_M TO ROLE roleXXX', $num_users);
call utility.public.loopquery('GRANT USAGE ON COMPUTE POOL ML_TEAM_GPU_A100 TO ROLE roleXXX', $num_users);

-- PyPI external access
call utility.public.loopquery('GRANT USAGE ON INTEGRATION pypi_access_integration TO ROLE roleXXX', $num_users);

-- GitHub API integration access
call utility.public.loopquery('GRANT USAGE ON INTEGRATION github_api_integration TO ROLE roleXXX', $num_users);																																
																																				
USE ROLE ACCOUNTADMIN;																																				
																																				
-- stage for files																																				
call utility.public.loopquery('CREATE STAGE ML_HOL_DB.ML_SCHEMAXXX.ML_STAGE DIRECTORY = (ENABLE = TRUE)', $num_users);																																				
call utility.public.loopquery('grant all on stage ML_HOL_DB.ML_SCHEMAXXX.ML_STAGE to role roleXXX;', $num_users);																																				



																															
-- create csv format																																				
CREATE FILE FORMAT IF NOT EXISTS ML_HOL_DB.PUBLIC.CSVFORMAT																																				
SKIP_HEADER = 1																																				
TYPE = 'CSV';																																				
																																				
-- create external stage with the csv format to stage the diamonds dataset																																				
CREATE STAGE IF NOT EXISTS ML_HOL_DB.PUBLIC.DIAMONDS_ASSETS																																				
FILE_FORMAT = ML_HOL_DB.PUBLIC.CSVFORMAT																																				
URL = 's3://sfquickstarts/intro-to-machine-learning-with-snowpark-ml-for-python/diamonds.csv';																																				
call utility.public.loopquery('grant usage on stage ML_HOL_DB.PUBLIC.DIAMONDS_ASSETS to role roleXXX;', $num_users);																																				
																																				
call utility.public.loopquery('grant all on FILE FORMAT ML_HOL_DB.PUBLIC.CSVFORMAT to role roleXXX;', $num_users);																																				
																																				
show users;																																				
show roles;																																				
show warehouses;																																				
																																				
USE ROLE ROLE1;																																				
LS @ML_HOL_DB.PUBLIC.DIAMONDS_ASSETS;																																				
																																				
select $1, $2, $3 from @ML_HOL_DB.PUBLIC.DIAMONDS_ASSETS limit 10;																																				