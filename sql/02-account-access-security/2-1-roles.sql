USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_CODE_SAMPLE;
USE SCHEMA PUBLIC;
USE WAREHOUSE SCS;

-- 0.- Remove secondary roles from the owner user
ALTER USER <YOUR_USER> SET DEFAULT_SECONDARY_ROLES = ();
--ALTER USER <YOUR_USER> SET DEFAULT_SECONDARY_ROLES = ('ALL'); -- This will restore previous behavior

-- 1.- Creating a custom role analyst AND see the hierarchy in the UI
USE ROLE SECURITYADMIN;
CREATE OR REPLACE ROLE ANALYST
 COMMENT  = 'ANALYST';

-- CREATE USER
-- USE ROLE USERADMIN;
-- CREATE OR REPLACE USER TESTUSERRBAC
--  LOGIN_NAME = 'TESTUSERRBAC'
--  PASSWORD = 'TESTUSERRBAC@1_23'
--  MUST_CHANGE_PASSWORD = FALSE
--  DEFAULT_SECONDARY_ROLES = ()
--  TYPE = LEGACY_SERVICE;

-- 2.- Take a look ta the user interface to visualize the role AND open a new private window browser and login using the TESTUSER credentials.

-- 3.- Granting role analyst to role sysadmin
USE ROLE SECURITYADMIN;
GRANT ROLE ANALYST TO ROLE SYSADMIN;
-- GRANT ROLE ANALYST TO USER TESTUSERRBAC;
GRANT ROLE ANALYST TO USER <YOUR_USER>; -- Change this and use your user SELECT CURRENT_USER();

-- 4.- Assume the new role IN THE new Private Window browser you will see that it fails
USE ROLE ANALYST;
SELECT * FROM SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER; -- This will fail since we do not have access to the table

-- 5.- Granting access to the table (Run this on the browser where you are logined as ACCOUNTADMIN)
USE ROLE SECURITYADMIN;
GRANT SELECT ON TABLE SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER TO ROLE ANALYST;

-- RUN THIS ON THE PRIVATE WINDOW
SELECT * FROM SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER; -- This will fail again WHY?

-- 5.- Granting access to parent containers - (Run this on the browser where you are logined as ACCOUNTADMIN)
USE ROLE SECURITYADMIN;
GRANT USAGE ON DATABASE SNOWFLAKE_CODE_SAMPLE TO ROLE ANALYST;
GRANT USAGE ON SCHEMA SNOWFLAKE_CODE_SAMPLE.PUBLIC TO ROLE ANALYST;

-- 6.- Selecting table - RUN THIS ON THE PRIVATE WINDOW
USE ROLE ANALYST;
SELECT * FROM SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER LIMIT 10; -- This will fail gain WHY?

-- 7.- Granting access to warehouse - (Run this on the browser where you are logined as ACCOUNTADMIN)
USE ROLE SECURITYADMIN;
GRANT USAGE ON WAREHOUSE SCS TO ROLE ANALYST;

-- 8.- Selecting table - RUN THIS ON THE PRIVATE WINDOW
USE ROLE ANALYST;
USE WAREHOUSE SCS;
SELECT * FROM SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER LIMIT 10;

-- 9.- Creating a table - RUN THIS ON THE PRIVATE WINDOW
USE ROLE ANALYST;
SELECT C_MKTSEGMENT, COUNT(*) AS COUNT_OF_MKTSEGMENT FROM SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER GROUP BY ALL; -- This will succeed

CREATE OR REPLACE TABLE SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER_SUMMARY AS SELECT C_MKTSEGMENT, COUNT(*) AS COUNT_OF_MKTSEGMENT FROM SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER GROUP BY ALL; -- This will fail

-- 10.- Granting creation of table - (Run this on the browser where you are logined as ACCOUNTADMIN)
USE ROLE SECURITYADMIN;
GRANT CREATE TABLE ON SCHEMA SNOWFLAKE_CODE_SAMPLE.PUBLIC TO ROLE ANALYST;

-- 11.- RUN THIS ON THE PRIVATE WINDOW
USE ROLE ANALYST; 
USE WAREHOUSE SCS;
CREATE OR REPLACE TABLE SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER_SUMMARY AS SELECT C_MKTSEGMENT, COUNT(*) AS COUNT_OF_MKTSEGMENT FROM SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER GROUP BY ALL;
SELECT * FROM SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER_SUMMARY; -- After creating look at who's the owner of the user.

-- 12.- Showing grants: Exam question, what is the difference between the following - (Run this on the browser where you are logined as ACCOUNTADMIN)
SHOW GRANTS OF ROLE ANALYST; -- This show to whom the role has been granted and to which users as been assigned to.
SHOW GRANTS TO ROLE ANALYST; -- Take a look at the different privileges

-- 12.- Since we have a hierarchy in place (the ANALYST role falls under the SYSADMIN), we can do the following - (Run this on the browser where you are logined as ACCOUNTADMIN)
USE ROLE SYSADMIN;
DROP TABLE IF EXISTS SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER_SUMMARY;

-- 13.- Lets break the hierarchy and explore the DAC (Discretionary Access Control) - (Run this on the browser where you are logined as ACCOUNTADMIN)
USE ROLE SECURITYADMIN;
REVOKE ROLE ANALYST FROM ROLE SYSADMIN;
SHOW GRANTS TO ROLE ANALYST;

-- 14.- Creating a table - RUN THIS ON THE PRIVATE WINDOW
USE ROLE ANALYST;
USE WAREHOUSE SCS;
CREATE OR REPLACE TABLE SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER_SUMMARY AS SELECT C_MKTSEGMENT, COUNT(*) AS COUNT_OF_MKTSEGMENT FROM SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER GROUP BY ALL;
SELECT * FROM SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER_SUMMARY;

-- 14.- IS SYSADMIN ABLE TO SEE THE TABLE? - (Run this on the browser where you are logined as ACCOUNTADMIN)
USE ROLE SYSADMIN;
USE WAREHOUSE SCS;
SELECT * FROM SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER_SUMMARY; -- This will fail because of the DAC (Discretionary Access Control) since the ANALYST Role owns the table an there is no hierarchy in place
SHOW TABLES IN SCHEMA SNOWFLAKE_CODE_SAMPLE.PUBLIC; -- Where is the table?

-- 15.- Granting access back to SYSADMIN - (RUN THIS ON THE PRIVATE WINDOW)
USE ROLE ANALYST;
GRANT SELECT ON TABLE SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER_SUMMARY TO ROLE SYSADMIN; -- Notice Analyst has the ability to grant access to the table, do we want this behavior?

-- 15.- Verifying access (Run this on the browser where you are logined as ACCOUNTADMIN)
USE ROLE SYSADMIN;
USE WAREHOUSE SCS;
SELECT * FROM SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER_SUMMARY;
SHOW TABLES IN SCHEMA SNOWFLAKE_CODE_SAMPLE.PUBLIC; -- SYSADMIN can see it not that ANALYST granted the access but ANALYST has full control over the object.

-- 15.- Revoking access to SYSADMIN - (RUN THIS ON THE PRIVATE WINDOW)
USE ROLE ANALYST;
REVOKE SELECT ON TABLE SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER_SUMMARY FROM ROLE SYSADMIN;

-- 16.- Verifying access (Run this on the browser where you are logined as ACCOUNTADMIN)
USE ROLE SYSADMIN;
USE WAREHOUSE SCS;
SHOW TABLES IN SCHEMA SNOWFLAKE_CODE_SAMPLE.PUBLIC;

-- 14.- Managed Schemas: In a managed access schema, object owners lose the ability to make grant decisions. Only the schema owner - (Run this on the browser where you are logined as ACCOUNTADMIN)
USE ROLE ACCOUNTADMIN;
ALTER SCHEMA SNOWFLAKE_CODE_SAMPLE.PUBLIC ENABLE MANAGED ACCESS;
SHOW SCHEMAS IN DATABASE SNOWFLAKE_CODE_SAMPLE;

USE ROLE SYSADMIN;
USE DATABASE SNOWFLAKE_CODE_SAMPLE;
SHOW TABLES IN SCHEMA PUBLIC; -- We should be able to see the table the Analyst created AND revoked access to from us now that this schema is managed.
SELECT * FROM SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER_SUMMARY; -- This will fail, since RBAC is in place but SYSADMIN owns the Schema that why we can at least see the table.
DROP TABLE IF EXISTS SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER_SUMMARY; -- This will also fail since we do not have access to the table

-- 16.- Trying to grant access back to SYSADMIN - (RUN THIS ON THE PRIVATE WINDOW)
USE ROLE ANALYST;
GRANT SELECT ON TABLE SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER_SUMMARY TO ROLE SYSADMIN; -- Notice Analyst LOST the ability to grant access to the table

-- How do we fix this?. Either SECURITYADMIN moves the owership of the table to SYSADMIN or we can reestablish the hierarchy.

-- 15.- Option 1: SECURITYADMIN moves the ownership of the table to SYSADMIN
USE ROLE SECURITYADMIN;
GRANT OWNERSHIP ON ALL TABLES IN SCHEMA SNOWFLAKE_CODE_SAMPLE.PUBLIC TO ROLE SYSADMIN COPY CURRENT GRANTS; -- This will guarantee that all current tables will be owned by SYSADMIN and the grants will be presserved.
--GRANT OWNERSHIP ON FUTURE TABLES IN SCHEMA SNOWFLAKE_CODE_SAMPLE.PUBLIC TO ROLE SYSADMIN; -- This will guarantee that all future tables will be owned by SYSADMIN, but the default behavior of managed schemas is to default this to the owner of the schema.

-- 17.- Verifying access (Run this on the browser where you are logined as ACCOUNTADMIN)
USE ROLE SYSADMIN; 
USE WAREHOUSE SCS;
SELECT * FROM SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER_SUMMARY;
SHOW TABLES IN SCHEMA SNOWFLAKE_CODE_SAMPLE.PUBLIC;
DROP TABLE IF EXISTS SNOWFLAKE_CODE_SAMPLE.PUBLIC.CUSTOMER_SUMMARY; -- This will succeed since SYSADMIN is the owner of the table now.

--USE ROLE ACCOUNTADMIN;
--ALTER SCHEMA SNOWFLAKE_CODE_SAMPLE.PUBLIC DISABLE MANAGED ACCESS;
--SHOW SCHEMAS IN DATABASE SNOWFLAKE_CODE_SAMPLE;

-- 17. Option 2: Reestablish the hierarchy - (Run this on the browser where you are logined as ACCOUNTADMIN)
--USE ROLE SECURITYADMIN;
--GRANT ROLE ANALYST TO ROLE SYSADMIN;
