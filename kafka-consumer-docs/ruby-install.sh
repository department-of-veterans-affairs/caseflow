#!/bin/sh

cd /tmp

curl -OL https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.2.tar.gz
curl -OL https://github.com/yaml/libyaml/releases/download/0.2.5/yaml-0.2.5.tar.gz
curl -OL https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1u/openssl-1.1.1u.tar.gz
curl -OL https://github.com/libffi/libffi/releases/download/v3.4.4/libffi-3.4.4.tar.gz

tar -zxvf ruby-3.2.2.tar.gz
tar -zxvf yaml-0.2.5.tar.gz
tar -zxvf openssl-1.1.1u.tar.gz
tar -zxvf libffi-3.4.4.tar.gz

cd /tmp/openssl-1.1.1u
./config --prefix=/tmp/openssl-1.1.1u-bin
make
make install

cd ../ruby-3.2.2/
./configure --prefix=$HOME/.rbenv/versions/3.2.2 --with-libyaml-source-dir=/tmp/yaml-0.2.5 --with-openssl-dir=/tmp/openssl-1.1.1u-bin --with-libffi-dir=/tmp/libffi-3.4.4

REPLACEMENT_CODE="  args = \"#{yaml_configure} --enable-shared\".split(' ')"$'\n'
FILE_PATH="/tmp/ruby-3.2.2/ext/psych/extconf.rb"

sed -i.bak '22,28c\
'"$REPLACEMENT_CODE"'' "$FILE_PATH"

make
make install

