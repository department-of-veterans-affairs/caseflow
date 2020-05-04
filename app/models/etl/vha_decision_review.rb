# frozen_string_literal: true

# Model to capture reporting data scoped to those Decision Reviews (Appeal, HLR, SC)
# that have an associated benefit type corresponding to VHA.
#
# This includes the following tables:
#   * HIGHER_LEVEL_REVIEWS: Intake data for Higher level Reviews
#   * SUPPLEMENTAL CLAIMS: Intake data for Supplemental Claims
#   * APPEALS: Used to keep track of information for AMA appeals
#   * DECISION_ISSUES: Issue-level dispositions for AMA claims/appeals
#   * REMAND_REASONS: Remand reason for decision issues.
#
# To make it simple for VHA to pull the data they need, we're reporting data as a single table.

class ETL::VhaDecisionReview < ETL::Record
  class << self

    private

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def merge_original_attributes_to_target(original, target)

      target.decision_review_id = original.id
      target.decision_review_type = original.class.name

      [
        # common Appeal, HLR, and SC attributes
        :benefit_type,
        :establishment_processed_at,
        :establishment_submitted_at,
        :legacy_opt_in_approved,
        :receipt_date,
        :uuid,
        :veteran_file_number,
        :veteran_is_not_claimant,
      ].each do |attr|
        target[attr] = original[attr]
      end

      [
        # attributes unique to HLR
        :informal_conference,
        :same_office,

        # attributes unique to SC
        :decision_review_remanded_id,
        :decision_review_remanded_type,

        # attributes unique to Appeal
        :closest_regional_office,
        :docket_range_date,
        :docket_type,
        :established_at,
        :poa_participant_id,
        :stream_docket_number,
        :stream_type,
        :target_decision_date
      ].each do |attr|
        target[attr] = original[attr] if original.respond_to?(:attr)
      end

      # TODO: check if results from each model's methods should be captured in a column

      # DecisionIssue attributes
      decision_issues = DecisionIssue.where(decision_review_type: target[:decision_review_type], decision_review_id: target[:decision_review_id])
      # TODO: add decision_issues?
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end