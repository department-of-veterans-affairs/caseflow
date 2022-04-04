# frozen_string_literal: true

require 'uri'

# = uri/generic.rb
#
# Author:: Akira Yamada <akira@ruby-lang.org>
# License:: You can redistribute it and/or modify it under the same term as Ruby.
# Revision:: $Id: generic.rb 56878 2016-11-22 23:44:51Z kazu $
#
# See URI for general documentation
#

require 'uri/common'

module URI

  #
  # Base class for all URI classes.
  # Implements generic URI syntax as per RFC 2396.
  #
  class Generic
    undef find_proxy

    # returns a proxy URI.
    # The proxy URI is obtained from environment variables such as http_proxy,
    # ftp_proxy, no_proxy, etc.
    # If there is no proper proxy, nil is returned.
    #
    # If the optional parameter, +env+, is specified, it is used instead of ENV.
    #
    # Note that capitalized variables (HTTP_PROXY, FTP_PROXY, NO_PROXY, etc.)
    # are examined too.
    #
    # But http_proxy and HTTP_PROXY is treated specially under CGI environment.
    # It's because HTTP_PROXY may be set by Proxy: header.
    # So HTTP_PROXY is not used.
    # http_proxy is not used too if the variable is case insensitive.
    # CGI_HTTP_PROXY can be used instead.
    def find_proxy(env=ENV)
      raise BadURIError, "relative URI: #{self}" if self.relative?
      name = self.scheme.downcase + '_proxy'
      proxy_uri = nil
      if name == 'http_proxy' && env.include?('REQUEST_METHOD') # CGI?
        # HTTP_PROXY conflicts with *_proxy for proxy settings and
        # HTTP_* for header information in CGI.
        # So it should be careful to use it.
        pairs = env.reject {|k, v| /\Ahttp_proxy\z/i !~ k }
        case pairs.length
        when 0 # no proxy setting anyway.
          proxy_uri = nil
        when 1
          k, _ = pairs.shift
          if k == 'http_proxy' && env[k.upcase] == nil
            # http_proxy is safe to use because ENV is case sensitive.
            proxy_uri = env[name]
          else
            proxy_uri = nil
          end
        else # http_proxy is safe to use because ENV is case sensitive.
          proxy_uri = env.to_hash[name]
        end
        if !proxy_uri
          # Use CGI_HTTP_PROXY.  cf. libwww-perl.
          proxy_uri = env["CGI_#{name.upcase}"]
        end
      elsif name == 'http_proxy'
        unless proxy_uri = env[name]
          if proxy_uri = env[name.upcase]
            warn 'The environment variable HTTP_PROXY is discouraged.  Use http_proxy.'
          end
        end
      else
        proxy_uri = env[name] || env[name.upcase]
      end

      if proxy_uri.nil? || proxy_uri.empty?
        return nil
      end

      if self.hostname
        require 'socket'
        begin
          addr = IPSocket.getaddress(self.hostname)
          return nil if /\A127\.|\A::1\z/ =~ addr
        rescue SocketError
        end
      end

      name = 'no_proxy'
      if no_proxy = env[name] || env[name.upcase]
        no_proxy.scan(/(?!\.)([^:,\s]+)(?::(\d+))?/) {|host, port|
          if (!port || self.port == port.to_i)
            if /(\A|\.)#{Regexp.quote host}\z/i =~ self.host
              return nil
            elsif addr
              require 'ipaddr'
              return nil if
                begin
                  IPAddr.new(host)
                rescue IPAddr::InvalidAddressError
                  next
                end.include?(addr)
            end
          end
        }
      end
      URI.parse(proxy_uri)
    end
  end
end
