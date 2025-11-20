ARG UBUNTU_VERSION=24.04
ARG PHP_VERSION=8.3
# Use the Ruby compatibility version (major.minor.0) for stable gem paths
ARG RUBY_VERSION=3.2.0
# BASE_IMAGE ARG allows overriding to local tags during development
ARG BASE_IMAGE=ghcr.io/emboldagency/docker-base:ubuntu${UBUNTU_VERSION}

# -----------------------------------------------------------------------------
# Base Setup
# -----------------------------------------------------------------------------
FROM ${BASE_IMAGE} AS base

ARG PHP_VERSION

USER root

# Install PHP, Apache, and SSL support
# We use --mount=type=cache to speed up apt downloads
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    add-apt-repository -y ppa:ondrej/php \
    && add-apt-repository -y ppa:ondrej/apache2 \
    && apt-get update \
    && apt-get install -y -q --no-install-recommends \
    # The Apache HTTP Server
    apache2 \
    # SSL certificate management (Required for Apache snakeoil certs)
    ssl-cert \
    # PHP interpreter and modules
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
    # Supporting tools
    libapache2-mod-php${PHP_VERSION} \
    mariadb-client \
    dh-php \
    imagemagick \
    libmagickwand-dev \
    # Ruby for Pulsar
    ruby-full \
    # Postgres client libraries
    libpq-dev \
    postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Platform Specific Logic
# -----------------------------------------------------------------------------
FROM base AS php7.4
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get install -y -q --no-install-recommends \
    php7.4-json \
    && rm -rf /var/lib/apt/lists/*

FROM base AS php8.1
FROM base AS php8.2
FROM base AS php8.3
FROM base AS php8.4

# -----------------------------------------------------------------------------
# Final Configuration
# -----------------------------------------------------------------------------
FROM php${PHP_VERSION} AS final
ARG PHP_VERSION
ARG RUBY_VERSION

# Copy/merge coder folder from this image with /coder from base
COPY --chown=embold:embold coder /coder

# Setup Pulsar/Ruby Environment
RUN mkdir -p "/coder/gems/ruby/${RUBY_VERSION}" \
    && chown -R embold:embold "/coder/gems"

# Setup envs so gems install into the image
ENV GEM_HOME=/coder/gems/ruby/${RUBY_VERSION} \
    PATH=/home/embold/.composer/vendor/bin:/home/embold/.gem/ruby/${RUBY_VERSION}/bin:/coder/gems/ruby/${RUBY_VERSION}/bin:$PATH \
    PULSAR_CONF_REPO="git@github.com:emboldagency/pulsar.git"

# Setup Configs & Tools
RUN cd /coder \
    # --- PHP Configs ---
    && ln -sf /coder/conf/embold-php.ini /etc/php/${PHP_VERSION}/mods-available/embold.ini \
    && phpenmod embold \
    # --- MariaDB Config ---
    && ln -sf /coder/conf/embold-mysql.cnf /etc/mysql/conf.d/embold.cnf \
    # --- Apache Config ---
    && cp conf/embold-apache.conf /etc/apache2/conf-available/embold.conf \
    && a2enconf embold \
    # Sync vhosts provided in the build folder
    && rsync -a --delete conf/sites-available/ /etc/apache2/sites-available/ \
    # Configure Apache environment
    && sed -i 's/^export APACHE_RUN_USER=.*/export APACHE_RUN_USER=embold/' /etc/apache2/envvars \
    && sed -i 's/^export APACHE_RUN_GROUP=.*/export APACHE_RUN_GROUP=embold/' /etc/apache2/envvars \
    && a2enmod rewrite headers ssl \
    # --- Users ---
    && adduser embold www-data \
    && adduser www-data embold \
    # --- WP-CLI ---
    && curl -sO https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
    && chmod +x wp-cli.phar \
    && mv wp-cli.phar /usr/local/bin/wp \
    # --- Composer (Using local script) ---
    && bash scripts/install-composer.sh \
    # --- Stable IDE Symlink ---
    && ln -sf /usr/bin/php${PHP_VERSION} /usr/local/bin/php-ide

USER embold

# Gems installed last
RUN gem install bundler rake specific_install \
    && gem specific_install https://github.com/emboldagency/pulsar-embold.git \
    && rm -rf "$GEM_HOME/cache"/* || true

ENV GEM_HOME=/home/embold/.gem/ruby/${RUBY_VERSION} \
    GEM_PATH=/home/embold/.gem/ruby/${RUBY_VERSION}:/coder/gems/ruby/${RUBY_VERSION}

CMD ["/bin/zsh"]