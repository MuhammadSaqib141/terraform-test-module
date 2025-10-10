#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# =============================================================================
# CONFIGURATION
# =============================================================================
# These variables should match your OpenTofu configuration.
ENVIRONMENT="dev"
RESOURCE_GROUP_APPS="ordertracking-dev-apps-rg"
IMAGE_TAG="1.0.0" # You can change this for new versions, e.g., "1.0.1"

# These are the names of the Container App resources as defined in your Tofu module.
# The Tofu code generates these from: ${org_prefix}-${environment}-${app_name}-ca
ORDER_API_APP_NAME="ordertracking-dev-order-api-ca"
ORDER_WORKER_APP_NAME="ordertracking-dev-order-worker-c"


# =============================================================================
# SCRIPT LOGIC
# =============================================================================

echo "--> Starting application deployment for environment: $ENVIRONMENT"

# --- 1. Get the ACR Login Server from Tofu Outputs ---
# This dynamically links our deployment to our infrastructure.
echo "--> Retrieving ACR login server from OpenTofu state..."
ACR_LOGIN_SERVER=$(tofu output -json container_registry_login_servers | jq -r .main)

if [ -z "$ACR_LOGIN_SERVER" ]; then
    echo "❌ Error: Could not retrieve ACR login server from Tofu outputs."
    echo "   Please ensure your infrastructure is deployed and the state file is present."
    exit 1
fi
echo "    ACR Found: $ACR_LOGIN_SERVER"

# --- 2. Login to Azure Container Registry ---
echo "--> Logging into ACR..."
az acr login --name "$ACR_LOGIN_SERVER"
echo "    Login successful."

# --- 3. Build, Tag, and Push the 'order-api' image ---
echo "--> Building order-api image for linux/amd64..."
docker build --platform linux/amd64 -t "${ACR_LOGIN_SERVER}/order-api:${IMAGE_TAG}" ./src/order-api

echo "--> Pushing order-api image..."
docker push "${ACR_LOGIN_SERVER}/order-api:${IMAGE_TAG}"
echo "    Push complete."

# --- 4. Build, Tag, and Push the 'order-worker' image ---
echo "--> Building order-worker image for linux/amd64..."
docker build --platform linux/amd64 -t "${ACR_LOGIN_SERVER}/order-worker:${IMAGE_TAG}" ./src/order-worker

echo "--> Pushing order-worker image..."
docker push "${ACR_LOGIN_SERVER}/order-worker:${IMAGE_TAG}"
echo "    Push complete."

# --- 5. Update the Container Apps to use the new images ---
# echo "--> Updating Container App 'order-api' to use image tag: ${IMAGE_TAG}"
# az containerapp update \
#   --name "$ORDER_API_APP_NAME" \
#   --resource-group "$RESOURCE_GROUP_APPS" \
#   --image "${ACR_LOGIN_SERVER}/order-api:${IMAGE_TAG}"
# echo "    Update command sent for order-api."

# echo "--> Updating Container App 'order-worker' to use image tag: ${IMAGE_TAG}"
# az containerapp update \
#   --name "$ORDER_WORKER_APP_NAME" \
#   --resource-group "$RESOURCE_GROUP_APPS" \
#   --image "${ACR_LOGIN_SERVER}/order-worker:${IMAGE_TAG}"
# echo "    Update command sent for order-worker."

# echo ""
# echo "✅ Deployment initiated successfully!"
# echo "   It may take a minute or two for Azure to provision the new revisions."
# echo "   You can now test your API endpoint."