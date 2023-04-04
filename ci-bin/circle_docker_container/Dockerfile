# NOTE: Once we are no longer using the default Ruby environment, we should upgrade
# our base container to something more recent.
FROM cimg/ruby:2.7.3-browsers

USER root

# pdftk is used directly in the app. libaio1 and libaio-dev are used with Oracle's instantclient
# python2 is needed as a node-gyp@3.8.0 dependency. It can be eliminated if we udated to the latest version.
RUN apt-get update && apt-get install -y pdftk libaio1 libaio-dev python2

ADD instantclient_12_1 /opt/oracle/instantclient_12_1
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient_12_1
RUN ln -s /opt/oracle/instantclient_12_1/libclntsh.so.12.1 /opt/oracle/instantclient_12_1/libclntsh.so


USER circleci
