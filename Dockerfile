ARG PHP_VERSION="8.4-rc"

FROM php:${PHP_VERSION}-fpm-alpine
ENV PHP_EXTENSIONS="@composer" \
    REQUIRED_PACKAGES="fcgi" \
    REQUIRED_TEMP_PACKAGES="shadow" \
    ALPINE_PACKAGES="" \
    ALPINE_TEMP_PACKAGES="" \
    BASE_DIRECTORY="/app" \
    USER_ID=33 \
    GROUP_ID=33

COPY --chmod=0777 cmd/docker-php-healthcheck /usr/local/bin/docker-php-healthcheck
COPY --chmod=0777 cmd/docker-php-install /usr/local/bin/docker-php-install
COPY --chmod=0777 cmd/docker-set-id /usr/local/bin/docker-set-id

RUN apk update && \
    apk upgrade && \
    apk add --no-cache $REQUIRED_PACKAGES $REQUIRED_TEMP_PACKAGES $ALPINE_PACKAGES $ALPINE_TEMP_PACKAGES && \
    \
    docker-set-id www-data $USER_ID:$GROUP_ID && \
    \
    mkdir "${BASE_DIRECTORY}" && \
    chown -R www-data:www-data "${BASE_DIRECTORY}" && \
    chmod -R 0755 "${BASE_DIRECTORY}" && \
    \
    docker-php-install $PHP_EXTENSIONS && \
    \
    cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini && \
    rm -rf /usr/local/etc/php/php.ini-* && \
    rm -rf /usr/local/etc/php-fpm.conf.default && \
    \
    echo $'\n' >> /usr/local/etc/php-fpm.d/zz-docker.conf && \
    echo '[www]' >> /usr/local/etc/php-fpm.d/zz-docker.conf && \
    echo 'user =' >> /usr/local/etc/php-fpm.d/zz-docker.conf && \
    echo 'group =' >> /usr/local/etc/php-fpm.d/zz-docker.conf && \
    echo 'pm.status_path = /status' >> /usr/local/etc/php-fpm.d/zz-docker.conf && \
    \
    apk del $ALPINE_TEMP_PACKAGES $REQUIRED_TEMP_PACKAGES && \
    apk cache clean && \
    rm /usr/local/bin/docker-php-install && \
    rm /usr/local/bin/docker-set-id

USER www-data
WORKDIR $BASE_DIRECTORY
HEALTHCHECK --interval=5s --timeout=3s --retries=3 CMD docker-php-healthcheck || exit 1