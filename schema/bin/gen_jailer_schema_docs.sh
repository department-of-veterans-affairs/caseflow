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

# Build Jailer models of Caseflow's DB in the Jailer installation directory
sh jailer.sh build-model -jdbcjar lib/postgresql-42.2.16.jar \
  -datamodel caseflow-schema org.postgresql.Driver \
  jdbc:postgresql://localhost:5432/caseflow_certification_development postgres postgres

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
