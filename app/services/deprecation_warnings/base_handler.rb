# frozen_string_literal: true

# @abstract Subclass and override {.call} to implement a custom DeprecationWarnings handler class.
# @note For use with `ActiveSupport::Deprecation.behavior=`.
module DeprecationWarnings
  class BaseHandler
    class << self
      # Subclasses must respond to `.call` to play nice with `ActiveSupport::Deprecation.behavior=`.
      #   https://github.com/rails/rails/blob/a4581b53aae93a8dd3205abae0630398cbce9204/activesupport/lib/active_support/deprecation/behaviors.rb#L70-L71
      def call(message, callstack, deprecation_horizon, gem_name)
        raise NotImplementedError
      end

      # Subclasses must respond to `.arity` to play nice with `ActiveSupport::Deprecation.behavior=`.
      #   Must return number of arguments accepted by `.call`.
      #   https://github.com/rails/rails/blob/a4581b53aae93a8dd3205abae0630398cbce9204/activesupport/lib/active_support/deprecation/behaviors.rb#L101
      def arity
        method(:call).arity
      end
    end
  end
end
