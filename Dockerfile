FROM ruby:2.5.1-slim
MAINTAINER Development and Operations team @ Department of Veterans Affairs

# Build variables
ENV BUILD build-essential postgresql-client libaio1 libpq-dev libsqlite3-dev curl software-properties-common apt-transport-https
ENV CASEFLOW git nodejs yarn

# Environment (system) variables
ENV LD_LIBRARY_PATH="/opt/oracle/instantclient_12_2:$LD_LIBRARY_PATH" \
    ORACLE_HOME="/opt/oracle/instantclient_12_2" \
    LANG="AMERICAN_AMERICA.US7ASCII" \
    RAILS_ENV="development" \
    PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# install oracle deps
WORKDIR /opt/oracle/instantclient_12_2/
COPY docker-bin/oracle_libs/* ./
RUN ln -s libclntsh.so.12.1 libclntsh.so

WORKDIR /caseflow

# Build dependencies
RUN apt -y update && \
    apt -y upgrade && \
    apt install -y ${BUILD} && \
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt -y update && \
    curl -sL https://deb.nodesource.com/setup_6.x | bash - && \
    apt install -y ${CASEFLOW} &&  \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get clean && apt-get autoclean && apt-get autoremove

# Copy all the files
COPY . .

RUN bundle install && \
    cd client && \
    yarn install && \
    yarn run build:production && \
    chmod +x /caseflow/docker-bin/startup.sh && \
    rm -rf docker-bin

# Run the app
ENTRYPOINT ["/bin/bash", "-c", "/caseflow/docker-bin/startup.sh"]
