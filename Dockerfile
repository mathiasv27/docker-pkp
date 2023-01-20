# Default context
ARG BUILD_PKP_TOOL=ojs              \
    BUILD_PKP_VERSION=3.3.0-13      \
    BUILD_PKP_APP_PATH=/app         \
    BUILD_LABEL=notset



# GET THE CODE
FROM alpine:3.17 as pkp_code

# Context
ARG BUILD_PKP_TOOL                  \
    BUILD_PKP_VERSION               \
    BUILD_PKP_APP_PATH

RUN apk add --update --no-cache curl tar \
    && mkdir "${BUILD_PKP_APP_PATH}" 

WORKDIR "${BUILD_PKP_APP_PATH}"

# ADD is supossed to download, extract and remove, but there is an issue with some docker
# versions so, for compatibility, doing it manually: https://github.com/moby/moby/issues/33849 
# ADD "https://pkp.sfu.ca/$BUILD_PKP_TOOL/download/$BUILD_PKP_TOOL-$BUILD_PKP_VERSION.tar.gz" "$BUILD_PKP_APP_PATH"

RUN curl -Ss -O "https://pkp.sfu.ca/${BUILD_PKP_TOOL}/download/${BUILD_PKP_TOOL}-${BUILD_PKP_VERSION}.tar.gz" \
    && tar --strip-components=1 -xvzf "${BUILD_PKP_TOOL}-${BUILD_PKP_VERSION}.tar.gz" -C "${BUILD_PKP_APP_PATH}" > /tmp/untar.lst

RUN echo    "==============================================================="   \
    && echo " ---> PKP application: ${PKP_TOOL}"                                \
    && echo " ---> Version:         ${BUILD_PKP_VERSION}"                       \
    && echo "==============================================================="



# GET & SET THE LAMP
FROM php:8.0-apache

# TODO:
# - Concatenate calls to reduce the layers
# - Replace with PKP_variables when possible
# - Remove "vim" in production image
# - Ensure all required packages and php extensions
# - Test with OJS, OMP and OPS.
# - Redirect log output to stdout & FILE.

# Context
ARG BUILD_PKP_TOOL                              \
    BUILD_PKP_VERSION                           \
    BUILD_LABEL                                 \
    BUILD_PKP_APP_PATH

LABEL maintainer="Public Knowledge Project <marc.bria@gmail.com>"
LABEL org.opencontainers.image.vendor="Public Knowledge Project"
LABEL org.opencontainers.image.title="PKP ${BUILD_PKP_TOOL} Web Application"
LABEL org.opencontainers.image.description="Runs a ${BUILD_PKP_TOOL} application over Apache"
LABEL build_version="Docker for ${BUILD_PKP_TOOL} ${BUILD_PKP_VERSION} - Build-date: ${BUILD_LABEL}"

# ARGs only work during building time, so they need to be exported to ENVs:
ENV PKP_TOOL="${BUILD_PKP_TOOL:-ojs}"                       \
    PKP_VERSION="${BUILD_PKP_VERSION:-3.3.0-1}"             \
    SERVERNAME="localhost"                                  \
    WWW_USER="www-data"                                     \
    WWW_PATH_CONF="/etc/apache2/apache2.conf"               \
    WWW_PATH_ROOT="/var/www"                                \
    HTTPS="on"                                              \
    PKP_CLI_INSTALL="0"                                     \
    PKP_DB_HOST="localhost"                                 \
    PKP_DB_USER="${MYSQL_USER:-ojs}"                        \
    PKP_DB_PASSWORD="${MYSQL_PASSWORD:-changeMe}"           \
    PKP_DB_NAME="${MYSQL_DATABASE:-ojs}"                    \
    PKP_WEB_CONF="/etc/apache2/conf.d/$BUILD_PKP_TOOL.conf" \
    PKP_CONF="config.inc.php"                               \
    PKP_CMD="/usr/local/bin/${BUILD_PKP_TOOL:-ojs}-start"


# Basic packages (todo: Remove what don't need to be installed)
ENV PACKAGES        \
    cron            \
    rsyslog         \
    apache2-utils   \
    ca-certificates \
    git             \
    vim

# DEV packages are not required in production images.
ENV PACKAGES_DEV    \
    zlib1g-dev      \
    libmcrypt-dev   \
    libonig-dev     \
    libpng-dev      \
    libxslt-dev     \
    libzip-dev      \
    libbz2-dev      \
    libssl-dev      \
    libxml2-dev
#    libcurl4-openssl-dev    \

# PHP extensions
ENV PHP_EXTENSIONS  \
    gd \
    gettext \
    intl \
    pdo_mysql \
    mysqli \
    zip \
    bz2	\
	exif \
	phar \
	posix \
	session \
	shmop \
	simplexml \
	sockets \
	calendar \
	opcache \
	sysvmsg \
	sysvsem \
	sysvshm \
	tokenizer \
	xml


# Already included in php compilation :
# mbstring  ctype  curl  dom  fileinfo  ftp  iconv  xml (xmlreader  xmlwriter included in php8)  openssl

# Possible values are:
# bcmath bz2 calendar ctype curl dba dom enchant exif ffi fileinfo filter ftp gd gettext gmp hash iconv imap intl json ldap mbstring mysqli oci8 odbc opcache pcntl pdo pdo_dblib pdo_firebird pdo_mysql pdo_oci pdo_odbc pdo_pgsql pdo_sqlite pgsql phar posix pspell readline reflection session shmop simplexml snmp soap sockets sodium spl standard sysvmsg sysvsem sysvshm tidy tokenizer xml xmlreader xmlwriter xsl zend_test zip

WORKDIR ${WWW_PATH_ROOT}/html

# For Debian:
RUN apt-get update && apt-get install -y ${PACKAGES} ${PACKAGES_DEV}
#	&& docker-php-ext-configure $PHP_CONFIGURE \

RUN docker-php-ext-install -j$(nproc) ${PHP_EXTENSIONS}

# RUN pecl channel-update pecl.php.net && \
#     pecl install ${PHP_EXTENSIONS}

RUN docker-php-ext-enable ${PHP_EXTENSIONS}

RUN pecl install xdebug && docker-php-ext-enable xdebug

# Enable mod_rewrite and mod_ssl
RUN a2enmod rewrite ssl

# Building PKP-TOOL (ie: OJS):


# Get the code
COPY --from=pkp_code "${BUILD_PKP_APP_PATH}" .

# Create directories
RUN mkdir -p /etc/ssl/apache2 "${WWW_PATH_ROOT}/files" /run/apache2
RUN echo "PKP_CONF: ${PKP_CONF}"
RUN cp -a config.TEMPLATE.inc.php "${WWW_PATH_ROOT}/html/${PKP_CONF}" 
RUN chown -R ${WWW_USER}:${WWW_USER} "${WWW_PATH_ROOT}"
# Prepare freefont for captcha 
#	&& ln -s /usr/share/fonts/TTF/FreeSerif.ttf /usr/share/fonts/FreeSerif.ttf \
# Prepare crontab
RUN echo "0 * * * *   pkp-run-scheduled" | crontab - 
# Prepare httpd.conf
RUN sed -i -e '\#<Directory />#,\#</Directory>#d' ${WWW_PATH_CONF} 
RUN sed -i -e "s/^ServerSignature.*/ServerSignature Off/" ${WWW_PATH_CONF} 
# Clear the image (list of files to be deleted in exclude.list).
RUN rm -rf /tmp/* 
RUN rm -rf /root/.cache/* \
RUN apt-get clean autoclean \
    && apt-get autoremove --yes 

# # Optional: Some folders are not required (as .git .travis.yml test .gitignore .gitmodules ...)
# 	&& find . -name ".git" -exec rm -Rf '{}' \; \
# 	&& find . -name ".travis.yml" -exec rm -Rf '{}' \; \
# 	&& find . -name "test" -exec rm -Rf '{}' \; \
# 	&& find . \( -name .gitignore -o -name .gitmodules -o -name .keepme \) -exec rm -Rf '{}' \;

COPY "templates/common/$BUILD_PKP_TOOL/root/" /

RUN echo "${BUILD_PKP_TOOL}-${BUILD_PKP_VERSION} [build:" $(date "+%Y%m%d-%H%M%S") "]" > "${WWW_PATH_ROOT}/container.version" \
    && rm -f "${BUILD_PKP_TOOL}-${BUILD_PKP_VERSION}.tar.gz" \
    && cat "${WWW_PATH_ROOT}/container.version"

EXPOSE 80 
EXPOSE 443

VOLUME [ "${WWW_PATH_ROOT}/files", "${WWW_PATH_ROOT}/html" ]

RUN chmod +x "/usr/local/bin/${BUILD_PKP_TOOL}-start"

RUN echo    "==============================================================="   \
    && echo " ---> PKP application: ${PKP_TOOL}"                                \
    && echo " ---> Version:         ${BUILD_PKP_VERSION}"                       \
    && echo " ---> BUILD ID:        $(cat ${WWW_PATH_ROOT}/container.version)"  \
    && echo " ---> Run:             ${PKP_CMD}"                                 \
    && echo "==============================================================="

CMD "${PKP_CMD}"
