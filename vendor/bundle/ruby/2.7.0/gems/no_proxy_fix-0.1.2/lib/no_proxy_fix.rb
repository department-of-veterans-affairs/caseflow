require 'no_proxy_fix/version'

module NoProxyFix
  require 'cext/generic_find_proxy' if RUBY_VERSION =~ /\A2\.4\.[10]/
end
