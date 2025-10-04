# srcs/requirements/nginx/Dockerfile
ARG BASE_IMAGE=debian
ARG OS_VERSION=bookworm
FROM ${BASE_IMAGE}:${OS_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

# Nginx + openssl for runtime cert generation
RUN apt-get update && apt-get install -y --no-install-recommends \
      nginx openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Create cert dir; keep perms tight
RUN mkdir -p /etc/nginx/certs /var/www/html /var/run/nginx \
 && chmod 700 /etc/nginx/certs

# Remove Debian's default site to avoid conflicts
RUN rm -f /etc/nginx/sites-enabled/default /etc/nginx/sites-available/default || true

# Entrypoint
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 443
CMD ["/usr/local/bin/entrypoint.sh"]
