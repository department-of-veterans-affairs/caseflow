#!/bin/bash


# Clear the Status

export STATUS= ;



# Clear the tmp results file

rm /tmp/output.tmp 2>/dev/null;



# Get the X-AUTH-TOKEN

export X_AUTH_TOKEN=$(credstash -t appeals-credstash get caseflow.prod.govdelivery_token) ;



# Set the csv file initial header - TODO: Expand to include the gov delivery items

export HEADER='"request_id","date ET","class","appeal_id","email_address","email_type","gov_delivery_id","total","new","sending","inconclusive","blacklisted","canceled","sent","failed"'



# Set the Start and End Times

export START_TIME=`date -d "yesterday 00:00" "+%s"`

export END_TIME=`date -d "today 00:00" "+%s"`



# Set the Cloud Watch Log Group to Pull the gov_delivery_id's and appeals_ids from

export LOG_GROUP_NAME="dsva-appeals-certification-prod/opt/caseflow-certification/src/log/caseflow-certification.out"



# Send Query to AWS Cloud Formation

echo "Send Query to AWS Cloud Formation"

aws logs start-query --log-group-name "$LOG_GROUP_NAME"  --start-time "$START_TIME" --end-time "$END_TIME"  --query-string 'fields @message | display @message | filter @message like /gov_delivery_id/' | grep "queryId" | awk '{ print $2 }' | sed 's/"//g' > /tmp/query-id



# Populate the QUERY_ID to get the response object

export QUERY_ID=$(cat /tmp/query-id) ;



# Get the AWS Cloud Watch Query Results

echo "Get AWS Cloud Watch Query Results for ${QUERY_ID}" ;

while [ "${STATUS}" != "Complete" ] ; do

  export RESULTS=`aws logs get-query-results --query-id "${QUERY_ID}"` ;

  export STATUS=`echo "${RESULTS}" | jq .status | sed 's/"//g'` ;

done



# Parse the Cloud Watch Query Results

echo "Parsing the Cloud Watch Query Results to /tmp/output.tmp" ;

echo ${RESULTS} | jq .results | jq -c '.[][].value' | while read i; do

  echo ${i} | grep appeals | grep -v success | sed 's/"//g' | sed 's/\[//g'| sed 's/\]//g' | sed 's/{//g' | sed 's/}//g' |sed 's/=>/ /g' | sed 's/,//g' | sed 's/\/messages\/email\///g'| awk '{ print $2","$4" "$5","$9","$11","$13","$15","$19 }' >> /tmp/output.tmp ;

done



# Set the Header, Parse the JSON, and create the final csv records

echo ${HEADER} > /tmp/output.csv

echo "Call govdelivery API with gov_delivery_id" ;

cat /tmp/output.tmp | grep -v "request_id" | while read i; do

  export APPEAL_URL=`echo ${i} | awk -F"," '{ print "https://tms.govdelivery.com/messages/email/"$7 }'` ;

  export RESPONSE=$(curl -sS -k "$APPEAL_URL" -H "X-Auth-Token: ${X_AUTH_TOKEN}") ;

  export TOTAL=$(echo ${RESPONSE} | jq .recipient_counts.total) ;

  export NEW=$(echo ${RESPONSE} | jq .recipient_counts.new) ;

  export SENDING=$(echo ${RESPONSE} | jq .recipient_counts.sending) ;

  export INCONCLUSIVE=$(echo ${RESPONSE} | jq .recipient_counts.inconclusive) ;

  export BLACKLISTED=$(echo ${RESPONSE} | jq .recipient_counts.blacklisted) ;

  export CANCELED=$(echo ${RESPONSE} | jq .recipient_counts.canceled) ;

  export SENT=$(echo ${RESPONSE} | jq .recipient_counts.sent) ;

  export FAILED=$(echo ${RESPONSE} | jq .recipient_counts.failed) ;

  echo "${i},${TOTAL},${NEW},${SENDING},${INCONCLUSIVE},${BLACKLISTED},${CANCELED},${SENT},${FAILED}" >> /tmp/output.csv

done



rm /tmp/output.tmp

rm /tmp/query-id
