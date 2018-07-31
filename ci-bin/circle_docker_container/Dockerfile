# NOTE: Once we are no longer using the default Ruby environment, we should upgrade
# our base container to something more recent.
FROM circleci/ruby:2.2-node-browsers

USER root

# pdftk is used directly in the app. libaio1 and libaio-dev are used with Oracle's instantclient
RUN apt-get install pdftk libaio1 libaio-dev

ADD instantclient_12_1 /opt/oracle/instantclient_12_1
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient_12_1
RUN ln -s /opt/oracle/instantclient_12_1/libclntsh.so.12.1 /opt/oracle/instantclient_12_1/libclntsh.so
# The default permissions here break rbenv. I'm not sure why. Since the CircleCI
# user is the only user of this container, hammer the permissions.
RUN chown -R circleci /usr/local/bundle

USER circleci
# Explicitly set the rbenv PATHs here so the installation script doesn't error.
ENV PATH=/home/circleci/.rbenv/bin:/home/circleci/.rbenv/shims:/usr/local/bundle/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN curl -fsSL https://github.com/rbenv/rbenv-installer/raw/master/bin/rbenv-installer | bash
