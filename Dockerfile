FROM ruby:2.2.4

## Install all required dependencies and clean the apt cache
RUN apt-get update -qq && apt-get install -qq -y \ 
	build-essential \
	git \
	libpq-dev \
	nodejs \
	pdftk \
	postgresql \
	unzip \
	wget \
	xvfb \
	--fix-missing \ 
&& rm -rf /var/lib/apt/lists/*

## Install Node 6.10.2
RUN wget https://s3-us-gov-west-1.amazonaws.com/shared-s3/dsva-appeals/node-v6.10.2-linux-x64.tar.xz -O /opt/node-v6.10.2-linux-x64.tar.xz
RUN tar xf /opt/node-v6.10.2-linux-x64.tar.xz -C /opt
ENV PATH=/opt/node-v6.10.2-linux-x64/bin:$PATH

RUN LATEST=$(wget -q -O - http://chromedriver.storage.googleapis.com/LATEST_RELEASE) && \
	wget http://chromedriver.storage.googleapis.com/$LATEST/chromedriver_linux64.zip && \
	unzip chromedriver_linux64.zip && ln -s $PWD/chromedriver /usr/local/bin/chromedriver

## Copy project files to newly built container
RUN mkdir /build
WORKDIR /build
COPY Gemfile /build/Gemfile
COPY Gemfile.lock /build/Gemfile.lock
RUN bundle install --deployment --without development staging production
COPY . /build

RUN cd /build/client && npm install --no-optional

ENV POSTGRES_HOST=db
ENV POSTGRES_PASSWORD=1234
