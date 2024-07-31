#!/bin/bash

# Enable strict mode for better error handling
set -euo pipefail

# Retrieve API_INTERNAL_HOST from Kubernetes ConfigMap
API_INTERNAL_HOST=$(kubectl get cm global -o jsonpath={.data.mosip-api-internal-host})

echo $API_INTERNAL_HOST

# Ensure required environment variables are set
if [ -z "${API_INTERNAL_HOST:-}" ] || [ -z "${mosip_regproc_client_secret:-}" ]; then
  echo "Error: Environment variables API_INTERNAL_HOST and mosip_regproc_client_secret must be set."
  exit 1
fi

pwd

# Define the properties file path
PROPERTIES_FILE="application.properties"

# Check if the properties file exists
if [ ! -f "$PROPERTIES_FILE" ]; then
  echo "Error: Properties file '$PROPERTIES_FILE' not found!"
  exit 1
fi

# Update the properties file
if ! sed -i "s|^mosip.auth.server.url=.*|mosip.auth.server.url=https://$API_INTERNAL_HOST/v1/authmanager/authenticate/clientidsecretkey|" "$PROPERTIES_FILE"; then
  echo "Error: Failed to update mosip.auth.server.url in '$PROPERTIES_FILE'"
  exit 1
fi

if ! sed -i "s|^mosip.auth.secretkey=.*|mosip.auth.secretkey=$mosip_regproc_client_secret|" "$PROPERTIES_FILE"; then
  echo "Error: Failed to update mosip.auth.secretkey in '$PROPERTIES_FILE'"
  exit 1
fi

if ! sed -i "s|^mosip.ida.server.url=.*|mosip.ida.server.url=https://$API_INTERNAL_HOST/idauthentication/v1/internal/getCertificate?applicationId=IDA&referenceId=IDA-FIR|" "$PROPERTIES_FILE"; then
  echo "Error: Failed to update mosip.ida.server.url in '$PROPERTIES_FILE'"
  exit 1
fi

echo "Properties file updated successfully."
