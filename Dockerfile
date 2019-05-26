FROM elixir:1.8-alpine

LABEL maintainer="OmiseGO Team <omg@omise.co>"
LABEL description="Potterhat"

ENV LANG=C.UTF-8
ENV MIX_ENV=prod
ENV HOME=/app

## S6
##

ENV S6_VERSION="1.21.4.0"

RUN set -xe \
 && apk add --update --no-cache --virtual .fetch-deps \
        curl \
        ca-certificates \
 && S6_DOWNLOAD_URL="https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-amd64.tar.gz" \
 && S6_DOWNLOAD_SHA256="e903f138dea67e75afc0f61e79eba529212b311dc83accc1e18a449d58a2b10c" \
 && curl -fsL -o s6-overlay.tar.gz "${S6_DOWNLOAD_URL}" \
 && echo "${S6_DOWNLOAD_SHA256}  s6-overlay.tar.gz" |sha256sum -c - \
 && tar -xzC / -f s6-overlay.tar.gz \
 && rm s6-overlay.tar.gz \
 && apk del .fetch-deps

## Application
##

RUN set -xe \
 && adduser -D -h /app app \
 && chown app:app /app

WORKDIR /app

COPY --chown=app mix.exs mix.lock ./

RUN set -xe \
 && s6-setuidgid app mix do \
      local.hex --force, \
      local.rebar --force, \
      deps.get, \
      deps.compile

COPY --chown=app apps ./apps
COPY --chown=app config ./config

RUN set -xe \
 && s6-setuidgid app mix compile

## Run
##

ENTRYPOINT ["/init"]

CMD ["s6-setuidgid", "app", "mix", "run", "--no-halt"]
