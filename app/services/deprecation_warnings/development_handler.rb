# frozen_string_literal: true

require_relative "disallowed_deprecations"

# @note For use with `ActiveSupport::Deprecation.behavior=`.
module DeprecationWarnings
  class DevelopmentHandler < BaseHandler
    extend DisallowedDeprecations

    class << self
      # :reek:LongParameterList
      def call(message, _callstack, _deprecation_horizon, _gem_name)
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
