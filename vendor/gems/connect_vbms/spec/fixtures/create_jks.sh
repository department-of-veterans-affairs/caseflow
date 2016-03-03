#!/bin/bash

set -e
set -x


DIR=$1
CERT_KEY_FILENAME=$2
SERVER_CERT=$3

openssl pkcs12 -export -name importkey -in "$DIR/$CERT_KEY_FILENAME.crt" -inkey "$DIR/$CERT_KEY_FILENAME.key" -out "$DIR/keystore.p12"
keytool -importkeystore -destkeystore "$DIR/keystore.jks" -srckeystore "$DIR/keystore.p12" -srcstoretype pkcs12 -alias importkey -storepass "importkey"
rm "$DIR/keystore.p12"
keytool -importcert -keystore "$DIR/keystore.jks" -file "$DIR/$SERVER_CERT" -storepass "importkey" -alias "vbms_server_key"

