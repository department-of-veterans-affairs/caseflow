CREATE EXTENSION oracle_fdw;

CREATE SERVER vacols_sv FOREIGN DATA WRAPPER oracle_fdw OPTIONS (
    dbserver 'vacols_db:1521/BVAP'
);

-- Grant permissions to the postgres user for the foreign tables
GRANT USAGE ON FOREIGN SERVER vacols_sv TO postgres;

-- Create a user mapping to the foreign server
CREATE USER MAPPING FOR postgres SERVER vacols_sv OPTIONS (
    USER 'VACOLS_DEV',
    PASSWORD 'VACOLS_DEV'
);
