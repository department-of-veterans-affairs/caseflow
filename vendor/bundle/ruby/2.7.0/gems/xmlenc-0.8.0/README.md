[![Build Status](https://app.travis-ci.com/digidentity/xmlenc.svg?branch=master)](https://app.travis-ci.com/digidentity/xmlenc)
[![Coverage Status](https://coveralls.io/repos/digidentity/xmlenc/badge.svg?branch=master&service=github)](https://coveralls.io/github/digidentity/xmlenc?branch=master)
[![Code Climate](https://codeclimate.com/github/digidentity/xmlenc/badges/gpa.svg)](https://codeclimate.com/github/digidentity/xmlenc)

# Xmlenc

This gem is a (partial) implementation of the XMLEncryption specification (http://www.w3.org/TR/xmlenc-core/)

## Installation

Add this line to your application's Gemfile:

    gem 'xmlenc'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install xmlenc

## Usage

### Decrypt a document

```ruby
key_pem = File.read('path/to/key.pem')
xml = File.read('path/to/file.xml')

private_key = OpenSSL::PKey::RSA.new(key_pem)
encrypted_document = Xmlenc::EncryptedDocument.new(xml)
decrypted_document = encrypted_document.decrypt(private_key)
```

### Supported algorithms

Data algorithms
* http://www.w3.org/2001/04/xmlenc#tripledes-cbc
* http://www.w3.org/2001/04/xmlenc#aes128-cbc
* http://www.w3.org/2001/04/xmlenc#aes256-cbc
* http://www.w3.org/2009/xmlenc11#aes128-gcm
* http://www.w3.org/2009/xmlenc11#aes192-gcm
* http://www.w3.org/2009/xmlenc11#aes256-gcm

Key algorithms

* http://www.w3.org/2001/04/xmlenc#rsa-1_5
* http://www.w3.org/2001/04/xmlenc#rsa-oaep-mgf1p (Without OAEPParams and only SHA1 digest methods)


## Roadmap
1. add encryption (in progress)
2. support more algorithms

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
