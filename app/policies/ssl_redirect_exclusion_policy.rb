# frozen_string_literal: true

# @note To be used in the environment configuration settings for excluding exempt request paths from SSL redirects
#   when `config.force_ssl = true`
#
# @example config/environments/production.rb
#
#   Rails.application.configure do
#     config.force_ssl = true
#     config.ssl_options = { redirect: { exclude: SslRedirectExclusionPolicy } }
#     # etc.
class SslRedirectExclusionPolicy
  EXEMPT_PATH_PATTERNS = [
    %r{^/api/docs/v3/},
    %r{^/api/metadata$},
    %r{^/health-check$},
    %r{^/idt/api/v1/},
    %r{^/idt/api/v2/},
    %r{^/pdfjs/}
  ].freeze

  # @param [ActionDispatch::Request] request
  # @return [TrueClass, FalseClass] true if request path is exempt from an SSL redirect
  def self.call(request)
    EXEMPT_PATH_PATTERNS.any? { |pattern| pattern =~ request.path }
  end
end
