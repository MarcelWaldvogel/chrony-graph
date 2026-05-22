#!/bin/sh
# Copies the certificate from the Caddy S3 storage (e.g. MinIO) to the
# /etc/chrony/keys and restarts chrony if necessary
#
# Run this when the certificate is available (or ready to be created)
# and regularly via cron or similar (once daily should be sufficient)
#
# Configuration from .env
# - THISHOST: The FQDN this host should be reachable under;
#     e.g. ntp.example.ch 
# - MINIO_BASE: The path the the directory where Caddy stores certificates and
#     keys; e.g. caddy/caddy-admin/acme/certificates/acme-v02.api.letsencrypt.org-directory/
#     (of course, the `caddy` alias needs to be configured for mc for this to work)

. ./.env

KEYSDIR=/etc/chrony/keys
CONFDIR=/etc/chrony/conf.d
CONF="${CONFDIR}/nts-server.conf"

# Try to create/renew the certificate, if needed
curl "https://${THISHOST}" > /dev/null

# Set up configuration on first run
if [ ! -r "${CONF}" ]
then
  cat << EOF > "${CONF}"
ntsdumpdir	/var/lib/chrony
ntsserverkey	${KEYSDIR}/${THISHOST}.key
ntsservercert	${KEYSDIR}/${THISHOST}.crt
EOF
  mkdir -p "${KEYSDIR}/tmp"
  chown caddy:caddy "${KEYSDIR}"
  chmod 600 "${KEYSDIR}"
fi

# Copy files to .../tmp and verify locally whether they need updates
mc cp --recursive "${MINIO_BASE}/${THISHOST}/" "${KEYSDIR}/tmp"
if [ -r "${KEYSDIR}/${THISHOST}.crt" ] && cmp "${KEYSDIR}/${THISHOST}.crt" "${KEYSDIR}/tmp/${THISHOST}.crt"
then
  cp --update "${KEYSDIR}/tmp/${THISHOST}".{key,crt} "${KEYSDIR}"
  systemctl restart chronyd
fi
