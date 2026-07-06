cd /home/eerah/final_pj/k8s/was/image_build/blue
docker compose build --no-cache
./push_acr.sh

cd ../green
docker compose build --no-cache
./push_acr.sh

k -n app-was rollout restart deploy was-blue
k -n app-was rollout restart deploy was-green

k -n app-was get pod