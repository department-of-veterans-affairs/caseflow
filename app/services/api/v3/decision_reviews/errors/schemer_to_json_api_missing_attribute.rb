# frozen_string_literal: true

class Api::V3::DecisionReviews::Errors::SchemerToJsonApiMissingAttribute < StandardError
  attr_accessor :code
  attr_accessor :details

  def initialize(details)
    @code = 422
    @details = details
  end

  def all_errors
    required_errors, other_errors = details.partition { |detail| self.class.required_error?(detail) }
    errors = []
    unless required_errors.empty?
      errors.concat(required_errors.map { |error| self.class.build_required_errors(error) }.reduce(:concat))
    end
    errors.concat(other_errors.map { |error| self.class.build_error(error) })
    errors.uniq
  end

  class << self
    def to_human(detail)
      if detail["type"] == "required"
        "The property #{to_source(detail)} did not contain the required key #{detail['details']['missing_key']}"
      else
        "The property #{detail['data_pointer']} did not match the following requirements #{detail['schema']}"
      end
    end

    def to_source(detail)
      detail["data_pointer"].empty? ? "/" : detail["data_pointer"]
    end

    def build_error(detail)
      {
        status: 422,
        detail: to_human(detail),
        source: to_source(detail)
      }
    end

    def build_required_errors(required_error)
      required_error["details"]["missing_keys"].map do |missing_key|
        build_error(
          "type" => "required",
          "data_pointer" => required_error["data_pointer"],
          "details" => { "missing_key" => missing_key }
        )
      end
    end

    def required_error?(detail)
      detail["type"] == "required"
    end
  end
end
