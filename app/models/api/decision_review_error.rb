# frozen_string_literal: true

class Api::DecisionReviewError
  attr_reader :status, :title, :code

  # only code needs to be specified. status and title can be specified, but,
  # if they don't match what is pulled up from ERRORS[code], an exception
  # will be thrown
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
