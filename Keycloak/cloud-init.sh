#!/bin/bash
apt update -y
apt install -y docker*
systemctl enable --now docker.service


# Generate certificates using Docker
docker run -v $PWD/certs:/certs \
  -e CA_SUBJECT="My own root CA" \
  -e CA_EXPIRE="1825" \
  -e SSL_EXPIRE="365" \
  -e SSL_SUBJECT="${keycloak_server_name}" \
  -e SSL_DNS="${keycloak_server_name}" \
  -e SILENT="true" \
  superseb/omgwtfssl

# Combine certificate and CA into fullchain.pem
cat certs/cert.pem certs/ca.pem > certs/fullchain.pem


# Set up Keycloak certificates directory
mkdir -p /opt/keycloak/certs
cp certs/fullchain.pem /opt/keycloak/certs/
cp certs/key.pem /opt/keycloak/certs/


cat <<EOF > /opt/keycloak/keycloak.yml
version: '3'
services:
  keycloak:
    image: quay.io/keycloak/keycloak:latest
    container_name: keycloak
    restart: always
    ports:
      - 80:8080
      - 443:8443
    volumes:
      - ./certs/fullchain.pem:/etc/x509/https/tls.crt
      - ./certs/key.pem:/etc/x509/https/tls.key
    environment:
      - KEYCLOAK_ADMIN=admin
      - KEYCLOAK_ADMIN_PASSWORD=${keycloak_password}
      - KC_HOSTNAME=${keycloak_server_name}
      - KC_HTTPS_CERTIFICATE_FILE=/etc/x509/https/tls.crt
      - KC_HTTPS_CERTIFICATE_KEY_FILE=/etc/x509/https/tls.key
    command:
      - start-dev
EOF

# Start Keycloak with Docker Compose
curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/bin/docker-compose 
chmod +x /usr/bin/docker-compose
docker-compose -f /opt/keycloak/keycloak.yml up
