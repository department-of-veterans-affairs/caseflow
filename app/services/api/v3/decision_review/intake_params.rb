# frozen_string_literal: true

class Api::V3::DecisionReview::IntakeParams
  attr_reader :errors

  # expects ActionController::Parameters
  def initialize(params)
    @params = params
    @errors = []
    validate
  end

  def errors?
    errors.any?
  end

  def veteran_file_number
    veteran[:data][:id].to_s
  end

  # params for IntakesController#review
  def review_params
    ActionController::Parameters.new(
      receipt_date: attributes[:receiptDate] || Time.zone.now.strftime("%Y-%m-%d"),
      informal_conference: attributes[:informalConference],
      same_office: attributes[:sameOffice],
      benefit_type: attributes[:benefitType],
      claimant: claimant_participant_id,
      payee_code: claimant_payee_code,
      veteran_is_not_claimant: claimant_participant_id.present? || claimant_payee_code.present?,
      legacy_opt_in_approved: legacy_opt_in?
    )
  end

  # params for IntakesController#complete
  def complete_params
    ActionController::Parameters.new(
      request_issues: request_issues.map(&:intakes_controller_params)
    )
  end

  private

  #  minimum required shape:
  #  
  #  {
  #    data: {
  #      type: "HigherLevelReview",
  #      attributes: {...},
  #      relationships: {
  #        veteran: {
  #          data: {
  #            type: "Veteran",
  #            id: ...
  #          }
  #        }
  #      }
  #    }
  #  }

  def minimum_required_shape?
    params_valid? &&
    data_valid? &&
    attributes_valid? &&
    relationships_valid? &&
    veteran_object_valid?
  end

  def params_valid?
    @params.respond_to?(:has_key?)
  end

  def data
    @params[:data]
  end

  def data_valid?
    data.respond_to?(:has_key?) && data[:type] == "HigherLevelReview"
  end

  def attributes
    data[:attributes]
  end

  def attributes_valid?
    attributes.respond_to?(:has_key?)
  end

  def relationships
    data[:relationships]
  end

  def relationships_valid?
    relationships.respond_to?(:has_key?)
  end

  def veteran
    relationships[:veteran]
  end

  def veteran_object_valid?
    veteran.respond_to?(:has_key?) &&
    veteran[:data].respond_to?(:has_key?) &&
    veteran[:data][:type] == "Veteran" &&
    veteran[:data][:id].present?
  end

  def claimant
    relationships[:claimant]
  end

  def claimant_object_valid?
    claimant.respond_to?(:has_key?) &&
    claimant[:data].respond_to?(:has_key?) &&
    claimant[:data][:type] == "Claimant" &&
    claimant[:data][:id].present? &&
    claimant[:data][:meta].respond_to?(:has_key?) &&
    claimant[:data][:meta][:payeeCode].present?
  end
    
  def claimant_participant_id
    claimant && claimant[:data][:id]
  end

  def claimant_payee_code
    claimant && claimant[:data][:meta][:payeeCode]
  end

  def included
    @params[:included] || []
  end

  def included_valid?
    @params[:included].nil? ||
    (@params[:included].is_a?(Array) && included.all? {|obj| obj.respond_to? :has_key?})
  end

  def legacy_opt_in?
    # tweaked for happy path: legacy_opt_in_approved always true (regardless of input) for happy path
    # attributes[:legacyOptInApproved]
    true
  end

  def request_issues
    @request_issues ||= included
      .select { |obj| obj[:type] == "RequestIssue" }
      .map do |obj|
        Api::V3::DecisionReview::RequestIssueParams.new(
          request_issue: obj,
          benefit_type: attributes[:benefitType],
          legacy_opt_in_approved: legacy_opt_in?
        )
      end
  end

  def validate
    unless (
      minimum_required_shape? &&
      (!claimant || claimant_object_valid?) &&
      included_valid? &&
      (
        begin
          request_issues
          true
        rescue
          false
        end
      )
    )
      @errors << Api::V3::DecisionReview::IntakeError.new(:malformed_request)
      return
    end

    @errors += request_issue_errors
  end

  def request_issue_errors
    request_issues.select(&:error_code).map do |request_issue|
      Api::V3::DecisionReview::IntakeError.new(request_issue)
    end
  end
end
