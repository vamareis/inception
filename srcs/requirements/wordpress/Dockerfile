ARG BASE_IMAGE=debian
ARG OS_VERSION=bookworm
FROM ${BASE_IMAGE}:${OS_VERSION}

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates curl netcat-openbsd\
      php-fpm php-mysql php-cli php-curl php-xml php-mbstring php-zip php-gd \
    && rm -rf /var/lib/apt/lists/*

RUN sed -ri 's@^listen = .*@listen = 9000@' /etc/php/*/fpm/pool.d/www.conf \
 && sed -ri 's@^;?clear_env = .*@clear_env = no@' /etc/php/*/fpm/pool.d/www.conf

RUN curl -fsSL https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
      -o /usr/local/bin/wp \
 && chmod +x /usr/local/bin/wp

RUN mkdir -p /var/www/html && chown -R www-data:www-data /var/www

COPY tools/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000
CMD ["/usr/local/bin/entrypoint.sh"]

