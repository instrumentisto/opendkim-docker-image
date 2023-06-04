FROM alpine:3.18
RUN apk update && apk add --no-cache \
    postfix ca-certificates bind-tools \
    && rm -rf /var/cache/apk/*

CMD ["postfix", "start-fg"]

EXPOSE 25 465 587

