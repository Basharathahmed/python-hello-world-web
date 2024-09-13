#!/bin/bash
set -e

az login

# Define variables
RESOURCE_GROUP="sample-resource"
CLUSTER_NAME="sample-akscluster"
ACR_NAME="sampleacr12"
SECRET_NAME="acr-secret"
DOCKER_USERNAME="${DOCKER_USERNAME:-default-username}"
DOCKER_PASSWORD="${DOCKER_PASSWORD:-default-password}"
DOCKER_EMAIL="${DOCKER_EMAIL:-default-email@example.com}"
NAMESPACE="default"

# Check if required environment variables are set
if [ -z "$DOCKER_USERNAME" ] || [ -z "$DOCKER_PASSWORD" ] || [ -z "$DOCKER_EMAIL" ]; then
  echo "Error: Docker credentials are not set."
  exit 1
fi

# Function to check command success
check_success() {
  if [ $? -ne 0 ]; then
    echo "Error: Command failed."
    exit 1
  fi
}

# Update AKS cluster to attach ACR
echo "Attaching ACR to AKS cluster..."
az aks update --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --attach-acr "$ACR_NAME"
check_success

# Configure kubectl to use the AKS cluster
echo "Configuring kubectl to use the AKS cluster..."
az aks get-credentials --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME"
check_success

# Verify ACR attachment
echo "Verifying ACR attachment..."
az aks show --resource-group "$RESOURCE_GROUP" --name "$CLUSTER_NAME" --query "attachedACRs" --output table
check_success

# Create Docker registry secret
echo "Creating Docker registry secret..."
kubectl create secret docker-registry "$SECRET_NAME" \
  --docker-server="$ACR_NAME.azurecr.io" \
  --docker-username="$DOCKER_USERNAME" \
  --docker-password="$DOCKER_PASSWORD" \
  --docker-email="$DOCKER_EMAIL" \
  --namespace "$NAMESPACE"
check_success

echo "Script execution completed successfully."
