ARG BASE_IMAGE=debian
ARG OS_VERSION=bookworm
FROM ${BASE_IMAGE}:${OS_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      mariadb-server mariadb-client \
 && rm -rf /var/lib/apt/lists/* \
 && rm -rf /var/lib/mysql/*

COPY conf/99-inception.cnf /etc/mysql/mariadb.conf.d/99-inception.cnf
COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 3306
CMD ["/usr/local/bin/entrypoint.sh"]
