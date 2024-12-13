-- Switch to Caseflow database for the environment you're in
\c caseflow_certification_{ENV}
-- Example in development:
-- \c caseflow_certification_development

-- Enable oracle_fdw extension
CREATE EXTENSION oracle_fdw;

-- This step is not required, however if you'd like to verify the extension was enabled
-- you can print the extension version by uncommenting the command below
-- SELECT oracle_diag ();

-- Please note, if you are running the SQL commands below in the development environment
-- the variables should be as follows
-- ENV = development
-- postgres_user = postgres
-- db_or_load_balancer_url = localhost
-- oracle_listener_port = 1521
-- vacols_user = 'VACOLS_DEV'


-- Skip if you aren't running this as part of an initialization script.
-- To create the Caseflow Database, uncomment the line below
-- CREATE DATABASE caseflow_certification_{ENV} OWNER {postgres_user} ENCODING UTF8;
-- Example in development:
-- CREATE DATABASE caseflow_certification_development OWNER postgres ENCODING UTF8;

-- #####################
-- Init foreign server
-- #####################

-- Create the foreign server
-- Set the dbserver to point to the db or load balancer on the port it uses to query VACOLS
CREATE SERVER vacols_sv FOREIGN DATA WRAPPER oracle_fdw OPTIONS (
    dbserver '{db_or_load_balancer_URL}:1521/BVAP'
    isolation_level 'read_only'
);

-- Grant permissions to the postgres user for the foreign tables
GRANT USAGE ON FOREIGN SERVER vacols_sv TO {postgres_user};

-- Create a user mapping to the foreign server
CREATE USER MAPPING FOR {postgres_user} SERVER vacols_sv OPTIONS (
    USER {vacols_user},
    PASSWORD {vacols_password}
);
