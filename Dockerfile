FROM php:5.6-apache

RUN apt-get update && apt-get install -y \
	bzip2 \
	libcurl4-openssl-dev \
	libfreetype6-dev \
	libicu-dev \
	libjpeg-dev \
	libldap2-dev \
	libmcrypt-dev \
	libmemcached-dev \
	libpng12-dev \
	libpq-dev \
	libxml2-dev \
	&& rm -rf /var/lib/apt/lists/*

# https://doc.owncloud.org/server/8.1/admin_manual/installation/source_installation.html#prerequisites
RUN docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ \
	&& docker-php-ext-install exif gd intl ldap mbstring mcrypt mysql opcache pdo_mysql pdo_pgsql pgsql zip

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
	echo 'opcache.memory_consumption=128'; \
	echo 'opcache.interned_strings_buffer=8'; \
	echo 'opcache.max_accelerated_files=4000'; \
	echo 'opcache.revalidate_freq=60'; \
	echo 'opcache.fast_shutdown=1'; \
	echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

# PECL extensions
RUN set -ex \
	&& pecl install APCu-4.0.10 \
	&& pecl install memcached-2.2.0 \
	&& pecl install redis-2.2.8 \
	&& docker-php-ext-enable apcu memcached redis

# test
RUN openssl genrsa -out nextcloud.key 2048 \
	&& openssl req -new -key nextcloud.key -out nextcloud.csr -subj "/C=FR/ST=Toulouse/Toulouse/O=Perso/OU=IT Department/CN=example.com" \
	&& openssl x509 -req -days 365 -in nextcloud.csr -signkey nextcloud.key -out nextcloud.crt

RUN mv nextcloud.crt /etc/ssl/private \ 
	&& mv nextcloud.key /etc/ssl/private/ \
	&& mv nextcloud.csr /etc/ssl/private/


# fin test

ENV NEXTCLOUD_VERSION 10.0.1
VOLUME /var/www/html

RUN curl -fsSL -o nextcloud.tar.bz2 \
		"https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2" \
	&& curl -fsSL -o nextcloud.tar.bz2.asc \
		"https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2.asc" \
	#&& curl -fsSL -o nextcloud.asc "https://nextcloud.com/nextcloud.asc" \

	&& export GNUPGHOME="$(mktemp -d)" \

# gpg key from https://nextcloud.com/nextcloud.asc
	#&& gpg --import nextcloud.asc \
	
	#&& gpg --verify nextcloud.tar.bz2.asc nextcloud.tar.bz2 \

	&& gpg --keyserver ha.pool.sks-keyservers.net --recv-keys 28806A878AE423A28372792ED75899B9A724937A \
	&& gpg --batch --verify nextcloud.tar.bz2.asc nextcloud.tar.bz2 \
	&& rm -r "$GNUPGHOME" nextcloud.tar.bz2.asc \
	&& tar -xjf nextcloud.tar.bz2 -C /usr/src/ \
	&& rm nextcloud.tar.bz2

#RUN sed "s/);/\t\'forcessl\' => true,\n);/" < /var/www/html/nextcloud/config/conf.php > /var/www/html/nextcloud/config/config.php.new
#RUN mv /var/www/html/nextcloud/config/config.php.new /var/www/html/nextcloud/config/config.php

COPY docker-entrypoint.sh /entrypoint.sh

COPY nextcloud.conf /etc/apache2/sites-available/nextcloud.conf

RUN a2enmod ssl \
	&& a2ensite nextcloud.conf
RUN service apache2 restart

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]

