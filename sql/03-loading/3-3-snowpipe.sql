-- This script demonstrates a Snowpipe-style workload using an INTERNAL stage.
-- It re-uses the CSV file format defined in the 3-1 example and shows how to:
--  1) create an internal stage
--  2) create a pipe that copies from that stage into the target table
--  3) PUT (upload) the local CSV into the stage
--  4) trigger the pipe with ALTER PIPE ... REFRESH to ingest files in the stage
--  5) verify the load
--
-- IMPORTANT: For automatic (event-driven) Snowpipe you need cloud messaging (SQS/SNS/GCS PubSub) and an external stage.
-- Using an INTERNAL stage is fine for examples and for manual/REST-triggered loads. REFRESH loads files already in the stage.

-- Environment setup
USE ROLE SYSADMIN;
USE WAREHOUSE SCS;
USE DATABASE SNOWFLAKE_CODE_SAMPLE;

-- CREATE SCHEMA
-- CREATE OR REPLACE SCHEMA SNOWFLAKE_CODE_SAMPLE.RAW COMMENT = 'Loading Schema' DATA_RETENTION_TIME_IN_DAYS = 2;
USE SCHEMA SNOWFLAKE_CODE_SAMPLE.RAW;

-- Create / reuse the CSV file format used in 3-1
CREATE OR REPLACE FILE FORMAT SNOWFLAKE_CODE_SAMPLE.RAW.GENERIC_CSV
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    TRIM_SPACE = TRUE
    COMPRESSION = 'NONE';

-- Internal stage (directory-style)
CREATE OR REPLACE STAGE SNOWFLAKE_CODE_SAMPLE.RAW.FILES_STAGE_PIPE DIRECTORY = ( ENABLE = TRUE );

-- Target table (same structure as 3-1)
CREATE OR REPLACE TABLE SNOWFLAKE_CODE_SAMPLE.RAW.ACCOUNTS_RAW (
    ACCESSIBLE_BALANCE                         VARCHAR,
    ACCOUNT_BALANCE                            VARCHAR,
    ACCOUNT_STATUS_CODE                        VARCHAR,
    ACCOUNT_UID                                VARCHAR,
    CDIC_HOLD_STATUS_CODE                      VARCHAR,
    CURRENCY_CODE                              VARCHAR,
    CURRENT_CDIC_HOLD_AMOUNT                   VARCHAR,
    DEPOSITOR_ID                               VARCHAR,
    INSURANCE_DETERMINATION_CATEGORY_TYPE_CODE VARCHAR,
    PRODUCT_CODE                               VARCHAR,
    REGISTERED_ACCOUNT_FLAG                    VARCHAR,
    REGISTERED_PLAN_TYPE_CODE                  VARCHAR,
    FILE_NAME                                  VARCHAR,
    FILE_ROW_NUMBER                            VARCHAR
);

-- Create a pipe that copies CSV files from the internal stage into the table.
-- This pipe can be triggered manually with ALTER PIPE ... REFRESH or via the Snowpipe REST API. External Stage use AUTO_INGEST = TRUE
CREATE OR REPLACE PIPE SNOWFLAKE_CODE_SAMPLE.RAW.ACCOUNTS_PIPE AS
COPY INTO SNOWFLAKE_CODE_SAMPLE.RAW.ACCOUNTS_RAW
FROM @SNOWFLAKE_CODE_SAMPLE.RAW.FILES_STAGE_PIPE
FILE_FORMAT = (FORMAT_NAME = SNOWFLAKE_CODE_SAMPLE.RAW.GENERIC_CSV)
ON_ERROR = 'CONTINUE'
PATTERN = '.*\\.csv';

-- === Upload the CSV file to the internal stage ===
-- Adjust the local path below to your machine (the example path used in 3-1):
-- file:///Users/eplata/Developer/snowflake-code-sample/sql/03-loading/data_0_0_0.csv
PUT file:///Users/eplata/Developer/snowflake-code-sample/sql/03-loading/data_0_0_0.csv @SNOWFLAKE_CODE_SAMPLE.RAW.FILES_STAGE_PIPE/ AUTO_COMPRESS=FALSE;

-- List files in the stage to confirm upload
LS @SNOWFLAKE_CODE_SAMPLE.RAW.FILES_STAGE_PIPE;

-- === Trigger the pipe to load files currently in the stage ===
-- This will instruct the pipe to load any files in the stage that haven't been ingested yet.
ALTER PIPE SNOWFLAKE_CODE_SAMPLE.RAW.ACCOUNTS_PIPE REFRESH;

-- Optionally, to refresh only specific files:
-- ALTER PIPE SNOWFLAKE_CODE_SAMPLE.RAW.ACCOUNTS_PIPE REFRESH (FILES => ('data_0_0_0.csv'));

-- Wait a few seconds, then verify the load
SELECT COUNT(*) AS loaded_rows FROM SNOWFLAKE_CODE_SAMPLE.RAW.ACCOUNTS_RAW;
SELECT * FROM SNOWFLAKE_CODE_SAMPLE.RAW.ACCOUNTS_RAW LIMIT 20;

-- Cleanup (uncomment to remove objects when you're done)
-- DROP PIPE IF EXISTS SNOWFLAKE_CODE_SAMPLE.RAW.ACCOUNTS_PIPE;
-- DROP STAGE IF EXISTS SNOWFLAKE_CODE_SAMPLE.RAW.FILES_STAGE_PIPE;
-- DROP TABLE IF EXISTS SNOWFLAKE_CODE_SAMPLE.RAW.ACCOUNTS_RAW;
-- DROP FILE FORMAT IF EXISTS SNOWFLAKE_CODE_SAMPLE.RAW.GENERIC_CSV;
-- DROP SCHEMA IF EXISTS SNOWFLAKE_CODE_SAMPLE.RAW;
