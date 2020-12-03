#!/bin/bash

# This script queries our Metabase's API.

: ${CURL_CMD:=curl}
: ${CF_SOCKS_URI:=127.0.0.1:2001}

if ! which $CURL_CMD > /dev/null; then
	>&2 echo "Command not found: $CURL_CMD"
	exit 1
fi

if [ "$USE_SOCKS" = "true" ]; then
	# When running in dev environment
	>&2 echo "Using socks proxy: $CF_SOCKS_URI"
	>&2 echo "  To not use socks (when you're running within the VA network), run 'unset USE_SOCKS'."
	>&2 echo "  To use a different proxy, run something like 'export CF_SOCKS_URI=proxy.hostname.or.ip:2001'."
	# Why --insecure? Skip verifying certificate -- see https://curl.se/docs/sslcerts.html
	CURL_CMD="$CURL_CMD --insecure --socks5-hostname $CF_SOCKS_URI"
fi

CURL_CMD="$CURL_CMD -H 'Content-Type: application/json'"
METABASE_URL="https://query.prod.appeals.va.gov"

getMetabaseSessionId(){
	PAYLOAD="{\"username\": \"$1\", \"password\": \"$2\"}"
	RESPONSE=`eval $CURL_CMD -d \'$PAYLOAD\' "$METABASE_URL/api/session"`
	if [[ "$RESPONSE" == *"\"id\":"* ]]; then
		>&2 echo "Authentication SUCCESS."
	else
		>&2 echo "! Could not authenticate! Retry or enable using proxy with 'export USE_SOCKS=true'"
		exit 5
	fi
	# Let's use BASH to parse the response instead of relying on "jq -c '.id'"
	SESS_ID="${RESPONSE/\{\"id\":\"/}"
	echo "${SESS_ID/\"\}/}"
}

checkOrGetSessionId(){
	if [ "$METABASE_SESS_ID" ]; then
		>&2 echo "Using existing METABASE_SESS_ID=$METABASE_SESS_ID"
	else
		[ "$METABASE_USER" ] || read -p "Enter your Metabase username (email address): " METABASE_USER
		[ "$METABASE_PWD" ] || read -s -p "Enter your Metabase password: " METABASE_PWD
		echo ""

		if [ -z "$METABASE_USER" ] || [ -z "$METABASE_PWD" ]; then
			>&2 echo "! Please set METABASE_USER and METABASE_PWD environment variables."
			exit 2
		fi

		>&2 echo "## Asking Metabase for a new session ID"
		METABASE_SESS_ID=`getMetabaseSessionId "$METABASE_USER" "$METABASE_PWD"` || exit 7
		>&2 echo -e "To reuse this session ID, set the environment variable: export METABASE_SESS_ID=\"$METABASE_SESS_ID\"\n"
	fi
	echo "$METABASE_SESS_ID"
}

getAllCards(){
	METABASE_SESS_ID=`checkOrGetSessionId` || exit 3
	echo "## Retrieving all Metabase cards (aka questions and queries)"
	CURL_SESS_CMD="$CURL_CMD -X GET -H 'X-Metabase-Session: $METABASE_SESS_ID'"
	if eval $CURL_SESS_CMD "$METABASE_URL/api/card" > "$1"; then
		echo -e "Downloaded cards to $1 \n"
	else
		echo "!! Unsuccesful!"
		exit 8
	fi
}

if [ "$1" = "cards" ]; then
	echo "Using base curl command: $CURL_CMD $METABASE_URL/..."
	getAllCards "$2"
elif [ "$1" = "downloadAndValidate" ]; then
	getAllCards "${2:-cards.json}" || exit 10
	echo "## Running Rake tasks to extract_queries_from cards.json and validate queries"
	bundle exec rake 'sql:extract_queries_from[cards.json,sql_queries]' 'sql:validate[sql_queries,queries_output]'
else
	echo "Usage: $0 cards <output_filename>"
fi


# For reference:
# curl --socks5-hostname 127.0.0.1:2001 -X GET -H "Content-Type: application/json" -H "X-Metabase-Session: $METABASE_SESS_ID" https://query.prod.appeals.va.gov/api/card | jq > cards.json
# cat cards.json | jq '.[] | select (.database_id == 5)' > cards_for_db5.json
# cat cards.json | jq -c '.[] | select (.database_id == 5) | { id: .id } '
