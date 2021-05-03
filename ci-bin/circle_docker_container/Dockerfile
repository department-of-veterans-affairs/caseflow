# NOTE: Once we are no longer using the default Ruby environment, we should upgrade
# our base container to something more recent.
FROM circleci/ruby:2.5.9-node-browsers

USER root

# pdftk is used directly in the app. libaio1 and libaio-dev are used with Oracle's instantclient
RUN apt-get install pdftk libaio1 libaio-dev

ADD instantclient_12_1 /opt/oracle/instantclient_12_1
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient_12_1
RUN ln -s /opt/oracle/instantclient_12_1/libclntsh.so.12.1 /opt/oracle/instantclient_12_1/libclntsh.so

USER circleci
