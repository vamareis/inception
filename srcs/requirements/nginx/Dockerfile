ARG BASE_IMAGE=debian
ARG OS_VERSION=bookworm
FROM ${BASE_IMAGE}:${OS_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      nginx openssl ca-certificates netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /etc/nginx/certs /var/www/html /var/run/nginx \
 && chmod 700 /etc/nginx/certs

RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default || true

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 443
CMD ["/usr/local/bin/entrypoint.sh"]
