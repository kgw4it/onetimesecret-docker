# Dockerfile for One-Time Secret
# http://onetimesecret.com

FROM debian:stretch

MAINTAINER Dan Staples <dan@disman.tl>

# Install dependencies
RUN DEBIAN_FRONTEND=noninteractive \
  apt-get update && \
  apt-get install -y \
    ruby \
    ruby-dev \
    ruby-bundler \
    redis-server \
    curl \
    build-essential \
  && rm -rf /var/lib/apt/lists/*

# OTS pre-installation
RUN set -ex && \
  # Add ots user
  useradd -U -s /bin/false ots && \
  \
  # Create directories
  mkdir -p /etc/onetime /var/log/onetime /var/run/onetime /var/lib/onetime /var/lib/onetime/redis && \
  chown ots /etc/onetime /var/log/onetime /var/run/onetime /var/lib/onetime /var/lib/onetime/redis

USER ots

# Download and install latest OTS
RUN set -ex && \
  curl https://codeload.github.com/kgw4it/onetimesecret/legacy.tar.gz/master -o /tmp/ots.tar.gz && \
  tar xzf /tmp/ots.tar.gz -C /var/lib/onetime --strip-components=1 && \
  rm /tmp/ots.tar.gz && \
  cd /var/lib/onetime && \
  bundle install --frozen --deployment --without=dev --gemfile /var/lib/onetime/Gemfile && \
  cp -R etc/* /etc/onetime/

# Copy our own config files over the config files that OTS put in there
# By default, these are owned by root, but we tell Docker to have the ots user own them instead
COPY --chown=ots:ots config.example /etc/onetime/config
COPY --chown=ots:ots redis.conf.example /etc/onetime/redis.conf

ADD entrypoint.sh /usr/bin/

VOLUME /etc/onetime /var/lib/onetime/redis

EXPOSE 7143/tcp

ENTRYPOINT /usr/bin/entrypoint.sh
