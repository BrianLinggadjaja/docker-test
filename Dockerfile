FROM ubuntu:18.04

# ENV available before and after buildtime
ENV APACHE_DOCUMENT_ROOT /var/www/html/public

# ARG only available during buildtime
ARG GIT_REPO=https://github.com/csuntechlab/affinity.git
ARG DEBIAN_FRONTEND=noninteractive

# Update & Upgrade base distro
RUN apt-get update; \
    apt-get -y upgrade 

# Install toolkit
RUN apt-get install -y git \
    vim \
    curl \
    zip \
    unzip

# Install services
RUN apt-get install -y apache2 \
    mysql-client \
    php \
        # Php service dependencies
        libapache2-mod-php php-mysql php7.2-cli php7.2-curl php7.2-gd php7.2-mbstring php7.2-mysql php7.2-xml php-xml

# Repository setup
RUN git clone ${GIT_REPO} /var/www/html/affinity; \
    chown -hR www-data:www-data /var/www/html/affinity

# Sym-link public distribution
RUN cd '/var/www/html/'; \
    ln -s /var/www/html/affinity/public public

# Install back-end dependancies via composer
RUN cd '/var/www/html/affinity'; \
    curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
    composer install --ignore-platform-reqs

# Configure apache2 dir.conf
RUN sed -i 's|index.html|replace|g; s|index.php|index.html|g; s|replace|index.php|g' /etc/apache2/mods-enabled/dir.conf

# Configure apache2.conf
RUN sed -i "162 s|denied|granted|g; 170 s|/var/www|${APACHE_DOCUMENT_ROOT}|g" /etc/apache2/apache2.conf

# Configure apache2 sites-available
RUN sed -i "s|/var/www/html|${APACHE_DOCUMENT_ROOT}|g" /etc/apache2/sites-available/000-default.conf

# Start web-server after process complete
EXPOSE 80
CMD apachectl -D FOREGROUND
