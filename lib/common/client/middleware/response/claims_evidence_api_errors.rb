# frozen_string_literal: true

module Common
  module Client
    module Middleware
      module Response
        class ClaimsEvidenceApiErrors < Faraday::Response::Middleware
          def on_complete(env)
            return if env.success?

            mapped_error = env[:body]['error']
            return if mapped_error.nil?

            env[:body]['code'] = mapped_error['code']
            env[:body]['detail'] = mapped_error['message']
          end
        end
      end
    end
  end
end
