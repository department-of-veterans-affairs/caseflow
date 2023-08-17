# frozen_string_literal: true

require_relative "disallowed_deprecations"

# @note For use with `ActiveSupport::Deprecation.behavior=`.
module DeprecationWarnings
  class TestHandler < BaseHandler
    extend DisallowedDeprecations

    class << self
      # :reek:LongParameterList
      def call(message, _callstack, _deprecation_horizon, _gem_name)
        raise_if_disallowed_deprecation!(message)
        emit_error_to_stderr(message)
      end

      private

      def emit_error_to_stderr(message)
        ActiveSupport::Logger.new($stderr).error(message)
      end
    end
  end
end
