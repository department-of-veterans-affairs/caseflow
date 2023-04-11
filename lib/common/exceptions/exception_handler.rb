# frozen_string_literal: true

require 'common/client/errors'

module Common
  module Exceptions
    class ExceptionHandler
      attr_reader :error, :service

      # @param error [ErrorClass] An external service error
      # @param service [String] The name of the external service
      #
      def initialize(error, service)
        @error = validate!(error)
        @service = service
      end

      # Serializes the initialized error into one of the predetermined error types.
      #
      # The serialized error format is modelled after the Maintenance Windows schema,
      # per the FE's request.
      #
      # @return [Hash] A serialized version of the initialized error. Follows maintenance
      # window schema.
      # @see https://department-of-veterans-affairs.github.io/va-digital-services-platform-docs/api-reference/#/site/getMaintenanceWindows
      #
      def serialize_error
        case error
        when Common::Exceptions::BaseError
          base_error
        when Common::Client::Errors::ClientError
          client_error
        else
          standard_error
        end
      end

      private

      def validate!(error)
        raise Common::Exceptions::ParameterMissing.new('error'), 'error' if error.blank?

        error
      end

      def base_error
        exception = error.errors.first

        "#{service}: #{exception.title}, #{exception.detail}"
      end

      def client_error
        "#{service}: #{error.message}, #{error.body}"
      end

      def standard_error
        "#{service}: #{error.message}, #{error}"
      end
    end
  end
end
