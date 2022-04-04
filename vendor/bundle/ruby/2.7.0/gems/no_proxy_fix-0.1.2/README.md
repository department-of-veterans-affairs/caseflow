# no_proxy_fix

[![Gem Version](https://badge.fury.io/rb/no_proxy_fix.svg)](http://badge.fury.io/rb/no_proxy_fix)
[![Build Status](https://travis-ci.org/ermaker/no_proxy_fix.svg?branch=master)](https://travis-ci.org/ermaker/no_proxy_fix)
[![Dependency Status](https://gemnasium.com/ermaker/no_proxy_fix.svg)](https://gemnasium.com/ermaker/no_proxy_fix)


This fixes https://github.com/ruby/ruby/commit/556e3da4216c926e71dea9ce4ea4a08dcfdc1275 for ruby 2.4.0 and ruby 2.4.1.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'no_proxy_fix'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install no_proxy_fix

## Usage

```ruby
require 'no_proxy_fix'
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ermaker/no_proxy_fix.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

