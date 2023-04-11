# frozen_string_literal: true

module ClaimsEvidenceApi
  # Core class responsible for api interface operations
  class Client < Common::Client::Base
    configuration ScorecardApi::Configuration

    def schools(params = {})
      perform(:get, 'schools', merged_params(params))
    end

    private

    # api_key is created by following instructions at https://collegescorecard.ed.gov/data/documentation/
    def merged_params(params = {})
      params.merge(api_key: Settings.scorecard.api_key)
    end
  end
end
