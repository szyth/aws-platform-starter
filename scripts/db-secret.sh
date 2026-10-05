#!/usr/bin/env bash
# Creates (or updates) the Kubernetes Secret the app reads DATABASE_URL from.
# Inputs come from Terraform outputs; the password comes from Secrets Manager,
# where RDS generated it. Nothing secret is printed or written to disk.
#
#   ./scripts/db-secret.sh                    # defaults below
#   NAMESPACE=prod ./scripts/db-secret.sh
#
# Production alternative: External Secrets Operator syncs the secret
# automatically, including RDS password rotations.
set -euo pipefail

NAMESPACE="${NAMESPACE:-default}"
SECRET_NAME="${SECRET_NAME:-rust-backend-starter-db}"
ENV_DIR="$(cd "$(dirname "$0")/../envs/dev" && pwd)"

endpoint=$(terraform -chdir="$ENV_DIR" output -raw db_endpoint)       # host:5432
db_name=$(terraform -chdir="$ENV_DIR" output -raw db_name)
secret_arn=$(terraform -chdir="$ENV_DIR" output -raw db_master_secret_arn)

creds=$(aws secretsmanager get-secret-value --secret-id "$secret_arn" \
  --query SecretString --output text)                                 # {"username","password"}

# URL-encode user and password (generated passwords can contain : # ? % ...);
# RDS enforces TLS, so require it from the client too.
database_url=$(jq -r --arg ep "$endpoint" --arg db "$db_name" \
  '"postgres://\(.username|@uri):\(.password|@uri)@\($ep)/\($db)?sslmode=require"' <<<"$creds")

# create-or-update without ever showing the value
kubectl create secret generic "$SECRET_NAME" --namespace "$NAMESPACE" \
  --from-literal=DATABASE_URL="$database_url" \
  --dry-run=client -o yaml | kubectl apply -f -

echo "secret/$SECRET_NAME ready in namespace $NAMESPACE"
