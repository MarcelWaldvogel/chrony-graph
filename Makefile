update-docker:
	docker compose build --pull
	docker compose up -d

# Abuses the "backup" tag for a daily cron
backup:	update-certificate

update-certificate:
	./copy-caddy-minio-certificate.sh

