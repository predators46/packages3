#
# Copyright (C) 2006-2016 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_NAME:=php
PKG_VERSION:=5.6.40
PKG_RELEASE:=1

PKG_MAINTAINER:=W. Michael Petullo <mike@flyn.org>, Michael Heimpold <mhei@heimpold.de>

PKG_LICENSE:=PHPv3.01
PKG_LICENSE_FILES:=LICENSE

PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.xz
PKG_SOURCE_URL:=http://www.php.net/distributions/
PKG_MD5SUM:=c7dde3afb16ce7b761abf2805125d372

PKG_FIXUP:=libtool autoreconf
PKG_BUILD_PARALLEL:=1
PKG_USE_MIPS16:=0

PHP5_MODULES = \
	calendar ctype curl \
	bcmath \
	fileinfo \
	dom \
	exif \
	ftp \
	gettext gd gmp \
	hash \
	iconv imap intl \
	json \
	ldap \
	mbstring mcrypt mysql mysqli mysqlnd \
	opcache openssl \
	pcntl pdo pdo-mysql pdo-pgsql pdo-sqlite pgsql phar \
	session shmop simplexml snmp soap sockets sqlite3 sysvmsg sysvsem sysvshm \
	tokenizer \
	xml xmlreader xmlwriter zip \

PKG_CONFIG_DEPENDS:= \
	$(patsubst %,CONFIG_PACKAGE_php5-mod-%,$(PHP5_MODULES)) \
	CONFIG_PHP5_FILTER CONFIG_PHP5_LIBXML CONFIG_PHP5_SYSTEMTZDATA CONFIG_PACKAGE_apache-mod-php5

include $(INCLUDE_DIR)/package.mk
include $(INCLUDE_DIR)/nls.mk

define Package/php5/Default
  SUBMENU:=PHP
  SECTION:=lang
  CATEGORY:=Languages
  TITLE:=PHP5 Hypertext preprocessor
  URL:=http://www.php.net/
  DEPENDS:=php5
endef

define Package/php5/Default/description
  PHP is a widely-used general-purpose scripting language that is especially
  suited for Web development and can be embedded into HTML.
endef

define Package/php5/config
	config PHP5_FILTER
		bool "PHP5 Filter support"
		depends on PACKAGE_php5-cli || PACKAGE_php5-cgi
		default y

	config PHP5_LIBXML
		bool "PHP5 LIBXML support"
		depends on PACKAGE_php5-cli || PACKAGE_php5-cgi

	config PHP5_SYSTEMTZDATA
		bool "Use system timezone data instead of php's built-in database"
		depends on PACKAGE_php5-cli || PACKAGE_php5-cgi || PACKAGE_apache-mod-php5
		default y
		help
			Enabling this feature automatically selects the zoneinfo-core package
			which contains data for UTC timezone. To use other timezones you have
			to install the corresponding zoneinfo-... package(s).
endef

define Package/php5
  $(call Package/php5/Default)

  DEPENDS:=+libpcre +zlib \
           +PHP5_LIBXML:libxml2 \
           +PHP5_SYSTEMTZDATA:zoneinfo-core
endef

define Package/php5/description
  $(call Package/php5/Default/description)
  This package contains only the PHP config file. You must actually choose
  your PHP flavour (cli, cgi or fastcgi).
endef

define Package/php5-cli
  $(call Package/php5/Default)
  DEPENDS+= +PACKAGE_php5-mod-intl:libstdcpp
  TITLE+= (CLI)
endef

define Package/php5-cli/description
  $(call Package/php5/Default/description)
  This package contains the CLI version of the PHP5 interpreter.
endef

define Package/php5-cgi
  $(call Package/php5/Default)
  DEPENDS+= +PACKAGE_php5-mod-intl:libstdcpp
  TITLE+= (CGI & FastCGI)
endef

define Package/php5-cgi/description
  $(call Package/php5/Default/description)
  This package contains the CGI version of the PHP5 interpreter.
endef

define Package/php5-fastcgi
  $(call Package/php5/Default)
  DEPENDS+= +php5-cgi
  TITLE:=FastCGI startup script
endef

define Package/php5-fastcgi/description
  As FastCGI support is now a core feature the php5-fastcgi package now depends
  on the php5-cgi package, containing just the startup script.
endef

define Package/php5-fpm
  $(call Package/php5/Default)
  DEPENDS+= +PACKAGE_php5-mod-intl:libstdcpp
  TITLE+= (FPM)
endef

define Package/php5-fpm/description
  $(call Package/php5/Default/description)
  This package contains the FastCGI Process Manager of the PHP5 interpreter.
endef

define Package/php5-mod-intl/config
  config PHP5_FULLICUDATA
	bool "Add dependency to full ICU Data"
	depends on PACKAGE_php5-mod-intl
	default n
endef

define Package/php5-mod-intl/description
  Note that this package depends in ICU library which is built without data
  by default. This is to satisfy programs build and run dependencies but to
  keep the installed footprint small on the target system(s).
  However, the data is required to make the ICU library useful - and thus
  directly affects PHPs ICU extension, too - so consider to also
  select/install package 'icu-full-data'.
endef

define Package/apache-mod-php5
  $(call Package/php5/Default)
  SUBMENU:=Web Servers/Proxies
  SECTION:=net
  CATEGORY:=Network
  DEPENDS+=PACKAGE_apache-mod-php5:apache \
	   +PACKAGE_php5-mod-intl:libstdcpp \
	   +libpcre2 +zlib
  TITLE:=PHP5 module for Apache Web Server
endef

define Package/apache-mod-php5/description
  $(call Package/php5/Default/description)
  This package contains the PHP module for the Apache Web Server.
endef

CONFIGURE_ARGS+= \
	--enable-cli \
	--enable-cgi \
	--enable-fpm \
	--enable-shared \
	--disable-static \
	--disable-rpath \
	--disable-debug \
	--without-pear \
	\
	--with-config-file-path=/etc \
	--with-config-file-scan-dir=/etc/php5 \
	--disable-short-tags \
	\
	--with-zlib="$(STAGING_DIR)/usr" \
	  --with-zlib-dir="$(STAGING_DIR)/usr" \
	--with-pcre-regex="$(STAGING_DIR)/usr"

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-calendar),)
  CONFIGURE_ARGS+= --enable-calendar=shared
else
  CONFIGURE_ARGS+= --disable-calendar
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-ctype),)
  CONFIGURE_ARGS+= --enable-ctype=shared
else
  CONFIGURE_ARGS+= --disable-ctype
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-curl),)
  CONFIGURE_ARGS+= --with-curl=shared,"$(STAGING_DIR)/usr"
else
  CONFIGURE_ARGS+= --without-curl
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-bcmath),)
  CONFIGURE_ARGS+= --enable-bcmath=shared
else
  CONFIGURE_ARGS+= --disable-bcmath
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-fileinfo),)
  CONFIGURE_ARGS+= --enable-fileinfo=shared
else
  CONFIGURE_ARGS+= --disable-fileinfo
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-gettext),)
  CONFIGURE_ARGS+= --with-gettext=shared,"$(STAGING_DIR)/usr/lib/libintl-full"
else
  CONFIGURE_ARGS+= --without-gettext
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-dom),)
  CONFIGURE_ARGS+= --enable-dom=shared
else
  CONFIGURE_ARGS+= --disable-dom
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-exif),)
  CONFIGURE_ARGS+= --enable-exif=shared
else
  CONFIGURE_ARGS+= --disable-exif
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-ftp),)
  CONFIGURE_ARGS+= --enable-ftp=shared
else
  CONFIGURE_ARGS+= --disable-ftp
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-gd),)
  CONFIGURE_ARGS+= \
	--with-gd=shared \
	--with-freetype-dir="$(STAGING_DIR)/usr" \
	--with-jpeg-dir="$(STAGING_DIR)/usr" \
	--with-png-dir="$(STAGING_DIR)/usr" \
	--without-xpm-dir \
	--enable-gd-native-ttf \
	--disable-gd-jis-conv
else
  CONFIGURE_ARGS+= --without-gd
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-gmp),)
  CONFIGURE_ARGS+= --with-gmp=shared,"$(STAGING_DIR)/usr"
else
  CONFIGURE_ARGS+= --without-gmp
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-hash),)
  CONFIGURE_ARGS+= --enable-hash=shared
else
  CONFIGURE_ARGS+= --disable-hash
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-iconv),)
  CONFIGURE_ARGS+= --with-iconv=shared,"$(ICONV_PREFIX)"
else
  CONFIGURE_ARGS+= --without-iconv
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-imap),)
  CONFIGURE_ARGS+= \
	--with-imap=shared,"$(STAGING_DIR)/usr" \
	--with-kerberos=no \
	--with-imap-ssl="$(STAGING_DIR)/usr"
else
  CONFIGURE_ARGS+= --without-imap
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-intl),)
  CONFIGURE_ARGS+= --enable-intl=shared
else
  CONFIGURE_ARGS+= --disable-intl
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-json),)
  CONFIGURE_ARGS+= --enable-json=shared
else
  CONFIGURE_ARGS+= --disable-json
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-ldap),)
  CONFIGURE_ARGS+= \
	--with-ldap=shared,"$(STAGING_DIR)/usr" \
	--with-ldap-sasl="$(STAGING_DIR)/usr"
else
  CONFIGURE_ARGS+= --without-ldap
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-mbstring),)
  CONFIGURE_ARGS+= --enable-mbstring=shared --enable-mbregex
else
  CONFIGURE_ARGS+= --disable-mbstring
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-mcrypt),)
  CONFIGURE_ARGS+= --with-mcrypt=shared,"$(STAGING_DIR)/usr"
else
  CONFIGURE_ARGS+= --without-mcrypt
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-mysql),)
  CONFIGURE_ARGS+= --with-mysql=shared,"$(STAGING_DIR)/usr"
else
  CONFIGURE_ARGS+= --without-mysql
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-mysqli),)
  CONFIGURE_ARGS+= --with-mysqli=shared
else
  CONFIGURE_ARGS+= --without-mysqli
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-mysqlnd),)
  CONFIGURE_ARGS+= --enable-mysqlnd=shared
else
  CONFIGURE_ARGS+= --disable-mysqlnd
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-opcache),)
  CONFIGURE_ARGS+= --enable-opcache=shared
else
  CONFIGURE_ARGS+= --disable-opcache
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-openssl)$(CONFIG_PACKAGE_php5-mod-ftp)$(CONFIG_PACKAGE_php5-mod-imap)$(CONFIG_PACKAGE_php5-mod-snmp),)
  CONFIGURE_ARGS+= \
	--with-openssl=shared,"$(STAGING_DIR)/usr" \
	--with-kerberos=no \
	--with-openssl-dir="$(STAGING_DIR)/usr"
else
  CONFIGURE_ARGS+= --without-openssl
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-pcntl),)
  CONFIGURE_ARGS+= --enable-pcntl=shared
else
  CONFIGURE_ARGS+= --disable-pcntl
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-pdo),)
  CONFIGURE_ARGS+= --enable-pdo=shared
  ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-pdo-mysql),)
    CONFIGURE_ARGS+= --with-pdo-mysql=shared
  else
    CONFIGURE_ARGS+= --without-pdo-mysql
  endif
  ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-pdo-pgsql),)
    CONFIGURE_ARGS+= --with-pdo-pgsql=shared,"$(STAGING_DIR)/usr"
  else
    CONFIGURE_ARGS+= --without-pdo-pgsql
  endif
  ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-pdo-sqlite),)
    CONFIGURE_ARGS+= --with-pdo-sqlite=shared,"$(STAGING_DIR)/usr"
  else
    CONFIGURE_ARGS+= --without-pdo-sqlite
  endif
else
  CONFIGURE_ARGS+= --disable-pdo
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-pgsql),)
  CONFIGURE_ARGS+= --with-pgsql=shared,"$(STAGING_DIR)/usr"
else
  CONFIGURE_ARGS+= --without-pgsql
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-phar),)
  CONFIGURE_ARGS+= --enable-phar=shared
else
  CONFIGURE_ARGS+= --disable-phar
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-session),)
  CONFIGURE_ARGS+= --enable-session=shared
else
  CONFIGURE_ARGS+= --disable-session
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-shmop),)
  CONFIGURE_ARGS+= --enable-shmop=shared
else
  CONFIGURE_ARGS+= --disable-shmop
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-simplexml),)
  CONFIGURE_ARGS+= --enable-simplexml=shared
else
  CONFIGURE_ARGS+= --disable-simplexml
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-snmp),)
  CONFIGURE_ARGS+= --with-snmp=shared,"$(STAGING_DIR)/usr"
else
  CONFIGURE_ARGS+= --without-snmp
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-soap),)
  CONFIGURE_ARGS+= --enable-soap=shared
else
  CONFIGURE_ARGS+= --disable-soap
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-sockets),)
  CONFIGURE_ARGS+= --enable-sockets=shared
else
  CONFIGURE_ARGS+= --disable-sockets
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-sqlite3),)
  CONFIGURE_ARGS+= --with-sqlite3=shared,"$(STAGING_DIR)/usr"
else
  CONFIGURE_ARGS+= --without-sqlite3
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-sysvmsg),)
  CONFIGURE_ARGS+= --enable-sysvmsg=shared
else
  CONFIGURE_ARGS+= --disable-sysvmsg
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-sysvsem),)
  CONFIGURE_ARGS+= --enable-sysvsem=shared
else
  CONFIGURE_ARGS+= --disable-sysvsem
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-sysvshm),)
  CONFIGURE_ARGS+= --enable-sysvshm=shared
else
  CONFIGURE_ARGS+= --disable-sysvshm
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-tokenizer),)
  CONFIGURE_ARGS+= --enable-tokenizer=shared
else
  CONFIGURE_ARGS+= --disable-tokenizer
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-xml),)
  CONFIGURE_ARGS+= --enable-xml=shared,"$(STAGING_DIR)/usr"
  ifneq ($(CONFIG_PHP5_LIBXML),)
    CONFIGURE_ARGS+= --with-libxml-dir="$(STAGING_DIR)/usr/include/libxml2"
  else
    CONFIGURE_ARGS+= --with-libexpat-dir="$(STAGING_DIR)/usr"
  endif
else
  CONFIGURE_ARGS+= --disable-xml
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-xmlreader),)
  CONFIGURE_ARGS+= --enable-xmlreader=shared,"$(STAGING_DIR)/usr"
else
  CONFIGURE_ARGS+= --disable-xmlreader
endif

ifneq ($(SDK)$(CONFIG_PACKAGE_php5-mod-xmlwriter),)
  CONFIGURE_ARGS+= --enable-xmlwriter=shared,"$(STAGING_DIR)/usr"
else
  CONFIGURE_ARGS+= --disable-xmlwriter
endif

ifneq ($(CONFIG_PACKAGE_php5-mod-zip),)
  CONFIGURE_ARGS+= --enable-zip=shared
else
  CONFIGURE_ARGS+= --disable-zip
endif

ifneq ($(SDK)$(CONFIG_PHP5_FILTER),)
  CONFIGURE_ARGS+= --enable-filter
else
  CONFIGURE_ARGS+= --disable-filter
endif

ifneq ($(SDK)$(CONFIG_PHP5_LIBXML),)
  CONFIGURE_ARGS+= --enable-libxml
  CONFIGURE_ARGS+= --with-libxml-dir="$(STAGING_DIR)/usr/include/libxml2"
else
  CONFIGURE_ARGS+= --disable-libxml
endif

ifneq ($(CONFIG_PHP5_SYSTEMTZDATA),)
  CONFIGURE_ARGS+= --with-system-tzdata
else
  CONFIGURE_ARGS+= --without-system-tzdata
endif

ifneq ($(CONFIG_PACKAGE_apache-mod-php5),)
  CONFIGURE_ARGS+= --with-apxs2=$(STAGING_DIR)/usr/bin/apxs
endif

CONFIGURE_VARS+= \
	ac_cv_c_bigendian_php=$(if $(CONFIG_BIG_ENDIAN),yes,no) \
	php_cv_cc_rpath="no" \
	iconv_impl_name="gnu_libiconv" \
	ac_cv_php_xml2_config_path="$(STAGING_DIR)/host/bin/xml2-config" \

define Package/php5/conffiles
/etc/php.ini
endef

define Package/php5/install
	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DATA) ./files/php.ini $(1)/etc/
endef

define Package/php5-cli/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) $(PKG_BUILD_DIR)/sapi/cli/php $(1)/usr/bin/php-cli
endef

define Package/php5-cgi/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(CP) $(PKG_BUILD_DIR)/sapi/cgi/php-cgi $(1)/usr/bin/php-cgi
	ln -sf php-cgi $(1)/usr/bin/php-fcgi
endef

define Package/php5-fastcgi/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/php5-fastcgi.config $(1)/etc/config/php5-fastcgi

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/php5-fastcgi.init $(1)/etc/init.d/php5-fastcgi
endef

define Package/php5-fpm/install
	$(INSTALL_DIR) $(1)/usr/bin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/sapi/fpm/php-fpm $(1)/usr/bin/php-fpm

	$(INSTALL_DIR) $(1)/etc
	$(INSTALL_DATA) ./files/php5-fpm.conf $(1)/etc/php5-fpm.conf

	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/php5-fpm.config $(1)/etc/config/php5-fpm

	$(INSTALL_DIR) $(1)/etc/php5-fpm.d
	$(INSTALL_DATA) ./files/php5-fpm-www.conf $(1)/etc/php5-fpm.d/www.conf

	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/php5-fpm.init $(1)/etc/init.d/php5-fpm
endef

define Package/apache-mod-php5/install
	$(INSTALL_DIR) $(1)/usr/lib/apache2
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/libs/libphp5.so $(1)/usr/lib/apache2
endef

define Build/Prepare
	$(call Build/Prepare/Default)
	( cd $(PKG_BUILD_DIR); touch configure.in; ./buildconf --force )
endef

define Build/InstallDev
	mkdir -p $(PKG_BUILD_DIR)/staging/usr/bin
	make -C $(PKG_BUILD_DIR) install INSTALL_ROOT=$(PKG_BUILD_DIR)/staging
	rm -f $(PKG_BUILD_DIR)/staging/usr/bin/php
	$(CP) $(PKG_BUILD_DIR)/staging/* $(STAGING_DIR_HOST)
	sed -i -e "s#prefix='/usr'#prefix='$(STAGING_DIR_HOST)/usr'#" $(STAGING_DIR_HOST)/usr/bin/phpize
	sed -i -e "s#exec_prefix=\"\`eval echo /usr\`\"#exec_prefix='$(STAGING_DIR_HOST)/usr'#" $(STAGING_DIR_HOST)/usr/bin/phpize
	sed -i -e "s#prefix=\"/usr\"#prefix=\"$(STAGING_DIR_HOST)/usr\"#" $(STAGING_DIR_HOST)/usr/bin/php-config
endef

define BuildModule

  define Package/php5-mod-$(1)
    $(call Package/php5/Default)

    ifneq ($(3),)
      DEPENDS+=$(3)
    endif

    TITLE:=$(2) shared module
  endef

  define Package/php5-mod-$(1)/install
	$(INSTALL_DIR) $$(1)/usr/lib/php
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/modules/$(subst -,_,$(1)).so $$(1)/usr/lib/php/
	$(INSTALL_DIR) $$(1)/etc/php5
      ifeq ($(4),zend)
	echo "zend_extension=/usr/lib/php/$(subst -,_,$(1)).so" > $$(1)/etc/php5/$(subst -,_,$(1)).ini
      else
	echo "extension=$(subst -,_,$(1)).so" > $$(1)/etc/php5/$(subst -,_,$(1)).ini
    endif
  endef

  $$(eval $$(call BuildPackage,php5-mod-$(1)))

endef

$(eval $(call BuildPackage,php5))
$(eval $(call BuildPackage,php5-cgi))
$(eval $(call BuildPackage,php5-cli))
$(eval $(call BuildPackage,php5-fastcgi))
$(eval $(call BuildPackage,php5-fpm))
$(eval $(call BuildPackage,apache-mod-php5))

#$(eval $(call BuildModule,NAME,TITLE[,PKG DEPENDS]))
$(eval $(call BuildModule,calendar,Calendar))
$(eval $(call BuildModule,ctype,Ctype))
$(eval $(call BuildModule,curl,cURL,+PACKAGE_php5-mod-curl:libcurl))
$(eval $(call BuildModule,dom,DOM,+@PHP5_LIBXML +PACKAGE_php5-mod-dom:libxml2))
$(eval $(call BuildModule,exif,EXIF))
$(eval $(call BuildModule,bcmath,Bcmath))
$(eval $(call BuildModule,fileinfo,Fileinfo))
$(eval $(call BuildModule,ftp,FTP,+PACKAGE_php5-mod-ftp:libopenssl))
$(eval $(call BuildModule,gd,GD graphics,+PACKAGE_php5-mod-gd:libjpeg +PACKAGE_php5-mod-gd:libpng +PACKAGE_php5-mod-gd:libfreetype))
$(eval $(call BuildModule,gettext,Gettext,+PACKAGE_php5-mod-gettext:libintl-full))
$(eval $(call BuildModule,gmp,GMP,+PACKAGE_php5-mod-gmp:libgmp))
$(eval $(call BuildModule,hash,Hash))
$(eval $(call BuildModule,iconv,iConv,$(ICONV_DEPENDS)))
$(eval $(call BuildModule,imap,IMAP,+PACKAGE_php5-mod-imap:libopenssl +PACKAGE_libpam:libpam +PACKAGE_php5-mod-imap:uw-imap))
$(eval $(call BuildModule,intl,Internationalization Functions,+PACKAGE_php5-mod-intl:icu +PHP5_FULLICUDATA:icu-full-data))
$(eval $(call BuildModule,json,JSON))
$(eval $(call BuildModule,ldap,LDAP,+PACKAGE_php5-mod-ldap:libopenldap +PACKAGE_php5-mod-ldap:libsasl2))
$(eval $(call BuildModule,mbstring,MBString))
$(eval $(call BuildModule,mcrypt,Mcrypt,+PACKAGE_php5-mod-mcrypt:libmcrypt +PACKAGE_php5-mod-mcrypt:libltdl))
$(eval $(call BuildModule,mysql,MySQL,+PACKAGE_php5-mod-mysql:libmysqlclient))
$(eval $(call BuildModule,mysqli,MySQL Improved Extension,+PACKAGE_php5-mod-mysqli:php5-mod-mysqlnd))
$(eval $(call BuildModule,mysqlnd,MySQL Native Driver,+PACKAGE_php5-mod-openssl:php5-mod-openssl))
$(eval $(call BuildModule,opcache,OPcache,,zend))
$(eval $(call BuildModule,openssl,OpenSSL,+PACKAGE_php5-mod-openssl:libopenssl))
$(eval $(call BuildModule,pcntl,PCNTL))
$(eval $(call BuildModule,pdo,PHP Data Objects))
$(eval $(call BuildModule,pdo-mysql,PDO driver for MySQL,+php5-mod-pdo +PACKAGE_php5-mod-pdo-mysql:php5-mod-mysqlnd))
$(eval $(call BuildModule,pdo-pgsql,PDO driver for PostgreSQL,+php5-mod-pdo +PACKAGE_php5-mod-pdo-pgsql:libpq))
$(eval $(call BuildModule,pdo-sqlite,PDO driver for SQLite 3.x,+php5-mod-pdo +PACKAGE_php5-mod-pdo-sqlite:libsqlite3 +PACKAGE_php5-mod-pdo-sqlite:librt))
$(eval $(call BuildModule,pgsql,PostgreSQL,+PACKAGE_php5-mod-pgsql:libpq))
$(eval $(call BuildModule,phar,Phar Archives))
$(eval $(call BuildModule,session,Session))
$(eval $(call BuildModule,shmop,Shared Memory))
$(eval $(call BuildModule,simplexml,SimpleXML,+@PHP5_LIBXML +PACKAGE_php5-mod-simplexml:libxml2))
$(eval $(call BuildModule,snmp,SNMP,+PACKAGE_php5-mod-snmp:libnetsnmp +PACKAGE_php5-mod-snmp:libopenssl))
$(eval $(call BuildModule,soap,SOAP,+@PHP5_LIBXML +PACKAGE_php5-mod-soap:libxml2))
$(eval $(call BuildModule,sockets,Sockets))
$(eval $(call BuildModule,sqlite3,SQLite3,+PACKAGE_php5-mod-sqlite3:libsqlite3))
$(eval $(call BuildModule,sysvmsg,System V messages))
$(eval $(call BuildModule,sysvsem,System V shared memory))
$(eval $(call BuildModule,sysvshm,System V semaphore))
$(eval $(call BuildModule,tokenizer,Tokenizer))
$(eval $(call BuildModule,xml,XML,+PHP5_LIBXML:libxml2 +!PHP5_LIBXML:libexpat))
$(eval $(call BuildModule,xmlreader,XMLReader,+@PHP5_LIBXML +PACKAGE_php5-mod-xmlreader:libxml2))
$(eval $(call BuildModule,xmlwriter,XMLWriter,+@PHP5_LIBXML +PACKAGE_php5-mod-xmlwriter:libxml2))
$(eval $(call BuildModule,zip,ZIP,+PACKAGE_php5-mod-zip:zlib))
