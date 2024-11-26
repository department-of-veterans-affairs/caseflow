FROM ruby:2.7.3-slim
MAINTAINER Development and Operations team @ Department of Veterans Affairs

# Build variables
ENV BUILD build-essential postgresql-client libaio1 libpq-dev libsqlite3-dev curl software-properties-common apt-transport-https pdftk
ENV CASEFLOW git yarn

# Environment (system) variables
ENV LD_LIBRARY_PATH="/opt/oracle/instantclient_12_2:$LD_LIBRARY_PATH" \
    ORACLE_HOME="/opt/oracle/instantclient_12_2" \
    LANG="AMERICAN_AMERICA.US7ASCII" \
    RAILS_ENV="development" \
    DEPLOY_ENV="demo" \
    PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH" \
    NODE_OPTIONS="--max-old-space-size=8192" \
    SSL_CERT_FILE="/etc/ssl/certs/cacert.pem"
# install oracle deps
WORKDIR /opt/oracle/instantclient_12_2/
COPY docker-bin/oracle_libs/* ./
RUN ln -s libclntsh.so.12.1 libclntsh.so

WORKDIR /caseflow

# Copy all the files
COPY . .

RUN pwd && ls -lsa

# Install VA Trusted Certificates
RUN mkdir -p /usr/local/share/ca-certificates/va
COPY docker-bin/ca-certs/*.crt /usr/local/share/ca-certificates/va/
#COPY docker-bin/ca-certs/*.cer /usr/local/share/ca-certificates/va/
RUN update-ca-certificates
COPY docker-bin/ca-certs/cacert.pem /etc/ssl/certs/cacert.pem

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

RUN apt -y update && \
    apt -y upgrade && \
    mkdir -p /usr/share/man/man1 && \
    mkdir /usr/share/man/man7 && \
    apt install -y ${BUILD} && \
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt -y update

# Install node
RUN mkdir /usr/local/nvm
ENV NVM_DIR /usr/local/nvm
ENV NODE_VERSION 16.16.0
ENV NVM_INSTALL_PATH $NVM_DIR/versions/node/v$NODE_VERSION
RUN curl --silent -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
RUN source $NVM_DIR/nvm.sh \
   && nvm install $NODE_VERSION \
   && nvm alias default $NODE_VERSION \
   && nvm use default
ENV NODE_PATH $NVM_INSTALL_PATH/lib/node_modules
ENV PATH $NVM_INSTALL_PATH/bin:$PATH

RUN apt install -y ${CASEFLOW} &&  \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get clean && apt-get autoclean && apt-get autoremove

ARG PRIVATE_ACCESS_TOKEN
RUN git config --global url."https://${PRIVATE_ACCESS_TOKEN}:x-oauth-basic@github.com/".insteadOf "https://github.com/"

# install jemalloc
RUN apt install -y --no-install-recommends libjemalloc-dev

RUN rm -rf /var/lib/apt/lists/*

# Installing the version of bundler that corresponds to the Gemfile.lock
# Rake 13.0.1 is already installed, so we're uninstalling it and letting bundler install rake later.
RUN gem install bundler:$(cat Gemfile.lock | tail -1 | tr -d " ") && gem uninstall -i /usr/local/lib/ruby/gems/2.7.0 rake
RUN bundle install && \
    cd client && \
    yarn install && \
    yarn run build:demo && \
    chmod +x /caseflow/docker-bin/startup.sh && \
    rm -rf docker-bin

# Run the app
ENTRYPOINT ["/bin/bash", "-c", "/caseflow/docker-bin/startup.sh"]


