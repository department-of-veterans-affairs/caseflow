# Use CircleCI with ruby 2.5 and browsers installed as a base.
# see https://circleci.com/developer/images
FROM cimg/ruby:2.5-browsers

USER root

RUN apt-get update

# pdftk is used directly in the app.
# Note: ruby 2.5 is bundled with Ubuntu 18, which no longer has pdftk.
# Build java port of pdftk from source
# see https://gitlab.com/pdftk-java/pdftk
RUN apt-get install ant default-jre-headless libcommons-lang3-java libbcprov-java
RUN git clone https://gitlab.com/pdftk-java/pdftk.git \
    && cd pdftk \
    && mkdir lib \
    && ln -st lib /usr/share/java/{commons-lang3,bcprov}.jar \
    && ant jar \
    && java -jar build/jar/pdftk.jar --version
ADD stub.sh pdftk/build/jar/stub.sh
# Create a wrapper script for the java port of the pdftk jar
# see https://github.com/jkraemer/pdf-forms#using-the-java-port-of-pdftk (our dependency)
RUN cat pdftk/build/jar/stub.sh pdftk/build/jar/pdftk.jar > pdftk.run \
    && chmod +x pdftk.run \
    && mv pdftk.run /usr/bin/pdftk \
    && pdftk --version
RUN rm -r pdftk

# libaio1 and libaio-dev are used with Oracle's instantclient
RUN apt-get install libaio1 libaio-dev

ADD instantclient_12_1 /opt/oracle/instantclient_12_1
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient_12_1
RUN ln -s /opt/oracle/instantclient_12_1/libclntsh.so.12.1 /opt/oracle/instantclient_12_1/libclntsh.so

# Install Edge
# via. https://www.tecmint.com/install-microsoft-edge-browser-in-linux/
# Note: This could eventually migrate to the CircleCI browser-tools orb
# see https://circleci.com/developer/orbs/orb/circleci/browser-tools
RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
RUN install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
RUN sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list'
RUN rm microsoft.gpg
RUN apt-get update
RUN apt-get install microsoft-edge-dev

USER circleci
