FROM registry.embold.app/base:ubuntu22.04

USER root

ARG PHP_VERSION=8.1

RUN add-apt-repository -y ppa:ondrej/php && \
	add-apt-repository -y ppa:ondrej/apache2 && \
	apt-get update && \
	apt-get install -y -q --no-install-recommends \
	# Ruby for capistrano/pulsar
	ruby \
	ruby-dev \
	ruby-irb \
	ruby-rake \
	ruby-bigdecimal \
	# LAMP
	apache2 \
	dh-php \
	libapache2-mod-php${PHP_VERSION} \
	mariadb-client \
	php${PHP_VERSION} \
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
	&& rm -rf /var/lib/apt/lists/*

COPY --chown=embold:embold --chmod=774 coder /coder

RUN cd /coder \
	&& ln -s conf/embold-mysql.cnf /etc/mysql/conf.d/embold.cnf \
	&& ln -s conf/embold-php.ini /etc/php/${PHP_VERSION}/mods-available/embold.ini \
	&& cp conf/embold-apache.conf /etc/apache2/conf-available/embold.conf \
	&& rsync -a --delete /coder/conf/sites-available/ /etc/apache2/sites-available \
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
	# Ruby gems
	&& mkdir -p $GEM_HOME \
	&& gem install bundler colorls /coder/pulsar.gem \
	&& chown -R embold:embold $GEM_HOME \
	&& chmod -R 1777 $GEM_HOME \
	# Install wp-cli
	&& curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar \
	&& chmod +x wp-cli.phar \
	&& mv wp-cli.phar /usr/local/bin/wp

USER embold

CMD ["/bin/zsh"]
