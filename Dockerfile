FROM ubuntu:14.04

WORKDIR /caseflow

## Install all required dependencies and clean the apt cache
RUN apt-get update -qq && apt-get install -qq -y \ 
	build-essential \
	chromium-browser \
	curl \
	git \
	libfontconfig \
	libgconf-2-4 \
	libnss3 \
	libpq-dev \
	libreadline-dev \
	libssl-dev \
	libsqlite3-dev \
	libxml2-dev \
	libxslt-dev \
	libyaml-dev \
	nodejs \
	pdftk \
	postgresql \
	sqlite3 \
	unzip \
	wget \
	xvfb \
	zlib1g-dev \
	--fix-missing \ 
&& rm -rf /var/lib/apt/lists/*

## Install RBENV and Ruby 2.2.4
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv
RUN /bin/sh -c "cd ~/.rbenv && src/configure && make -C src"
ENV PATH=/root/.rbenv/shims:/root/.rbenv/bin:$PATH
RUN git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
ENV PATH=/root/.rbenv/plugins/ruby-build/bin:$PATH
RUN rbenv install -v 2.2.4
RUN rbenv global 2.2.4
RUN gem install bundler

## Install Node 6.10.2
RUN wget https://s3-us-gov-west-1.amazonaws.com/shared-s3/dsva-appeals/node-v6.10.2-linux-x64.tar.xz -O /opt/node-v6.10.2-linux-x64.tar.xz
RUN tar xf /opt/node-v6.10.2-linux-x64.tar.xz -C /opt
ENV PATH=/opt/node-v6.10.2-linux-x64/bin:$PATH

RUN CHROMEDRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` && \
     mkdir -p /opt/chromedriver-$CHROMEDRIVER_VERSION && \
     curl -sS -o /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip && \
     unzip -qq /tmp/chromedriver_linux64.zip -d /opt/chromedriver-$CHROMEDRIVER_VERSION && \
     rm /tmp/chromedriver_linux64.zip && \
     chmod +x /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver && \
     ln -fs /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver /usr/local/bin/chromedriver

ENV RAILS_ENV=test
ENV POSTGRES_HOST=localhost
ENV POSTGRES_USER=postgres
ENV DISPLAY=:99

# Prefetch Gems
ADD Gemfile* /caseflow/
RUN cd /caseflow && bundle install --without production staging
