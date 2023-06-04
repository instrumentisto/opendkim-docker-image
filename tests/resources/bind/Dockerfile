FROM alpine:3.18
RUN apk update \
    && apk add --no-cache bind \
    && rm -rf /var/cache/apk/* \
    && mkdir -p /var/cache/bind \
    && chown -R named:named /var/cache/bind

CMD ["named", "-g", "-u", "named"]

EXPOSE 53


