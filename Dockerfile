FROM php:5.5-apache

MAINTAINER Bruno Monteiro <babumsouza1@gmail.com>

ENV XDEBUG_PORT 9000

RUN apt-get update \
    && apt-get install -y php5-dev \
    php-pear \
    libpng12-dev \
    libmcrypt-dev \
    libmcrypt4 \
    libcurl3-dev \
    libfreetype6 \
    libjpeg62-turbo \
    libpng12-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    apt-utils \
    php5-gd \
    php5-mysql \
    mysql-client-5.5 \
    libxml2-dev \
    git \
    wget \
    zip \
    vim \
    gcc \
    make \
    autoconf \
    libc-dev \
    pkg-config \
	php-pear -y

RUN docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ \
    && docker-php-ext-install pdo \
    pdo_mysql \
    gd \
    mcrypt \
    mbstring \
    soap

RUN chmod 777 -R /var/www \
	&& chown -R www-data:1000 /var/www \
  	&& usermod -u 1000 www-data \
  	&& chsh -s /bin/bash www-data\
  	&& a2enmod rewrite \
	&& a2enmod headers \
    && php5enmod opcache \
	&& sed -i -e 's/\/var\/www\/html/public/\/var\/www\/htdocs/' /etc/apache2/apache2.conf

# Install oAuth
RUN apt-get update \
	&& pecl install oauth-1.2.3 \
	&& echo "extension=oauth.so" > /usr/local/etc/php/conf.d/docker-php-ext-oauth.ini

# Install Mhsendmail
RUN DEBIAN_FRONTEND=noninteractive apt-get -y install golang-go \
   && mkdir /opt/go \
   && export GOPATH=/opt/go \
   && go get github.com/mailhog/mhsendmail

# Install XDebug
#RUN yes | pecl install php5-xdebug \
#    && echo "zend_extension=$(find /usr/local/lib/php/extensions/ -name php5-xdebug.so)" > /usr/local/etc/php/conf.d/xdebug.iniOLD


# Install Modman
RUN wget https://raw.githubusercontent.com/colinmollenhour/modman/master/modman -O /usr/local/bin/modma

# SSH
# RUN apt-get update && apt-get install -y openssh-server openssh-client
# RUN mkdir /var/run/sshd
# RUN echo 'root:root' | chpasswd
# RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config

# RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# ENV NOTVISIBLE "in users profile"
# RUN echo "export VISIBLE=now" >> /etc/profile

# RUN /etc/init.d/apache2 restart

# Install Composer
RUN	curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer

# To SSH
# RUN /usr/sbin/sshd
# Configuring system

ADD .docker/config/php.ini /usr/local/etc/php/php.ini
ADD .docker/config/default.conf /etc/apache2/sites-available/default.conf
ADD .docker/config/custom-xdebug.ini /usr/local/etc/php/conf.d/custom-xdebug.ini
COPY .docker/bin/* /usr/local/bin/

RUN chmod +x /usr/local/bin/*
RUN ln -s /etc/apache2/sites-available/default.conf /etc/apache2/sites-enabled/default.conf

VOLUME ["/var/www/html"]
WORKDIR /var/www/html
COPY ./src /var/www/html

CMD ["apache2-foreground", "-DFOREGROUND"]