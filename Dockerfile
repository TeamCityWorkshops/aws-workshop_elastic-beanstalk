FROM composer:1.6.5 AS composer
FROM php:7.2-apache

RUN apt-get update && apt-get install -y  \
         zlib1g-dev libpng-dev libcurl4-openssl-dev pkg-config libssl-dev git zip supervisor
RUN docker-php-ext-install pdo_mysql
RUN apt-get update && apt-get install -y \
         libpng-dev libcurl4-openssl-dev pkg-config libssl-dev openssl git zip supervisor
RUN docker-php-ext-install curl

RUN rm -f /etc/apache2/sites-available/000-default.conf
COPY ./.ci/000-default.conf /etc/apache2/sites-available/
RUN a2enmod rewrite

COPY --chown=www-data:www-data . /var/www/html

COPY --from=composer /usr/bin/composer /usr/bin/composer
COPY composer.json composer.lock ./
RUN composer install \
                --no-autoloader \
                --no-scripts \
                --no-progress \
                --no-suggest \
                --ansi \
                --no-dev \
                && composer clear-cache --ansi

RUN chown www-data:www-data *
RUN composer dump-autoload



RUN touch /var/www/html/storage/logs/laravel.log
RUN chmod -R 777 /var/www/html/storage

HEALTHCHECK --interval=5s --timeout=1s \
  CMD curl --user-agent "Docker HEALTHCHECK" --fail http://localhost || exit 1

COPY ./.ci/supervisord.conf /etc/supervisor/conf.d/

#CMD php artisan serve --host=0.0.0.0 --port=8000
EXPOSE 80