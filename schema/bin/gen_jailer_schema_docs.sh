#!/bin/bash

CASEFLOW_HOME=$1

# In Caseflow, `make doc-schema-caseflow` creates $CASEFLOW_HOME/docs/schema/caseflow-jailer_polymorphic_associations.csv
POLYMOPHIC_CSV_FILE="$2"

[ -d "$CASEFLOW_HOME" ] || { echo "ERROR: Cannot find Caseflow directory: '$CASEFLOW_HOME'"; exit 1; }

[ -f "$POLYMOPHIC_CSV_FILE" ] || {
	echo "ERROR: Cannot find Caseflow's polymorphic association csv file: '$POLYMOPHIC_CSV_FILE'"
	exit 2
}

[ -d "caseflow-schema" ] && rm -rf caseflow-schema

[ "$POSTGRES_DB" ] || { echo "ERROR: Environment variable POSTGRES_DB is not set"; exit 10; }
[ "$POSTGRES_USER" ] || { echo "ERROR: Environment variable POSTGRES_USER is not set"; exit 11; }
[ "$POSTGRES_PASSWORD" ] || { echo "ERROR: Environment variable POSTGRES_PASSWORD is not set"; exit 12; }

echo "Querying DB: $POSTGRES_DB as user $POSTGRES_USER"
# Build Jailer models of Caseflow's DB in the Jailer installation directory
sh jailer.sh build-model -jdbcjar lib/postgresql-42.2.16.jar \
  -datamodel caseflow-schema org.postgresql.Driver \
  "jdbc:postgresql://localhost:5432/$POSTGRES_DB" "$POSTGRES_USER" "$POSTGRES_PASSWORD"

[ -f "caseflow-schema/association.csv" ] || {
	echo "ERROR: Jailer didn't create file: 'caseflow-schema/association.csv'"
	ls -al
	exit 3
}

#  Append the file created by this method to 'caseflow-schema/association.csv' created by Jailer:
cat "$POLYMOPHIC_CSV_FILE" >> caseflow-schema/association.csv

# Create the html pages
echo "Caseflow schema; 1600000000000" >> caseflow-schema/modelname.csv
sh jailer.sh render-datamodel -datamodel caseflow-schema

# Update Caseflow's documentation:
rsync -av render/Caseflowschema/ ../html/
