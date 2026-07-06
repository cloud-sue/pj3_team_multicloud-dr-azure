# WEB Kubernetes

AKS에서 ACR 이미지를 pull 받아 WEB Pod를 배포하는 매니페스트입니다.

## 기준값

| 항목 | WEB |
| --- | --- |
| Namespace | `app-web` |
| Node pool | `appnp` |
| 최소 Replica | `2` |
| 최대 Replica | `20` |
| CPU Request | `200m` |
| Memory Request | `256Mi` |
| CPU Limit | `500m` |
| Memory Limit | `512Mi` |
| HPA 기준 | CPU `60%` |
| 배포 방식 | Blue/Green + Canary |
| Ingress controller | AGIC |

## ACR Pull 권한

AKS가 Azure Container Registry에서 이미지를 받으려면 AKS에 ACR pull 권한을 연결합니다. 이 방식이면 Pod YAML에 `imagePullSecrets`를 넣지 않아도 됩니다.

```bash
az aks update \
  --resource-group rg-azsis-kbeauty-dev \
  --name aks-azsis-kbeauty-dev \
  --attach-acr azsiskbeautyacr
```

## 이미지 변경

`blue/deployment.yaml`, `green/deployment.yaml`의 image 값을 실제 ACR 주소와 태그에 맞게 바꿉니다.

```text
azsiskbeautyacr.azurecr.io/final-pj-web:blue
azsiskbeautyacr.azurecr.io/final-pj-web:green
```

## 적용

```bash
kubectl apply -k /home/sue/pj_final/final_pj/k8s/web
kubectl -n app-web get deploy,svc,hpa,ingress,pod -o wide
```

## Blue/Green 전환

기본 트래픽은 `web-active` Service가 `blue`를 바라봅니다. green으로 전환하려면 selector를 바꿉니다.

```bash
kubectl -n app-web patch service web-active \
  -p '{"spec":{"selector":{"app":"web","color":"green"}}}'
```

blue로 롤백:

```bash
kubectl -n app-web patch service web-active \
  -p '{"spec":{"selector":{"app":"web","color":"blue"}}}'
```

## Canary

AGIC는 nginx ingress의 `canary-weight` 같은 annotation 방식의 가중치 분산을 그대로 지원하지 않습니다. 이 구성에서는 `/canary` 경로를 `web-green` Service로 보내서 새 버전을 먼저 검증합니다.

현재 라우팅 구조:

```text
/        -> web-active -> blue 또는 green
/canary  -> web-green
```

운영 흐름:

```text
1. 새 WEB 이미지를 green Deployment에 배포
2. http://<AGW-IP>/canary 로 green 버전 검증
3. 문제 없으면 web-active Service selector를 green으로 변경
4. 전체 일반 트래픽이 green으로 전환됨
```

green으로 전체 전환:

```bash
kubectl -n app-web patch service web-active \
  -p '{"spec":{"selector":{"app":"web","color":"green"}}}'
```

blue로 롤백:

```bash
kubectl -n app-web patch service web-active \
  -p '{"spec":{"selector":{"app":"web","color":"blue"}}}'
```

`/canary`에서 흰 화면이 나오면 green 이미지가 `/assets/...`를 root 경로로 요청하고 있을 가능성이 큽니다. `app/web_green/vite.config.js`는 canary 경로에서 JS/CSS를 green Service로 받기 위해 `base: "/canary/"`를 사용합니다. 이 값을 바꾼 뒤에는 green 이미지를 다시 빌드하고 push해야 합니다.
