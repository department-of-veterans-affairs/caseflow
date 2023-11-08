# Apple M1 & M2 install without Rosetta

## Description

Most installation guides recommend to use Rosetta as a work-a-round to setting up a Ruby environment which adds un-needed overhead. This guide will walk through how to compile Ruby v3.2.2 using a version of OpenSSL which will work with the Apple M1 & M2 Arm64 archetypes. This also includes adding Ruby v3.2.2 to rbenv.

## pre-reqs

1. Homebrew (installed through the Self Service app)
2. Command Line Tools (installed through the Self Service app)


## Steps:

### 1. Install rbenv and add init command to shell config

via CLI
`brew install rbenv ruby-build`

Add the following to the end your `~/.zshrc` file
`eval "(rbenv init - zsh)"`

### 2. Download the required tar files for Ruby v3.2.2

via CLI inside the temp directory
```Bash
cd /tmp
curl -OL https://cache.ruby-lang.org/pub/ruby/3.2/ruby-3.2.2.tar.gz
curl -OL https://github.com/yaml/libyaml/releases/download/0.2.5/yaml-0.2.5.tar.gz
curl -OL https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1u/openssl-1.1.1u.tar.gz
curl -OL https://github.com/libffi/libffi/releases/download/v3.4.4/libffi-3.4.4.tar.gz

```

### 3. Extract each tar file individually

via CLI
```Bash
tar -zxvf ruby-3.2.2.tar.gz
tar -zxvf yaml-0.2.5.tar.gz
tar -zxvf openssl-1.1.1u.tar.gz
tar -zxvf libffi-3.4.4.tar.gz
```

### 4. configure and compile the openSSL package

via CLI in the openssl package directory
```Bash
cd /tmp/openssl-1.1.1u
./config --prefix=/tmp/openssl-1.1.1u-bin
make
make install
```

### 5. Configure the Ruby package, modify the extconf, and compile

via CLI in the Ruby package directory
```Bash
cd ../ruby-3.2.2/
./configure --prefix=$HOME/.rbenv/versions/3.2.2 --with-libyaml-source-dir=/tmp/yaml-0.2.5 --with-openssl-dir=/tmp/openssl-1.1.1u-bin --with-libffi-dir=/tmp/libffi-3.4.4
```
We will need to modify the args for yaml configuration args before we compile
open the `./ext/psych/extconf.rb` file in the editor of your choice.

after the yaml args are defined we will modify the args. We are looking for this code snippet:
```Ruby
args = [
    yaml_configure,
    "--enable-#{shared ? 'shared' : 'static'}",
    "--host=#{RbConfig::CONFIG['host'].sub(/-unknown-/, '-')}",
    "CC=#{RbConfig::CONFIG['CC']}",
    *(["CFLAGS=-w"] if RbConfig::CONFIG["GCC"] == "yes"),
  ]
```
and replacing it with:
```Ruby
args = "#{yaml_configure} --enable-shared".split(' ')
```

After our file is modified and saved, we can compile and install

in CLI
```Bash
make
make install
```

### 6. Set and test our ruby version with rbenv

We can check to make sure that our new Ruby version is visible to rbenv with the command:
```Bash
rbenv versions
```

We can to set our new ruby version with the command:
```Bash
rbenv global 3.2.2
```

if `ruby -v` does not point to the correct version of Ruby, you may need to run `rbenv rehash`

Finally, we can test that Ruby is working correctly with the `irb` command.



