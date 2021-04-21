#!/bin/bash

# This script queries our Metabase's API.
# See reports/sql_queries/README.md

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
	# Why --insecure? To skip verifying SSL certificate -- see https://curl.se/docs/sslcerts.html
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
		>&2 echo ""

		if [ -z "$METABASE_USER" ] || [ -z "$METABASE_PWD" ]; then
			>&2 echo "! Please export METABASE_USER and METABASE_PWD environment variables."
			exit 2
		fi

		>&2 echo "## Asking Metabase for a new session ID"
		METABASE_SESS_ID=`getMetabaseSessionId "$METABASE_USER" "$METABASE_PWD"` || exit 7
		>&2 echo -e "To reuse this session ID, set the environment variable: export METABASE_SESS_ID=\"$METABASE_SESS_ID\"\n"
	fi
	echo "$METABASE_SESS_ID"
}

getCurlSessionCommand(){
	METABASE_SESS_ID=`checkOrGetSessionId` || exit 3
	echo "$CURL_CMD -H 'X-Metabase-Session: $METABASE_SESS_ID'"
}

getAllCards(){
	[ "$CURL_SESS_CMD" ] || CURL_SESS_CMD=`getCurlSessionCommand` || exit 12
	echo "## Retrieving all Metabase cards (aka questions and queries)"
	if eval $CURL_SESS_CMD -X GET "$METABASE_URL/api/card" > "$1"; then
		echo -e "Downloaded cards to $1 \n"
	else
		echo "!! Unsuccesful!"
		exit 8
	fi
}

checkOrInstallJq(){
	if ! `which jq > /dev/null`; then
		echo "Attempting to install jq using yum"
		yum -y install jq || { >&2 echo "Could not install jq!"; exit 30; }
	fi
}

extractQueries(){
	checkOrInstallJq

	CARDS_JSON_FILE=`realpath "$1"`

	[ -d "$2" ] || mkdir -p "$2"
	pushd $2 || { >&2 echo "Cannot change to directory: $2"; exit 21; }

	echo "Reading from $CARDS_JSON_FILE; writing to $OUTPUT_DIR"
	JQ_SCRIPT='.[] | select(.query_type=="native" and .archived==false and (.dataset_query.native.query|test("RAILS_EQUIV"))) | (.database_id|tostring)+" "+(.id|tostring), .dataset_query'
	jq -cr "$JQ_SCRIPT" $CARDS_JSON_FILE | awk 'NR%2{f=sprintf("db%02i_c%04i-metabase-payload.json",$1,$2);next} {print >f;close(f)}'
	popd
}

getResultsForQueries(){
	[ -d "$1" ] || { >&2 echo "Cannot find directory: $1"; exit 22; }
	[ "$CURL_SESS_CMD" ] || CURL_SESS_CMD=`getCurlSessionCommand` || exit 12

	for PAYLOAD_FILE in "$1"/*-metabase-payload.json; do
		if [ -f "$PAYLOAD_FILE" ]; then
			FILE_BASENAME="${PAYLOAD_FILE%-metabase-payload.json}"
			METABASE_RESPONSE_FILE="$FILE_BASENAME-metabase-response.json"
			if eval $CURL_SESS_CMD -d "@$PAYLOAD_FILE" "$METABASE_URL/api/dataset" > "$METABASE_RESPONSE_FILE"; then
				echo "### Saved query result to $METABASE_RESPONSE_FILE and $FILE_BASENAME.mb-out"
				jq -cr '.data.rows | .[] | @csv' "$METABASE_RESPONSE_FILE" > "$FILE_BASENAME.mb-out"
			else
				echo "!! Unsuccesful getting query result for @$1/$PAYLOAD_FILE"
				exit 23
			fi
		else
			echo "Skipping: Not a file: $PAYLOAD_FILE"
		fi
	done
}

if [ "$1" = "session" ]; then
	METABASE_SESS_ID=`checkOrGetSessionId` || exit 11
	echo "export METABASE_SESS_ID=\"$METABASE_SESS_ID\""
	echo "alias curl_metabase=\"$CURL_CMD -H 'X-Metabase-Session: $METABASE_SESS_ID'\""
elif [ "$1" = "queryResults" ]; then
	METABASE_SESS_ID=`checkOrGetSessionId` || exit 11

	: ${CARDS_JSON_FILE:=${2:-'cards.json'}}
	: ${OUTPUT_DIR:=${3:-'reports/queries_output'}}
	extractQueries "$CARDS_JSON_FILE" "$OUTPUT_DIR"
	getResultsForQueries "$OUTPUT_DIR"
elif [ "$1" = "cards" ]; then
	: ${OUTPUT_JSON_FILE:=${2:-cards.json}}
	echo "Will write to $OUTPUT_JSON_FILE"
	# echo "Using base curl command: $CURL_CMD $METABASE_URL/..."
	getAllCards "$OUTPUT_JSON_FILE"
elif [ "$1" = "downloadAndValidate" ]; then
	[ "$CURL_SESS_CMD" ] || CURL_SESS_CMD=`getCurlSessionCommand` || exit 12

	: ${CARDS_JSON_FILE:=${2:-'cards.json'}}
	getAllCards "$CARDS_JSON_FILE" || exit 10

	: ${OUTPUT_DIR:=${3:-'reports/queries_output'}}
	echo "## Getting Metabase's SQL query results and saving results"
	extractQueries "$CARDS_JSON_FILE" "$OUTPUT_DIR"
	getResultsForQueries "$OUTPUT_DIR"

	: ${QUERIES_DIR:=${4:-'reports/sql_queries'}}
	echo "## Running Rake tasks to extract_queries_from cards.json and validate queries"
	bundle exec rake "sql:extract_queries_from[cards.json,$QUERIES_DIR]" "sql:validate[$QUERIES_DIR,$OUTPUT_DIR]"
else
	echo "Usage: $0 cards <output_filename>"
fi


# For reference:
# curl --socks5-hostname 127.0.0.1:2001 -X GET -H "Content-Type: application/json" -H "X-Metabase-Session: $METABASE_SESS_ID" https://query.prod.appeals.va.gov/api/card | jq > cards.json
# cat cards.json | jq '.[] | select (.database_id == 5)' > cards_for_db5.json
# cat cards.json | jq -c '.[] | select (.database_id == 5) | { id: .id } '
