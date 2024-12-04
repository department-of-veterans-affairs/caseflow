#!/bin/sh

ADMIN_EMAIL=admin@caseflow.demo
ADMIN_PASSWORD=caseflow1
USER_EMAIL=caseflow@caseflow.demo
USER_PASSWORD=caseflow1

CASEFLOW_HOST=appeals-pg
VACOLS_HOST=host.docker.internal

echo "⌚︎ Waiting for Metabase to start"
while (! curl -s -m 5 http://localhost:3002/api/session/properties -o /dev/null); do sleep 5; done

echo "😎 Creating admin user"

SETUP_TOKEN=$(curl -s -m 5 -X GET \
    -H "Content-Type: application/json" \
    http://localhost:3002/api/session/properties \
    | jq -r '.["setup-token"]'
)

MB_TOKEN=$(curl -s -X POST \
    -H "Content-type: application/json" \
    http://localhost:3002/api/setup \
    -d '{
    "token": "'${SETUP_TOKEN}'",
    "user": {
        "email": "'${ADMIN_EMAIL}'",
        "first_name": "Caseflow",
        "last_name": "Admin",
        "password": "'${ADMIN_PASSWORD}'"
    },
    "prefs": {
      "allow_tracking": false,
      "site_name": "Caseflow"
    }
}' | jq -r '.id')

echo "Logging in as admin"
ADMIN_SESSION_ID=$(curl -s -X POST -H \
    "Content-type: application/json" http://localhost:3002/api/session \
    -d '{"username": "'${ADMIN_EMAIL}'", "password": "'${ADMIN_PASSWORD}'"}' \
    | jq -r '.id')

echo "Getting Sample Database ID"
SAMPLE_DB_ID=$(curl -X GET http://localhost:3002/api/database -H "X-Metabase-Session: ${ADMIN_SESSION_ID}" \
    | jq '.data[0].id')

echo "Deleting Sample Database"
curl -X DELETE http://localhost:3002/api/database/${SAMPLE_DB_ID} -H "X-Metabase-Session: ${ADMIN_SESSION_ID}"

echo "Creating Caseflow Database connection"
curl -X POST http://localhost:3002/api/database \
  -H "Content-type: application/json" \
  -H "X-Metabase-Session: ${ADMIN_SESSION_ID}" \
  -d '{
    "engine": "postgres",
    "name": "Caseflow DB",
    "details": {
      "host": "'${CASEFLOW_HOST}'", "port":"5432", "db": "caseflow_certification_development", "user": "postgres", "password": "postgres"
    }
  }'

echo -e "\nCreating VACOLS Database connection"
curl -X POST http://localhost:3002/api/database \
  -H "Content-type: application/json" \
  -H "X-Metabase-Session: ${ADMIN_SESSION_ID}" \
  -d '{
    "engine": "oracle",
    "name": "VACOLS",
    "details": {
      "host": "'${VACOLS_HOST}'", "port": "1521", "sid": "BVAP", "name": "VACOLS_DEV", "user": "VACOLS_DEV", "password": "VACOLS_DEV"
    }
  }'

echo -e "\n👥 Creating a basic user: "
curl -s "http://localhost:3002/api/user" \
    -H 'Content-Type: application/json' \
    -H "X-Metabase-Session: ${ADMIN_SESSION_ID}" \
    -d '{"first_name": "Caseflow", "last_name": "User", "email": "'${USER_EMAIL}'", "login_attributes": {"region_filter": "WA"}, "password":"'${USER_PASSWORD}'"}'

echo -e "\nMetabase setup complete!"
