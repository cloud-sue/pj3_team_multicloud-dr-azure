az account set --subscription b88f99b0-1f3c-4529-86c5-f80b227c53ac

az keyvault set-policy \
  --name kv-agw-azsis-kbeauty-dev \
  --object-id feffdc93-e27f-43b7-85dc-f677d7708373 \
  --certificate-permissions Get List Create Delete Import Purge Recover Update \
  --secret-permissions Get List Set Delete Purge Recover
  
  az keyvault certificate show \
  --vault-name kv-agw-azsis-kbeauty-dev \
  --name www-sue019522-shop \
  --query '{name:name,id:id}' \
  -o table