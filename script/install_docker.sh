#!/usr/bin/env bash
set -euo pipefail

if [[ "$(id -u)" -eq 0 ]]; then
  SUDO=""
  TARGET_USER="${SUDO_USER:-root}"
else
  SUDO="sudo"
  TARGET_USER="${USER}"
fi

install_with_apt() {
  ${SUDO} apt-get update
  ${SUDO} apt-get install -y docker.io docker-compose-v2
}

install_with_dnf() {
  ${SUDO} dnf install -y docker
}

install_with_yum() {
  ${SUDO} yum install -y docker
}

start_docker() {
  if command -v systemctl >/dev/null 2>&1 && systemctl list-units >/dev/null 2>&1; then
    ${SUDO} systemctl enable --now docker
    ${SUDO} systemctl status docker --no-pager
    return
  fi

  if command -v service >/dev/null 2>&1; then
    ${SUDO} service docker start
    ${SUDO} service docker status
    return
  fi

  echo "Could not find systemctl or service to start Docker." >&2
  exit 1
}

ensure_docker_compose_command() {
  if command -v docker-compose >/dev/null 2>&1; then
    return
  fi

  if docker compose version >/dev/null 2>&1; then
    ${SUDO} tee /usr/local/bin/docker-compose >/dev/null <<'EOF'
#!/usr/bin/env sh
exec docker compose "$@"
EOF
    ${SUDO} chmod +x /usr/local/bin/docker-compose
    return
  fi

  ${SUDO} curl -L \
    "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" \
    -o /usr/local/bin/docker-compose
  ${SUDO} chmod +x /usr/local/bin/docker-compose
}

echo "[1/6] Install Docker"
if command -v apt-get >/dev/null 2>&1; then
  install_with_apt
elif command -v dnf >/dev/null 2>&1; then
  install_with_dnf
elif command -v yum >/dev/null 2>&1; then
  install_with_yum
else
  echo "No supported package manager found. Install Docker manually first." >&2
  exit 1
fi

echo "[2/6] Enable and start Docker service"
start_docker

echo "[3/6] Add current user to docker group: ${TARGET_USER}"
${SUDO} usermod -aG docker "${TARGET_USER}"

echo "[4/6] Verify Docker"
if [[ "${TARGET_USER}" == "root" ]]; then
  docker version
elif command -v sg >/dev/null 2>&1; then
  sg docker -c "docker version"
else
  ${SUDO} docker version
fi

echo "[5/6] Install Docker Compose"
ensure_docker_compose_command

echo "[6/6] Verify Docker Compose"
docker-compose version

cat <<EOF

Docker installation completed.

If Docker commands fail without sudo in this terminal, refresh the group session:

  newgrp docker

Or log out and log back in.
EOF
