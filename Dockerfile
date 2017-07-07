################################################################################
# The goal of this container is to provide a VA Appeals specific app
# environment that includes all the basic tools to run any appeals applications.
#
################################################################################
FROM ubuntu:14.04

################################################################################
# Basic development packages and tools
################################################################################
RUN apt-get update && apt-get install -y \
	autoconf \
	build-essential \
    	chromium-browser \
	chrpath \
	curl \
	git \
	grep \
	iputils-ping \
	libgconf-2-4 \
	libssl-dev \
	libpq-dev \
	libsqlite3-dev \
	libxft-dev \
	netcat \
	openssl \
	pdftk \
    	sudo \
	tar \
	tzdata \
	unzip \
	vim \
	wget \
	xvfb \
	zlib1g-dev

################################################################################
# Ruby 2.3, copied from the Ruby Dockerhub (https://hub.docker.com/_/ruby/)
################################################################################

# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
	&& { \
		echo 'install: --no-document'; \
		echo 'update: --no-document'; \
	} >> /usr/local/etc/gemrc

ENV RUBY_MAJOR 2.2
ENV RUBY_VERSION 2.2.4
ENV RUBY_DOWNLOAD_SHA256 b87c738cb2032bf4920fef8e3864dc5cf8eae9d89d8d523ce0236945c5797dcd
ENV RUBYGEMS_VERSION 2.6.6

# some of ruby's build scripts are written in ruby
#   we purge system ruby later to make sure our final image uses what we just built
RUN set -ex \
	\
	&& buildDeps=' \
		bison \
		libgdbm-dev \
		ruby \
	' \
	&& apt-get update \
	&& apt-get install -y --no-install-recommends $buildDeps \
	&& rm -rf /var/lib/apt/lists/* \
	\
	&& wget -O ruby.tar.gz "http://cache.ruby-lang.org/pub/ruby/$RUBY_MAJOR/ruby-$RUBY_VERSION.tar.gz" \
	&& mkdir -p /usr/src/ruby \
	&& tar -xzf ruby.tar.gz -C /usr/src/ruby --strip-components=1 \
	&& rm ruby.tar.gz \
	\
	&& cd /usr/src/ruby \
	\
# hack in "ENABLE_PATH_CHECK" disabling to suppress:
#   warning: Insecure world writable dir
	&& { \
		echo '#define ENABLE_PATH_CHECK 0'; \
		echo; \
		cat file.c; \
	} > file.c.new \
	&& mv file.c.new file.c \
	\
	&& autoconf \
	&& ./configure --disable-install-doc \
	&& make -j"$(nproc)" \
	&& make install \
	\
	&& apt-get purge -y --auto-remove $buildDeps \
	&& cd / \
	&& rm -r /usr/src/ruby \
	\
	&& gem update --system

ENV BUNDLER_VERSION 1.14.6

RUN gem install bundler --version "$BUNDLER_VERSION"
RUN gem install rails

# install things globally, for great justice
# and don't create ".bundle" in all our apps
ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
	BUNDLE_BIN="$GEM_HOME/bin" \
	BUNDLE_SILENCE_ROOT_WARNING=1 \
	BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
	&& chmod 777 "$GEM_HOME" "$BUNDLE_BIN"

################################################################################
# Node js
################################################################################
RUN curl -sL http://deb.nodesource.com/setup_6.x | sudo -E bash -
RUN apt-get install -y nodejs


################################################################################
# Install Chrome WebDriver
################################################################################
RUN CHROMEDRIVER_VERSION=`curl -sS chromedriver.storage.googleapis.com/LATEST_RELEASE` && \
    mkdir -p /opt/chromedriver-$CHROMEDRIVER_VERSION && \
    curl -sS -o /tmp/chromedriver_linux64.zip http://chromedriver.storage.googleapis.com/$CHROMEDRIVER_VERSION/chromedriver_linux64.zip && \
    unzip -qq /tmp/chromedriver_linux64.zip -d /opt/chromedriver-$CHROMEDRIVER_VERSION && \
    rm /tmp/chromedriver_linux64.zip && \
    chmod +x /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver && \
    ln -fs /opt/chromedriver-$CHROMEDRIVER_VERSION/chromedriver /usr/local/bin/chromedriver


################################################################################
# Create User $username
################################################################################
ARG username=dsva
ARG usergroup=dsva

RUN echo $username
RUN useradd -ms /bin/bash $username
RUN usermod -g $usergroup $username
RUN usermod -a -G $usergroup $username
RUN echo "$username:$usergroup" | chpasswd && adduser $username sudo
RUN echo "$username ALL=(ALL) NOPASSWD:ALL" | sudo tee -a /etc/sudoers
ENV HOME /home/$username
WORKDIR /home/$username

################################################################################
# Permissions and Paths
################################################################################

RUN chown -R $username:$usergroup /home/$username/

USER $username

ENV TERM=xterm

