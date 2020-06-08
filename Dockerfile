FROM pandoc/ubuntu:2.10

RUN  apt-get -q --no-allow-insecure-repositories update \
  && DEBIAN_FRONTEND=noninteractive \
     apt-get install --assume-yes --no-install-recommends \
         build-essential \
         bundler=2.1.* \
         git=* \
         libicu-dev \
         rake=* \
         ruby=* \
         ruby-dev=* \
         ruby-rugged=0.28.4.1* \
         zlib1g-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY . /app

ENV RUBYOPT="-W0"
RUN  bundler install \
  && bundle exec rake spec

ENTRYPOINT ["bundle", "exec", "whedon"]
