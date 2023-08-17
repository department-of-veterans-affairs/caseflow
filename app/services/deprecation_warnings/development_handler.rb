# frozen_string_literal: true

require_relative "disallowed_deprecations"

# @note For use with `ActiveSupport::Deprecation.behavior=`.
module DeprecationWarnings
  class DevelopmentHandler < BaseHandler
    extend DisallowedDeprecations

    class << self
      def call(message, callstack, deprecation_horizon, gem_name)
        raise_if_disallowed_deprecation!(message)
        emit_warning_to_application_logs(message)
      end

      private

      def emit_warning_to_application_logs(message)
        Rails.logger.warn(message)
      end
    end
  end
end
