ARG RUBY_VERSION=2.7.3
FROM registry.docker.com/library/ruby:$RUBY_VERSION-slim

# Set up environment variables
ENV BUILD="build-essential postgresql-client libpq-dev libsqlite3-dev curl ca-certificates wget git" \
    NVM_DIR="/usr/local/nvm" \
    NODE_VERSION="16.16.0" \
    PATH="$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH" \
    RAILS_ENV="development" \
    DEPLOY_ENV="demo" \
    LANG="C.UTF-8"

# Copy all files from docker-bin into /usr/bin/ in the container
COPY docker-bin/. /usr/bin/

# Copy the contents of the instantclient_23_3 folder to the Oracle directory
COPY docker-bin/instantclient_23_3 /usr/lib/oracle/instantclient_23_3

# Set environment variables for Oracle libraries
ENV ORACLE_HOME="/usr/lib/oracle/instantclient_23_3"
ENV LD_LIBRARY_PATH="/usr/lib/oracle/instantclient_23_3:$LD_LIBRARY_PATH"

# Install Oracle dependencies and create symbolic links
WORKDIR /usr/lib/oracle/instantclient_23_3/
RUN test -e libclntsh.so.23.1 || ln -s libclntsh.so libclntsh.so.23.1

WORKDIR /caseflow

COPY . .

# Install base dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends $BUILD && \
    rm -rf /var/lib/apt/lists/*

# Set up NVM and Node
RUN mkdir -p $NVM_DIR && \
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash && \
    . "$NVM_DIR/nvm.sh" && \
    nvm install $NODE_VERSION && \
    nvm alias default $NODE_VERSION

# Install compatible Bundler version and gems
COPY Gemfile* .
RUN gem install bundler -v 2.4.19 && \
    bundle config build.ruby-oci8 --with-oci8-include=/usr/lib/oracle/instantclient_23_3 --with-oci8-lib=/usr/lib/oracle/instantclient_23_3 && \
    bundle install


# Expose the Rails port
ARG DEFAULT_PORT=3000
EXPOSE ${DEFAULT_PORT}

# Start the Rails application
CMD ["bundle", "exec", "rails", "s", "-p", "3000", "-b", "0.0.0.0"]
