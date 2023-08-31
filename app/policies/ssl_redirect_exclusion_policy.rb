require 'set'

class SslRedirectExclusionPolicy
  
  EXEMPT_PATH_PATTERNS = Set.new([
    %r(^/api/docs/v3/),
    %r(^/api/metadata$),
    %r(^/health-check$),
    %r(^/idt/api/v1/),
    %r(^/idt/api/v2/)
  ]).freeze

  def self.call(request)
    # Check if the request path matches any of the exempt patterns
    EXEMPT_PATH_PATTERNS.any? { |pattern| pattern.match?(request.path) }
  end
end
