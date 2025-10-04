# srcs/requirements/mariadb/Dockerfile
ARG BASE_IMAGE=debian
ARG OS_VERSION=bookworm
FROM ${BASE_IMAGE}:${OS_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

# Install server/client; keep image lean
RUN apt-get update && apt-get install -y --no-install-recommends \
      mariadb-server mariadb-client \
    && rm -rf /var/lib/apt/lists/*

# IMPORTANT: ensure the image datadir is empty so Docker won't copy it
# into a fresh volume on first attach.
RUN rm -rf /var/lib/mysql/* \
 && mkdir -p /run/mysqld /var/lib/mysql \
 && chown -R mysql:mysql /run/mysqld /var/lib/mysql

# Your configs and entrypoint
COPY conf/99-inception.cnf /etc/mysql/mariadb.conf.d/99-inception.cnf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3306
CMD ["/usr/local/bin/entrypoint.sh"]

