# ci test1
# ci test2
# ci test3
# ci test4  Spring 프로파일을 local로 활성화하여 테스트를 실행. 실제 db 정보는 k8s 환경에서 secret으로 관리할 예정이므로 테스트에서는 H2 인메모리 DB를 사용한다.
# ci test5 - 하위 모듈 provider 검사 제거 위해 disable-rule 옵션을 적용
# ci test6 - dockerfile과 build context root 맞추기
# ci test7 - whatap jar파일 ignore 예외처리
# ci test8 - github action secret으로 ACR 로그인 정보 추가
# ci test9 - oidc 실행 후 output에 나온 값 secret에 저장 후 ACR 로그인에 활용
# ci test10 - plan에 필요한 var.subsription_id를 github action secret으로 관리 -> TF_VAR_subscription_id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
# ci test11 - github가 자동으로 제공하는 GITHUB_TOKEN을 terraform plan 실행 시 soft_fail 옵션과 함께 전달하여, 토큰이 필요한 작업에서 인증 실패 시에도 전체 workflow가 실패하지 않도록 설정
# ci test12 - tfsec-action이 GitHub release API 접근이 조직 IP allow list에 막힐 수 있어 Docker 이미지로 실행한다. 보안 기준이 확정되기 전까지는 결과를 경고로만 남긴다.
# ci test13 - ci test.sh 파일도 ci 에 포함하여 변경사항 감지하도록 설정
# ci test14 - ci tf, was, web 파일 분리
# cd test1 - cd tf, was, web 파일 분리
# cd test2 - 보안 스캔 시 취약점 찾아도 워크플로우 실패하지 않도록 설정
# cd test3 - perl 정규식 안의 [ 문자깨짐해결
# cd test4 - blue/green 이미지 분리해서 업데이트 되도록 설정

######################################################################
# ci test1 - deploy commit message에 있을 때만 workflow 실행하도록 설정
# ci test2 - aws주석처리
# ci test3 - deploy 재 테스트
# ci test4 - 0616/sue : cdcd 주체가  key vault 사용할 수 있게 권한 업데이트 
# ci test5 - environment: dev에서 승인자가 있으면 승인대기할 수 있도록 설정되어있어서 oidc에 subject 추가
# cd test1 - 각 컬러에 맞게 업데이트 되도록 수정
# cd test2 - External Secrets Operator Helm chart를 설치
# cd test3 - External Secrets Operator가 Key Vault에서 Secret을 읽어올 수 있도록 Key Vault Access Policy에 GitHub OIDC 앱 추가