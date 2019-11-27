# frozen_string_literal: true

class Api::V3::DecisionReview::RequestIssueParams
  class << self
    def shape_valid?(obj)
      obj.is_a?(ActionController::Parameters) &&
        obj[:type] == "RequestIssue" &&
        obj[:attributes].respond_to?(:has_key?)
    end

  end

  attr_reader :error_code

  def initialize(request_issue:, benefit_type:, legacy_opt_in_approved:)
    unless self.class.shape_valid?(request_issue)
      @error_code = :request_issue_malformed # error_code
      return
    end

    @attributes = request_issue[:attributes].permit(PERMITTED_KEYS)
    @benefit_type = benefit_type
    @legacy_opt_in_approved = legacy_opt_in_approved

    validate_fields
  end

  def intakes_controller_params
    @attributes.as_json.each_with_object(ActionController::Parameters.new) do |(key, value), params|
      params[self.class.intakes_controller_style_key(key)] = value
    end.merge(is_unidentified: unidentified?, benefit_type: @benefit_type)
  end

  private

end
