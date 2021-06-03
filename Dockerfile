FROM ruby:2.5.3-slim
MAINTAINER Development and Operations team @ Department of Veterans Affairs

# Build variables
ENV BUILD build-essential postgresql-client libaio1 libpq-dev libsqlite3-dev curl software-properties-common apt-transport-https pdftk
ENV CASEFLOW git nodejs yarn

# Environment (system) variables
ENV LD_LIBRARY_PATH="/opt/oracle/instantclient_12_2:$LD_LIBRARY_PATH" \
    ORACLE_HOME="/opt/oracle/instantclient_12_2" \
    LANG="AMERICAN_AMERICA.US7ASCII" \
    RAILS_ENV="development" \
    DEPLOY_ENV="demo" \
    PATH="$HOME/.yarn/bin:$HOME/.config/yarn/global/node_modules/.bin:$PATH"
    APPOPTICS_SERVICE_KEY=$(cat config/appoptics.key)

# install oracle deps
WORKDIR /opt/oracle/instantclient_12_2/
COPY docker-bin/oracle_libs/* ./
RUN ln -s libclntsh.so.12.1 libclntsh.so

WORKDIR /caseflow

# Copy all the files
COPY . .

RUN pwd && ls -lsa

# Build dependencies
RUN apt -y update && \
    apt -y upgrade && \
    mkdir -p /usr/share/man/man1 && \
    mkdir /usr/share/man/man7 && \
    apt install -y ${BUILD} && \
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt -y update && \
    curl -sL https://deb.nodesource.com/setup_$(cat .nvmrc | cut -d "." -f 1).x | bash - && \
    apt install -y ${CASEFLOW} &&  \
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - && \
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list && \
    apt-get clean && apt-get autoclean && apt-get autoremove

# install jemalloc
RUN apt install -y --no-install-recommends libjemalloc-dev

# install datadog agent
RUN DD_INSTALL_ONLY=true DD_AGENT_MAJOR_VERSION=7 DD_API_KEY=$(cat config/datadog.key) bash -c "$(curl -L https://raw.githubusercontent.com/DataDog/datadog-agent/master/cmd/agent/install_script.sh)"

RUN rm -rf /var/lib/apt/lists/*

RUN bundle install && \
    cd client && \
    yarn install && \
    yarn run build:demo && \
    chmod +x /caseflow/docker-bin/startup.sh && \
    rm -rf docker-bin

# Run the app
ENTRYPOINT ["/bin/bash", "-c", "/caseflow/docker-bin/startup.sh"]
