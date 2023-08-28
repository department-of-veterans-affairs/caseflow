# frozen_string_literal: true

class SslRedirectExclusionPolicy
  EXCLUDED_PATHS = [
    %r(^/api/docs/v3/),
    %r(^/api/metadata$),
    %r(^/health-check$),
    %r(^/idt/api/v1/),
    %r(^/idt/api/v2/)
  ].freeze

  def self.call(request)
    EXCLUDED_PATHS.any? { |path| path.matches?(request.path) }
  end
end
