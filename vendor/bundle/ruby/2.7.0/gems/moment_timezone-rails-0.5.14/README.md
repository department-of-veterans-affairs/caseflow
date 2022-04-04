# moment_timezone-rails

[moment-timezone](http://momentjs.com/timezone/) for Rails

## Installation

`momentjs-rails` need to be explicitly included in your application's Gemfile:

```ruby
gem 'momentjs-rails'
```

Then add this line to your application's Gemfile:

```ruby
gem 'moment_timezone-rails'
```

And then execute:

```sh
$ bundle
```

Or install it yourself as:

```sh
$ gem install moment_timezone-rails
```

## Usage

Add the following directives to `application.js`.

### For v0.5.14 and up

```js
//= require moment

// moment-timezone without timezone data
//= require moment-timezone

// moment-timezone with timezone data from 2012-2022
//= require moment-timezone-with-data-2012-2022

// moment-timezone all timezone data
//= require moment-timezone-with-data
```

### For v0.2.2 and up

```js
//= require moment

// moment-timezone without timezone data
//= require moment-timezone

// moment-timezone with timezone data from 2010-2020
//= require moment-timezone-with-data-2010-2020

// moment-timezone all timezone data
//= require moment-timezone-with-data
```

### For v0.1.0

```js
//= require moment

// moment-timezone without timezone data
//= require moment-timezone

// moment-timezone with timezone data from 2010-2020
//= require moment-timezone-2010-2020

// moment-timezone all timezone data
//= require moment-timezone-all-years
```

### For v0.0.4 and below

```js
//= require moment
//= require moment-timezone
//= require moment-timezone-data
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
