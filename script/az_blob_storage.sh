# azure blob storage 생성 스크립트

# 리소스 그룹
az group create --name rg-azsis-kbeauty-blob --location koreacentral

# Storage Account (이름은 전세계 고유해야 함)
az storage account create \
  --name azsiskbeautytfstate \
  --resource-group rg-azsis-kbeauty-blob \
  --location koreacentral \
  --sku Standard_LRS \
  --allow-blob-public-access false

# Blob 컨테이너
az storage container create \
  --name tfstate \
  --account-name azsiskbeautytfstate


