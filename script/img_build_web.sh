cd /home/sue/pj_final/final_pj/k8s/web/image_build/blue
docker compose build --no-cache
./push_acr.sh

cd ../green
docker compose build --no-cache
./push_acr.sh

k -n app-web rollout restart deploy web-blue
k -n app-web rollout restart deploy web-green

k -n app-web get pod