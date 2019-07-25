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

  attr_reader :status, :title, :code

  # only code needs to be specified
  # status and title can be specified, but, if they don't match what is pulled up from
  # ERRORS[code], an error will be thrown
  def initialize(options)
    @status, @title, @code = options.values_at :status, :title, :code
    validate_status
    validate_title
    validate_code
  end

  def inspect
    { status: status, title: title, code: code }
  end

  delegate :as_json, to: :inspect
  delegate :to_s, to: :inspect

  private

  def validate_status
    @status = @status.to_i
    fail ArgumentError, "invalid status: <#{status}>" unless status == ERRORS[code]["status"]
  end

  def validate_title
    fail ArgumentError, "invalid title: <#{title}>" unless title == ERRORS[code]["title"]
  end

  def validate_code
    fail ArgumentError, "invalid code: <#{code}>" unless ERRORS[code]
  end

  #   class << self
  #     def code_from_title(title)
  #       title.split(" ").join("_").downcase.gsub(/[^0-9a-z_]/i, "")
  #     end
  #
  #     def title_from_code(code)
  #       code.split("_").join(" ").capitalize
  #     end
  #
  #     # verifies that status is a valid one
  #     # note: instead of a boolean, it returns either nil (invalid status) or the status code swapped
  #     # --swapped as in:
  #     #   given something number-like, returns a symbol
  #     #   given something symbol-like, returns an int
  #     def valid_status(status)
  #       int = begin
  #               Integer status
  #             rescue
  #               nil
  #             end
  #       sym = status.to_sym
  #       Rack::Utils::HTTP_STATUS_CODES[int] || Rack::Utils::SYMBOL_TO_STATUS_CODE[sym]
  #     end
  #   end
end
