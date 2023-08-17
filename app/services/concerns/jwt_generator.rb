# frozen_string_literal: true

module JwtGenerator
  extend ActiveSupport::Concern

  module ClassMethods
    # Purpose: Remove any illegal characters and keeps source at proper format
    #
    # Params: string
    #
    # Return: sanitized string
    def base64url(source)
      encoded_source = Base64.encode64(source)
      encoded_source = encoded_source.sub(/=+$/, "")
      encoded_source = encoded_source.tr("+", "-")
      encoded_source = encoded_source.tr("/", "_")
      encoded_source
    end
  end
end
