FROM emboldcreative/base:ubuntu22.04

USER root

RUN add-apt-repository -y ppa:ondrej/php && \
  add-apt-repository -y ppa:ondrej/apache2 && \
	apt-get update && \
  apt-get install -y -q --no-install-recommends && \
	# Ruby for capistrano/pulsar
	ruby \
	ruby-dev \
	ruby-irb \
	ruby-rake \
	ruby-bigdecimal && \
	# LAMP
	apache2 \
	dh-php \
  libapache2-mod-php8.1 \
	mariadb-client && \
	php8.1 \
	php8.1-bz2 \
	php8.1-cgi \
	php8.1-cli \
	php8.1-common \
	php8.1-curl \
	php8.1-dev \
	php8.1-enchant \
	php8.1-fpm \
	php8.1-gd \
	php8.1-gmp \
	php8.1-imagick \
	php8.1-imap \
	php8.1-interbase \
	php8.1-intl \
	php8.1-ldap \
	php8.1-mbstring \
	php8.1-mysql \
	php8.1-odbc \
	php8.1-opcache \
	php8.1-pgsql \
	php8.1-phpdbg \
	php8.1-pspell \
	php8.1-readline \
	php8.1-snmp \
	php8.1-soap \
	php8.1-sqlite3 \
	php8.1-sybase \
	php8.1-tidy \
	php8.1-xdebug \
	php8.1-xmlrpc \
	php8.1-xsl \
	php8.1-zip \
	&& rm -rf /var/lib/apt/lists/*

COPY conf/90-embold-mysql-client.cnf /etc/mysql/mariadb.conf.d/90-embold-mysql-client.cnf 
COPY conf/90-embold-php.ini /coder/90-embold-php.ini
COPY conf/embold-apache2.conf /etc/apache2/conf-available/embold-apache2.conf 
COPY conf/sites /etc/apache2/sites-available
COPY configure-php /coder/configure-php

# Combine our configure scripts
RUN cat /coder/configure-php >> /coder/configure

# Enable apache modules and configuration
RUN a2enmod rewrite & \
    a2enmod headers & \
    a2enconf embold-apache2

# Copy files needed for composer
COPY install-composer.sh /coder/install-composer.sh 
RUN chmod +x /coder/install-composer.sh

RUN adduser embold www-data && \
    adduser www-data embold

USER embold

# Ruby gems
RUN gem install bundler colorls pulsar

# Install wp-cli
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

HEALTHCHECK CMD curl -f http://localhost || exit 1

CMD ["/bin/zsh"]
