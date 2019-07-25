# frozen_string_literal: true

class Api::HigherLevelReviewError
  ERRORS = lambda do
    # grab our spec
    spec = YAML.safe_load File.read "app/controllers/api/docs/v3/decision_reviews.yaml"
    responses = spec.dig("paths", "/higher_level_reviews", "post", "responses")
    fail StandardError, "couldn't load the responses for HLRs from decision_reviews.yaml" unless responses

    # gather the errors in this format:
    #   [
    #     {"status"=>"404", "title"=>"Veteran File not found", "code"=>"veteran_not_found"},
    #     {"status"=>"422", "title"=>"Unknown error", "code"=>"unknown_error"},
    #     ...
    #   ]
    # and do some validation of decision_reviews.yaml
    errors = responses.reduce([]) do |acc, (status_code, status_body)|
      first_digit_of_status_code = status_code.to_s[0]
      next acc unless first_digit_of_status_code.match?(/4|5/) # skip if response isn't an error

      examples_hash = status_body.dig("content", "application/vnd.api+json", "examples")
      next acc unless examples_hash # skip if there are no examples

      acc + examples_hash.map do |_title, value_hash| # accumulate
        error_hash = value_hash.dig("value", "errors", 0)
        fail StandardError, "invalid error: <#{error_hash}>" unless
            error_hash &&
            error_hash.key?("title") &&
            error_hash.key?("code") &&
            error_hash.key?("status") &&
            (error_hash["status"] = error_hash["status"].to_i) >= 400

        error_hash
      end
    end

    fail StandardError, "decision_reviews.yaml doesn't define any errors for HLRs" if errors.empty?

    # set ERRORS to this format (lookup by code)
    #   {
    #     "unauthenticated"=>{"status"=>401, "title"=>"Unauthenticated"},
    #     "veteran_not_accessible"=>{"status"=>403, "title"=>"Veteran File inaccessible"},
    #     ...
    #   }
    # validate that an error code is never used more than once
    errors.reduce({}) do |errors_by_code, error_hash|
      code = error_hash["code"]
      fail StandardError, "non-unique error code: <#{code}>" if errors_by_code.key? code

      errors_by_code.merge(code => error_hash.except("code"))
    end
  end.call

  DEFAULT_ERROR = lambda do
    default_code = "unknown_error"
    ERRORS[default_code].merge code: default_code
  end.call
end
