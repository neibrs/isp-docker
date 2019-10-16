FROM drupal:fpm-alpine
#RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g' /etc/apk/repositories
RUN set -eux; \
	\
	apk add --no-cache --virtual .build-deps \
		coreutils \
		freetype-dev \
		libjpeg-turbo-dev \
		libpng-dev \
		libzip-dev \
		postgresql-dev \
	; \
	\
	docker-php-ext-configure gd \
		--with-freetype-dir=/usr/include \
		--with-jpeg-dir=/usr/include \
		--with-png-dir=/usr/include \
	; \
	\
	docker-php-ext-install -j "$(nproc)" \
		gd \
		opcache \
		pdo_mysql \
		pdo_pgsql \
		zip \
		bcmath \
	; \
	\
	runDeps="$( \
		scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
			| tr ',' '\n' \
			| sort -u \
			| awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
	)"; \
	apk add --virtual .drupal-phpexts-rundeps $runDeps; \
	apk del .build-deps

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
RUN { \
		echo 'opcache.memory_consumption=128'; \
		echo 'opcache.interned_strings_buffer=8'; \
		echo 'opcache.max_accelerated_files=4000'; \
		echo 'opcache.revalidate_freq=60'; \
		echo 'opcache.fast_shutdown=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN apk update && \
  apk add git \
  unzip \
  wget

## Composer install
RUN php -r "copy('https://install.phpcomposer.com/installer', 'composer-setup.php');" && \
  php composer-setup.php && \
  php -r "unlink('composer-setup.php');" && \
  mv composer.phar /usr/local/bin/composer && \
  chmod a+x /usr/local/bin/composer

RUN ls /usr/bin
# Install Drupal
RUN rm -rf /var/www/html

RUN git clone -b 8.8.x https://git.keiu.cn/neibrs/drupal.git /var/www/html

WORKDIR /var/www/html
ENV COMPOSER_PROCESS_TIMEOUT 1200
RUN composer config -g repo.packagist composer https://mirrors.aliyun.com/composer/ && \
    composer install

RUN composer require \
  drupal/purge \
  drupal/config_rewrite \
  drupal/config_update \
  drupal/memcache \
  drupal/restui \
  drupal/page_manager \
  drupal/panels \
  drupal/panelizer \
#  drupal/csv_serialization \
  drupal/default_content \
  drupal/migrate_plus \
  drupal/migrate_source_csv \
  drupal/migrate_source_xls \
  drupal/migrate_tools \
  drupal/xls_serialization \
  drupal/entity_print \
  mikehaertl/phpwkhtmltopdf \
  drupal/charts \
  drupal/r4032login \
  drupal/address \
  drupal/ajax_links_api \
  drupal/block_style_plugins:dev-2.x \
  drupal/conditional_fields \
  drupal/custom_formatters \
  drupal/entity_browser \
  drupal/facets \
  drupal/features \
  drupal/field_formatter_class \
  drupal/field_group \
  drupal/inline_entity_form \
  drupal/pinyin \
  drupal/quicktabs \
  drupal/reference_table_formatter \
  drupal/rules \
#  drupal/search_api_solr \
  drupal/token \
  drupal/token_filter \
  drupal/views_field_formatter \
  drupal/ajax_links_api \
  drupal/varnish_purge \
  drupal/adminimal_admin_toolbar \
  drupal/coffee \
  drupal/color_field \
  drupal/commerce \
  drupal/commerce_recurring \
  drupal/drush_language \
  kgaut/potx \
  drupal/block_style_plugins \
  drupal/typed_data \
  drupal/geofield \
  drupal/baidu_map \
  drupal/geocoder \
  drupal/computed_field \
  drupal/geolocation \
  drupal/geocoder_autocomplete \
  drupal/block_class \
  drupal/ds \
  drupal/superfish \
  drupal/libraries \
  drupal/commerce_autosku \
  drupal/views_slideshow \
  drupal/views_slideshow_cycle \
  drupal/login_security \
  drupal/smart_ip \
  drupal/if_then_else

COPY files/settings.memcache.php /var/www/html/web/sites/default/settings.memcache.php
