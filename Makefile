update-docker:
	docker compose build --pull
	docker compose up -d

# Abuses the "backup" tag
cron backup:
	./copy-caddy-minio-certificate.sh
