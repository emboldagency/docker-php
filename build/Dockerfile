ARG UBUNTU_VERSION=24.04 \ 
    PHP_VERSION=8.3 \
    RUBY_VERSION=3.3.0

# -----------------------------------------------------------------------------
# Ruby Builder
# -----------------------------------------------------------------------------
FROM ruby:${RUBY_VERSION}-slim AS ruby

# -----------------------------------------------------------------------------
# Base Setup
# -----------------------------------------------------------------------------
FROM ghcr.io/emboldagency/base:ubuntu${UBUNTU_VERSION} AS base

ARG PHP_VERSION \
    RUBY_VERSION

ENV BUNDLE_APP_CONFIG=/home/embold/.gems/${RUBY_VERSION} \
    GEM_HOME=/home/embold/.gems/${RUBY_VERSION} \
    GEM_PATH=/home/embold/.gem/ruby/${RUBY_VERSION}:/coder/gems/ruby/${RUBY_VERSION} \
    PATH=$PATH:/home/embold/.gems/${RUBY_VERSION}/bin

USER root

# Copy Ruby from the builder stage
COPY --from=ruby /usr/local /usr/local

# Prepare directories
RUN mkdir -p /home/embold/.gems && \
    chown -R embold:embold /home/embold/.gems

# Install PHP and Apache
# We use --mount=type=cache to speed up apt downloads
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    add-apt-repository -y ppa:ondrej/php && \
    add-apt-repository -y ppa:ondrej/apache2 && \
    apt-get update && \
    apt-get install -y -q --no-install-recommends \
    # LAMP Stack
    apache2 dh-php mariadb-client \
    libapache2-mod-php${PHP_VERSION} \
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
    # Image Libraries
    imagemagick \
    libmagickwand-dev \
    # Render Libraries (useful for screenshots even with Chrome)
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libcups2 \
    libdrm2 \
    libgbm1 \
    libgtk-3-0 \
    libnss3 \
    libpango-1.0-0 \
    libpangocairo-1.0-0 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libxss1 && \
    rm -rf /var/lib/apt/lists/*

# -----------------------------------------------------------------------------
# Platform Specific Logic
# -----------------------------------------------------------------------------

FROM base AS ubuntu22.04
RUN apt-get update && \
    apt-get install -y -q --no-install-recommends \
    libasound2 && \
    rm -rf /var/lib/apt/lists/*

FROM base AS ubuntu24.04
RUN apt-get update && \
    apt-get install -y -q --no-install-recommends \
    libasound2t64 && \
    rm -rf /var/lib/apt/lists/*

FROM ubuntu${UBUNTU_VERSION} AS php7.3
RUN apt-get update && \
    apt-get install -y -q --no-install-recommends \
    php7.3-json \
    php7.3-recode && \
    rm -rf /var/lib/apt/lists/*

FROM ubuntu${UBUNTU_VERSION} AS php7.4
RUN apt-get update && \
    apt-get install -y -q --no-install-recommends \
    php7.4-json && \
    rm -rf /var/lib/apt/lists/*

FROM ubuntu${UBUNTU_VERSION} AS php8.1

FROM ubuntu${UBUNTU_VERSION} AS php8.2

FROM ubuntu${UBUNTU_VERSION} AS php8.3

FROM ubuntu${UBUNTU_VERSION} AS php8.4

# -----------------------------------------------------------------------------
# Final Config
# -----------------------------------------------------------------------------
FROM php${PHP_VERSION} AS final
ARG PHP_VERSION

# Copy Coder files LATE to prevent cache busting
COPY --chown=embold:embold --chmod=774 coder /coder

# Apply Configurations
RUN cd /coder && \
    ln -s /coder/conf/embold-mysql.cnf /etc/mysql/conf.d/embold.cnf && \
    ln -s /coder/conf/embold-php.ini /etc/php/${PHP_VERSION}/mods-available/embold.ini && \
    cp conf/embold-apache.conf /etc/apache2/conf-available/embold.conf && \
    sed -i 's/^export APACHE_RUN_USER=.*/export APACHE_RUN_USER=embold/' /etc/apache2/envvars && \
    sed -i 's/^export APACHE_RUN_GROUP=.*/export APACHE_RUN_GROUP=embold/' /etc/apache2/envvars && \
    grep -qxF '. /etc/default/locale' /etc/apache2/envvars || echo '. /etc/default/locale' >> /etc/apache2/envvars && \
    grep -qxF 'export LANG' /etc/apache2/envvars || echo 'export LANG' >> /etc/apache2/envvars && \
    rsync -a --delete conf/sites-available/ /etc/apache2/sites-available && \
    # Combine our configure scripts
    cat scripts/configure-php >> scripts/configure && \
    # Enable mods
    a2enmod rewrite headers && \
    a2enconf embold && \
    phpenmod -v ALL -s ALL embold && \
    # Users
    adduser embold www-data && \
    adduser www-data embold && \
    # WP-CLI
    curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

USER embold

# Gems installed last as they change frequently
RUN mkdir -p "$GEM_HOME" && \
    gem install colorls specific_install && \
    gem specific_install https://github.com/emboldagency/pulsar-embold.git && \
    rm -f /usr/local/bin/bundle /usr/local/bin/bundler || true && \
    if [ -d "$GEM_HOME/cache" ]; then rm -rf "$GEM_HOME/cache"/* || true; fi && \
    chown -R embold:embold "$GEM_HOME"

CMD ["/bin/zsh"]
