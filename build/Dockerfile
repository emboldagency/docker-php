ARG UBUNTU_VERSION=24.04 \ 
    PHP_VERSION=8.3 \
    RUBY_VERSION=3.3.0

FROM emboldcreative/base:ubuntu${UBUNTU_VERSION} AS base

ARG PHP_VERSION \
    RUBY_VERSION

ENV BUNDLE_APP_CONFIG=/home/embold/.gems/${RUBY_VERSION} \
    GEM_HOME=/home/embold/.gems/${RUBY_VERSION} \
    PATH=$PATH:/home/embold/.gems/${RUBY_VERSION}/bin

USER root

RUN ruby-build ${RUBY_VERSION} /usr/local \
    && gem update --system \
    && chown -R embold:embold /home/embold/.gems

RUN add-apt-repository -y ppa:ondrej/php && \
    add-apt-repository -y ppa:ondrej/apache2 && \
    apt-get update && \
    apt-get install -y -q --no-install-recommends \
    # LAMP
    apache2 \
    dh-php \
    libapache2-mod-php${PHP_VERSION} \
    mariadb-client \
    php${PHP_VERSION} \
    php${PHP_VERSION}-bcmath \
    php${PHP_VERSION}-bz2 \
    php${PHP_VERSION}-cgi \
    php${PHP_VERSION}-cli \
    php${PHP_VERSION}-common \
    php${PHP_VERSION}-curl \
    php${PHP_VERSION}-dev \
    php${PHP_VERSION}-enchant \
    php${PHP_VERSION}-fpm \
    php${PHP_VERSION}-gd \
    php${PHP_VERSION}-gmp \
    php${PHP_VERSION}-imagick \
    php${PHP_VERSION}-imap \
    php${PHP_VERSION}-interbase \
    php${PHP_VERSION}-intl \
    php${PHP_VERSION}-ldap \
    php${PHP_VERSION}-mbstring \
    php${PHP_VERSION}-mysql \
    php${PHP_VERSION}-odbc \
    php${PHP_VERSION}-opcache \
    php${PHP_VERSION}-pgsql \
    php${PHP_VERSION}-phpdbg \
    php${PHP_VERSION}-pspell \
    php${PHP_VERSION}-readline \
    php${PHP_VERSION}-snmp \
    php${PHP_VERSION}-soap \
    php${PHP_VERSION}-sqlite3 \
    php${PHP_VERSION}-sybase \
    php${PHP_VERSION}-tidy \
    php${PHP_VERSION}-xdebug \
    php${PHP_VERSION}-xmlrpc \
    php${PHP_VERSION}-xsl \
    php${PHP_VERSION}-zip \
    # Browser and image processing dependencies
    chromium-browser \
    imagemagick \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libmagickwand-dev \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libxss1 \
    # Ubuntu version specific dependencies
    && if [ "$UBUNTU_VERSION" = "24.04" ]; then \
    apt-get install -y --no-install-recommends \
    libasound2t64; \
    fi \
    && if [ "$UBUNTU_VERSION" = "22.04" ]; then \
    apt-get install -y --no-install-recommends \
    libasound2; \
    fi \
    && rm -rf /var/lib/apt/lists/*

# Install version specific packages, if any
# Added these to handle the packages that are only available for specific versions of PHP

FROM base AS php7.3

RUN apt-get update \
    && apt-get install -y \
    php7.3-json \
    php7.3-recode \
    && rm -rf /var/lib/apt/lists/*

FROM base AS php7.4

RUN apt-get update \
    && apt-get install -y \
    php7.4-json \
    && rm -rf /var/lib/apt/lists/*

FROM base AS php8.1

FROM base AS php8.2

FROM base AS php8.3

FROM base AS php8.4

FROM php${PHP_VERSION} AS final

ARG PHP_VERSION

COPY --chown=embold:embold --chmod=774 coder /coder

RUN cd /coder \
    && ln -s /coder/conf/embold-mysql.cnf /etc/mysql/conf.d/embold.cnf \
    && ln -s /coder/conf/embold-php.ini /etc/php/${PHP_VERSION}/mods-available/embold.ini \
    && cp conf/embold-apache.conf /etc/apache2/conf-available/embold.conf \
    && sed -i 's/^export APACHE_RUN_USER=.*/export APACHE_RUN_USER=embold/' /etc/apache2/envvars \
    && sed -i 's/^export APACHE_RUN_GROUP=.*/export APACHE_RUN_GROUP=embold/' /etc/apache2/envvars \
    && grep -qxF '. /etc/default/locale' /etc/apache2/envvars || echo '. /etc/default/locale' >> /etc/apache2/envvars \
    && grep -qxF 'export LANG' /etc/apache2/envvars || echo 'export LANG' >> /etc/apache2/envvars \
    && rsync -a --delete conf/sites-available/ /etc/apache2/sites-available \
    # Combine our configure scripts
    && cat scripts/configure-php >> scripts/configure \
    # Enable apache modules and configuration
    && a2enmod rewrite \
    && a2enmod headers \
    && a2enconf embold \
    && phpenmod -v ALL -s ALL embold \
    # Create our user
    && adduser embold www-data \
    && adduser www-data embold \
    # Install wp-cli
    && curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp

USER embold

RUN mkdir -p $GEM_HOME \
    && gem install colorls /coder/pulsar-*.gem --conservative

CMD ["/bin/zsh"]
