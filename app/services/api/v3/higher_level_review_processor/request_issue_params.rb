# frozen_string_literal: true

# This module encapsulates the methods and constants used by the
# HigherLevelReviewProcessor for manipulating and validating RequestIssue
# parameters received by the Decision Review API (v3).
# It is not intended to be used as a mixin.
#
# Most of the methods below are in support of:
#
# RequestIssueParams::ApiShape.to_intakes_controller_shape
#   for converting an API-style request issue params object to an
#   IntakesController-style request issue params obje
#
# RequestIssueParams::IntakesControllerShape.validate
#   returns a an Error or nil

module Api::V3::HigherLevelReviewProcessor::RequestIssueParams
  PERMITTED_API_KEYS = [
    :notes,
    :decision_issue_id,
    :rating_issue_id,
    :legacy_appeal_id,
    :legacy_appeal_issue_id,
    :category,
    :decision_date,
    :decision_text
  ].freeze

  API_KEY_TO_INTAKES_CONTROLLER_KEY = {
    decision_issue_id: :contested_decision_issue_id,
    rating_issue_id: :rating_issue_reference_id,
    legacy_appeal_id: :vacols_id,
    legacy_appeal_issue_id: :vacols_sequence_id,
    category: :nonrating_issue_category
  }.freeze

  def self.api_key_to_intakes_controller_key(key)
    API_KEY_TO_INTAKES_CONTROLLER_KEY[key] || key
  end

  # methods for request issue params that are API shaped

  #   {
  #     type: "RequestIssue"
  #       attributes: {
  #         notes
  #         decision_issue_id
  #         rating_issue_id
  #         legacy_appeal_id
  #         legacy_appeal_issue_id
  #         category
  #         decision_date
  #         decision_text
  #       }
  #     }
  #   }

  module ApiShape
    def self.to_intakes_controller_shape(api_request_issue_params, benefit_type)
      intakes_controller_params = ActionController::Parameters.new

      api_request_issue_params[:attributes].permit(PERMITTED_API_KEYS).each do |key, value|
        intakes_controller_params[parent.api_key_to_intakes_controller_key(key.to_sym)] = value
      end

      intakes_controller_params.merge(
        is_unidentified: IntakesControllerShape.unidentified?(intakes_controller_params),
        benefit_type: benefit_type
      )
    end
  end

  # methods for request issue params that are IntakesController shaped:

  #   {
  #     rating_issue_reference_id: nil,
  #     rating_issue_diagnostic_code: nil,
  #     decision_text: nil,
  #     decision_date: nil,
  #     nonrating_issue_category: nil,
  #     benefit_type: nil,
  #     notes: nil,
  #     is_unidentified: nil,
  #     untimely_exemption: nil,
  #     untimely_exemption_notes: nil,
  #     ramp_claim_id: nil,
  #     vacols_id: nil,
  #     vacols_sequence_id: nil,
  #     contested_decision_issue_id: nil,
  #     ineligible_reason: nil,
  #     ineligible_due_to_id: nil,
  #     edited_description: nil,
  #     correction_type: nil
  #   }

  module IntakesControllerShape
    def self.unidentified?(params)
      [
        :contested_decision_issue_id,
        :rating_issue_reference_id,
        :vacols_id,
        :vacols_sequence_id,
        :nonrating_issue_category
      ].all? { |key| params[key].blank? }
    end

    def self.validate(params, legacy_opt_in_approved)
      [:all_fields_are_blank, :invalid_category, :no_ids].each do |test|
        error_code = Validate.send(test, params)
        next unless error_code

        return Api::V3::HigherLevelReviewProcessor::Error.from_error_code(error_code)
      end

      error_code = Validate.invalid_legacy_fields_or_no_opt_in(params, legacy_opt_in_approved)
      error_code && Api::V3::HigherLevelReviewProcessor::Error.from_error_code(error_code)
    end

    # helper methods for IntakesControllerShape.validate
    # these all return nil (on success) or an error code

    module Validate
      def self.all_fields_are_blank(params)
        params.values.all?(&:blank?) ? :request_issue_cannot_be_empty : nil
      end

      def self.invalid_category(params)
        category, benefit_type = params.values_at(:nonrating_issue_category, :benefit_type)
        return nil if category.blank? || category.in?(
          Api::V3::HigherLevelReviewProcessor::CATEGORY_BY_BENEFIT_TYPE[benefit_type]
        )

        :unknown_category_for_benefit_type
      end

      def self.no_ids(params)
        return :request_issues_without_an_id_are_invalid if [
          :contested_decision_issue_id,
          :rating_issue_reference_id,
          :vacols_id,
          :vacols_sequence_id
        ].all? { |id_key| params[id_key].blank? }

        nil
      end

      def self.invalid_legacy_fields_or_no_opt_in(params, legacy_opt_in_approved)
        id, seq = params.values_at(:vacols_id, :vacols_sequence_id)
        return nil if valid_legacy_fields?(id, seq, legacy_opt_in_approved)
        return :if_specifying_a_legacy_appeal_issue_id_must_specify_a_legacy_appeal_id if id.blank?
        return :if_specifying_a_legacy_appeal_id_must_specify_a_legacy_appeal_issue_id if seq.blank?

        :adding_legacy_issue_without_opting_in
      end

      def self.valid_legacy_fields?(id, seq, legacy_opt_in_approved)
        !!(id.blank? && seq.blank? || id.present? && seq.present? && legacy_opt_in_approved)
      end
    end
  end
end
