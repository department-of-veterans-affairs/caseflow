FROM ruby:2.2.4

RUN apt-get update -qq && apt-get install -qq -y build-essential nodejs libpq-dev xvfb postgresql pdftk --fix-missing --no-install-recommends

RUN wget https://s3-us-gov-west-1.amazonaws.com/shared-s3/dsva-appeals/node-v6.10.2-linux-x64.tar.xz -O /opt/node-v6.10.2-linux-x64.tar.xz
RUN tar xf /opt/node-v6.10.2-linux-x64.tar.xz -C /opt

## Copy project files to newly built container
RUN mkdir /build
WORKDIR /build
ADD Gemfile /build/Gemfile
ADD Gemfile.lock /build/Gemfile.lock
RUN bundle install --deployment --without development staging production
ADD . /build

ENV PATH="/opt/node-v6.10.2-linux-x64/bin:${PATH}"

RUN cd /build/client && npm install --no-optional

# TODO start postgres and setup database
# RUN RAILS_ENV=test bundle exec rake db:create
# RUN RAILS_ENV=test bundle exec rake db:schema:load
