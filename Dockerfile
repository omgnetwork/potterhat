FROM ubuntu:18.04

LABEL maintainer="OmiseGO Team <omg@omise.co>"
LABEL description="Official image for OmiseGO Potterhat"

ENV LANG=C.UTF-8

## S6
##

ENV S6_VERSION="1.21.4.0"

RUN set -xe \
 && apt-get update \
 && apt-get install -y \
                    curl \
                    ca-certificates \
 && S6_DOWNLOAD_URL="https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-amd64.tar.gz" \
 && S6_DOWNLOAD_SHA256="e903f138dea67e75afc0f61e79eba529212b311dc83accc1e18a449d58a2b10c" \
 && curl -fsL -o s6-overlay.tar.gz "${S6_DOWNLOAD_URL}" \
 && echo "${S6_DOWNLOAD_SHA256}  s6-overlay.tar.gz" |sha256sum -c - \
 && tar -xzC / -f s6-overlay.tar.gz \
 && rm s6-overlay.tar.gz \
 && rm -rf /var/lib/apt/lists/*

## Application
##

RUN set -xe \
 && apt-get update \
 && apt-get install -y \
                    bash \
 && rm -rf /var/lib/apt/lists/*

COPY rootfs /

# USER directive is not being used here since privileges are dropped via
# s6-setuigid in /entrypoint. s6-overlay is required to be run as root.
ARG user=potterhat
ARG group=potterhat
ARG uid=10000
ARG gid=10000

RUN set -xe \
 && groupadd --gid "${gid}" "${group}" \
 && useradd \
      --uid ${uid} \
      --gid ${gid} \
      --home /app \
      --create-home \
      --shell /bin/bash \
      ${user} \
 && chown "${uid}:${gid}" "/app" \
 && chmod +x /entrypoint

ARG release_version

ADD _build/prod/rel/potterhat/releases/${release_version}/potterhat.tar.gz /app
RUN chown -R "${uid}:${gid}" /app
WORKDIR /app

# Potterhat is using PORT environment variable to determine which port to run
# the application server.
ENV PORT 4000

EXPOSE $PORT

# These are ports required for clustering. The range is defined in vm.args
# in inet_dist_listen_min and inet_dist_listen_max.
EXPOSE 4369 6900 6901 6902 6903 6904 6905 6906 6907 6908 6909

ENTRYPOINT ["/init", "/entrypoint"]

CMD ["foreground"]
