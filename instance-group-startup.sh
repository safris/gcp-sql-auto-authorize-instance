#!/bin/bash
PROJECT=<your project id>
DB=<your db id>

METADATA=http://metadata.google.internal/computeMetadata/v1

# Get the external IP of this instance
EXTERNAL_IP=$(curl -s "$METADATA/instance/network-interfaces/0/access-configs/0/external-ip" -H "Metadata-Flavor: Google")

# Get access to call the SQL API
curl -s --header "Authorization: Bearer $ACCESS_TOKEN" -X GET https://www.googleapis.com/sql/v1beta4/projects/$PROJECT/instances/$DB?fields=settings/ipConfiguration/authorizedNetworks/value | grep value | awk -F\" '{print $4}' && \
SVC_ACCT=$METADATA/instance/service-accounts/default && \
ACCESS_TOKEN=$(curl -H 'Metadata-Flavor: Google' $SVC_ACCT/token | cut -d'"' -f 4)

# Get the IPs that are authorized to the database
EXISTING_IPS=$(curl -s --header "Authorization: Bearer $ACCESS_TOKEN" -X GET https://www.googleapis.com/sql/v1beta4/projects/$PROJECT/instances/$DB?fields=settings/ipConfiguration/authorizedNetworks/value | grep -B1 -A1 value | tr -d '\n')

# If the $EXTERNAL_IP is already authorized, then there's nothing to do
[ -n "$(echo $EXISTING_IPS | grep $EXTERNAL_IP)" ] && exit 0

# If the $EXISTING_IPS is not empty, prepend a comma
[ -n "$EXISTING_IPS" ] && EXISTING_IPS=", $EXISTING_IPS"

# Patch the database settings with the new authorized IPs
curl -s --header "Authorization: Bearer ${ACCESS_TOKEN}" \
     --header 'Content-Type: application/json' \
     --data "{\"settings\":{\"ipConfiguration\":{\"authorizedNetworks\":[{\"value\":\"$EXTERNAL_IP\"}$EXISTING_IPS]}}}" \
     -X PATCH \
     https://www.googleapis.com/sql/v1beta4/projects/$PROJECT/instances/$DB

# Dump the database settings for visual verification
curl -s --header "Authorization: Bearer $ACCESS_TOKEN" -X GET https://www.googleapis.com/sql/v1beta4/projects/$PROJECT/instances/$DB?fields=settings