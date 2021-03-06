<?php
$var = getopt('', ['version:', 'dockerfile:']);
$isAlpineImage = $var['dockerfile'] === 'alpine';
$AlpineRepoCommit = '3b749b4a926cd6db8c9f9f65b71d2f94e3fb08e5';
?>
# AUTOMATICALLY GENERATED
# DO NOT EDIT THIS FILE DIRECTLY, USE /Dockerfile.tmpl.php

<? if ($isAlpineImage) { ?>
# https://hub.docker.com/_/alpine
FROM alpine:3.13
<? } else { ?>
# https://hub.docker.com/_/debian
FROM debian:jessie-slim
<? } ?>

ARG opendkim_ver=<?= explode('-', $var['version'])[0]."\n"; ?>
ARG opendkim_sum=<?= "97923e533d072c07ae4d16a46cbed95ee799aa50f19468d8bc6d1dc534025a8616c3b4b68b5842bc899b509349a2c9a67312d574a726b048c0ea46dd4fcc45d8\n"; ?>
ARG s6_overlay_ver=2.2.0.3

LABEL org.opencontainers.image.source="\
    https://github.com/instrumentisto/opendkim-docker-image"


# Build and install OpenDKIM
<? if ($isAlpineImage) { ?>
# https://git.alpinelinux.org/cgit/aports/tree/community/opendkim/APKBUILD?h=<?= $AlpineRepoCommit."\n"; ?>
RUN apk update \
 && apk upgrade \
 && apk add --no-cache \
        ca-certificates \
<? } else { ?>
RUN apt-get update \
 && apt-get upgrade -y \
 && apt-get install -y --no-install-recommends --no-install-suggests \
            inetutils-syslogd \
            ca-certificates \
<? } ?>
 && update-ca-certificates \
    \
 # Install OpenDKIM dependencies
<? if ($isAlpineImage) { ?>
 && apk add --no-cache \
        libressl3.1-libcrypto libressl3.1-libssl \
        libmilter \
        # Perl and LibreSSL required for opendkim-* utilities
        libressl perl \
 # Add openssl symlink to libressl to fix incompatibility with OpenDKIM
 # since Alpine 3.11
 && ln -sf /usr/bin/libressl /usr/bin/openssl \
<? } else { ?>
 && apt-get install -y --no-install-recommends --no-install-suggests \
            libssl1.0.0 \
            libmilter1.0.1 \
            libbsd0 \
<? } ?>
    \
 # Install tools for building
<? if ($isAlpineImage) { ?>
 && apk add --no-cache --virtual .tool-deps \
        curl coreutils autoconf g++ libtool make \
<? } else { ?>
 && toolDeps=" \
        curl make gcc g++ libc-dev \
    " \
 && apt-get install -y --no-install-recommends --no-install-suggests \
            $toolDeps \
<? } ?>
    \
 # Install OpenDKIM build dependencies
<? if ($isAlpineImage) { ?>
 && apk add --no-cache --virtual .build-deps \
        libressl-dev \
        libmilter-dev \
<? } else { ?>
 && buildDeps=" \
        libssl-dev \
        libmilter-dev \
        libbsd-dev \
    " \
 && apt-get install -y --no-install-recommends --no-install-suggests \
            $buildDeps \
<? } ?>
    \
 # Download and prepare OpenDKIM sources
 && curl -fL -o /tmp/opendkim.tar.gz \
         https://downloads.sourceforge.net/project/opendkim/opendkim-${opendkim_ver}.tar.gz \
 && (echo "${opendkim_sum}  /tmp/opendkim.tar.gz" \
         | sha512sum -c -) \
 && tar -xzf /tmp/opendkim.tar.gz -C /tmp/ \
 && cd /tmp/opendkim-* \
    \
 # Build OpenDKIM from sources
 && ./configure \
        --prefix=/usr \
        --sysconfdir=/etc/opendkim \
        # No documentation included to keep image size smaller
        --docdir=/tmp/opendkim/doc \
        --htmldir=/tmp/opendkim/html \
        --infodir=/tmp/opendkim/info \
        --mandir=/tmp/opendkim/man \
 && make \
    \
 # Create OpenDKIM user and group
<? if ($isAlpineImage) { ?>
 && addgroup -S -g 91 opendkim \
 && adduser -S -u 90 -D -s /sbin/nologin \
            -H -h /run/opendkim \
            -G opendkim -g opendkim \
            opendkim \
 && addgroup opendkim mail \
<? } else { ?>
 && addgroup --system --gid 91 opendkim \
 && adduser --system --uid 90 --disabled-password --shell /sbin/nologin \
            --no-create-home --home /run/opendkim \
            --ingroup opendkim --gecos opendkim \
            opendkim \
 && adduser opendkim mail \
<? } ?>
    \
 # Install OpenDKIM
 && make install \
 # Prepare run directory
 && install -d -o opendkim -g opendkim /run/opendkim/ \
 # Preserve licenses
 && install -d /usr/share/licenses/opendkim/ \
 && mv /tmp/opendkim/doc/LICENSE* \
       /usr/share/licenses/opendkim/ \
 # Prepare configuration directories
 && install -d /etc/opendkim/conf.d/ \
    \
 # Cleanup unnecessary stuff
<? if ($isAlpineImage) { ?>
 && apk del .tool-deps .build-deps \
 && rm -rf /var/cache/apk/* \
<? } else { ?>
 && apt-get purge -y --auto-remove \
                  -o APT::AutoRemove::RecommendsImportant=false \
            $toolDeps $buildDeps \
 && rm -rf /var/lib/apt/lists/* \
           /etc/*/inetutils-syslogd \
<? } ?>
           /tmp/*


# Install s6-overlay
<? if ($isAlpineImage) { ?>
RUN apk add --update --no-cache --virtual .tool-deps \
        curl \
<? } else { ?>
RUN apt-get update \
 && apt-get install -y --no-install-recommends --no-install-suggests \
            curl \
<? } ?>
 && curl -fL -o /tmp/s6-overlay.tar.gz \
         https://github.com/just-containers/s6-overlay/releases/download/v${s6_overlay_ver}/s6-overlay-amd64.tar.gz \
 && tar -xzf /tmp/s6-overlay.tar.gz -C / \
    \
 # Cleanup unnecessary stuff
<? if ($isAlpineImage) { ?>
 && apk del .tool-deps \
 && rm -rf /var/cache/apk/* \
<? } else { ?>
 && apt-get purge -y --auto-remove \
                  -o APT::AutoRemove::RecommendsImportant=false \
            curl \
 && rm -rf /var/lib/apt/lists/* \
<? } ?>
           /tmp/*

ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2 \
    S6_CMD_WAIT_FOR_SERVICES=1


COPY rootfs /

RUN chmod +x /etc/services.d/*/run \
             /etc/cont-init.d/*


EXPOSE 8891

ENTRYPOINT ["/init"]

CMD ["opendkim", "-f"]
