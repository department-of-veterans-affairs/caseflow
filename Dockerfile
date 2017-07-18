FROM ubuntu:14.04

# Copy over local configs
WORKDIR /caseflow
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock

WORKDIR /caseflow/client
COPY client/npm-shrinkwrap.json npm-shrinkwrap.json
COPY client/package.json package.json


## Install all required dependencies and clean the apt cache
WORKDIR /caseflow
RUN apt-get update -qq && apt-get install -qq -y \
	build-essential \
	chromium-browser \
	chrpath \
	curl \
	dbus-x11 \
	git \
	libfontconfig \
	libfontconfig1 \
	libfontconfig1-dev \
	libfreetype6 \
	libfreetype6-dev \
	libgconf-2-4 \
	libnss3 \
	libpq-dev \
	libreadline-dev \
	libssl-dev \
	libsqlite3-dev \
	libxml2-dev \
	libxslt-dev \
	libxft-dev \
	libyaml-dev \
	nodejs \
	pdftk \
	postgresql \
	sqlite3 \
	unzip \
	wget \
	xfonts-100dpi \
	xfonts-75dpi \
	xfonts-cyrillic \
	xorg \
	xvfb \
	zlib1g-dev \
	--fix-missing \
	&& rm -rf /var/lib/apt/lists/*

# ARG user=caseflow
# RUN useradd --no-log-init -m -r $user && \
#     chown -R $user /caseflow && \
#     chown -R $user /opt && \
#     chown -R $user /home/$user && \
#     chown -R $user /usr/local
# USER $user

## Install RBENV and Ruby 2.2.4
RUN git clone https://github.com/rbenv/rbenv.git ~/.rbenv && \
    echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.bashrc && \
    echo 'eval "$(rbenv init -)"' >> ~/.bashrc
ENV PATH=/root/.rbenv/bin:/root/.rbenv/shims:$PATH
RUN cd /root/.rbenv && src/configure && make -C src

RUN git clone https://github.com/rbenv/ruby-build.git ~/.rbenv/plugins/ruby-build
ENV PATH=~/.rbenv/plugins/ruby-build/bin:$PATH

RUN rbenv install -v 2.2.4 && \
    rbenv global 2.2.4 && \
    gem install bundler && \
    gem install foreman

## Install Node 6.10.2
RUN wget https://s3-us-gov-west-1.amazonaws.com/shared-s3/dsva-appeals/node-v6.10.2-linux-x64.tar.xz -O /opt/node-v6.10.2-linux-x64.tar.xz && \
    tar xf /opt/node-v6.10.2-linux-x64.tar.xz -C /opt
ENV PATH=/opt/node-v6.10.2-linux-x64/bin:$PATH

## Install Chromedriver
RUN CHROMEDRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` && \
    mkdir -p /opt/chromedriver-$CHROMEDRIVER_VERSION && \
    curl -sS -o /tmp/chromedriver_linux64.zip https://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip && \
    unzip -qq /tmp/chromedriver_linux64.zip -d /opt/chromedriver-$CHROMEDRIVER_VERSION && \
    rm /tmp/chromedriver_linux64.zip && \
    chmod +x /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver && \
    ln -fs /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver /usr/local/bin/chromedriver

## Install PhantomJs for konacha tests
RUN PHANTOM_JS="phantomjs-2.1.1-linux-x86_64" && \
    wget https://bitbucket.org/ariya/phantomjs/downloads/$PHANTOM_JS.tar.bz2 -O /opt/$PHANTOM_JS.tar.bz2 && \
    tar xvjf /opt/$PHANTOM_JS.tar.bz2 -C /opt && \
    ln -sf /opt/$PHANTOM_JS/bin/phantomjs /usr/local/bin

## Set environment variables (this can be overridden with docker-compose)
ENV POSTGRES_HOST=localhost
ENV POSTGRES_USER=postgres
ENV DISPLAY=:99
ENV CHROME_BIN=chromium-browser

## Prefetch Gems
WORKDIR /caseflow
RUN bundle install --without production staging
WORKDIR /caseflow/client
RUN npm install

WORKDIR /caseflow

# Entrypoint for the container
CMD ["foreman", "start", "-f", "Procfile.docker"]
