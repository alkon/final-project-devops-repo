# --- Step 0: Ensure argocd-server pods restart to pick up ConfigMap changes ---
# (This step was already performed and confirmed by you, but included for completeness
# if you were to run this script from scratch again in the future).
echo "Restarting argocd-server pods to ensure ConfigMap changes are applied (if not already done)..."
kubectl rollout restart deployment argocd-server -n argocd
# Give it sufficient time for the pods to terminate and new ones to become ready
echo "Waiting for argocd-server pods to restart and become ready (approx. 30 seconds)..."
sleep 30
echo "Argo CD server pods should be restarted and ready."

# --- Step 1: Get the current initial admin password from the Kubernetes Secret ---
echo "Retrieving the current initial admin password from Kubernetes secret..."
ARGOCD_ADMIN_PASSWORD=$(kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 --decode)
echo "Admin password retrieved."

# --- Step 2: Log in to Argo CD using the retrieved password ---
# This establishes a valid session to allow token generation
ARGOCD_SERVER_ADDRESS="localhost:30080" # Ensure this matches your NodePort configuration

echo "Logging in to Argo CD with the admin password..."
argocd login "$ARGOCD_SERVER_ADDRESS" --username admin --password "$ARGOCD_ADMIN_PASSWORD" --plaintext

# --- Step 3: Generate a brand new API token for the 'admin' account with 3 months expiration ---
# --expires-in 90d sets the token to expire in 90 days.
echo "Attempting to generate a new API token for 'admin' account, expiring in 3 months (90 days)..."
NEW_ARGO_CD_TOKEN=$(argocd account generate-token --account admin --expires-in 90d --plaintext)

# Check if the token generation was successful before printing
if [ -z "$NEW_ARGO_CD_TOKEN" ]; then
  echo "ERROR: Token generation failed. The 'NEW_ARGO_CD_TOKEN' variable is empty."
  echo "Please check Argo CD server logs for more details: kubectl logs -f -n argocd -l app.kubernetes.io/name=argocd-server"
  exit 1
fi

echo "--- NEWLY GENERATED ARGO CD TOKEN (Expires in 3 months) ---"
echo "$NEW_ARGO_CD_TOKEN"
echo "----------------------------------------------------------"

# --- Step 4: Set the new token and server address as environment variables ---
# This is the most reliable way for non-interactive CLI usage
export ARGOCD_SERVER="$ARGOCD_SERVER_ADDRESS"
export ARGOCD_AUTH_TOKEN="$NEW_ARGO_CD_TOKEN"

echo "Environment variables ARGOCD_SERVER and ARGOCD_AUTH_TOKEN are now set with the new 3-month token."

# --- Step 5: Verify the new token by running an authenticated command ---
echo "Verifying the new token by listing Argo CD applications..."
argocd app list --plaintext