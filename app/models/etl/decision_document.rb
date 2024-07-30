# frozen_string_literal: true

# copy of decision_documents

class ETL::DecisionDocument < ETL::Record
  class << self
    private

    ATTRS_TO_OMIT = %w[created_at updated_at
                       document_series_reference_id document_version_reference_id].freeze

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def merge_original_attributes_to_target(original, target)
      # To-do: ETL legacy appeals; AMA appeals are sufficient for now
      return unless original.appeal_type == "Appeal"

      target.attributes = original.attributes.reject { |key| ATTRS_TO_OMIT.include?(key) }
      target.decision_document_created_at = original.created_at
      target.decision_document_updated_at = original.updated_at

      appeal = original.appeal
      target.docket_number = appeal.docket_number

      judge_case_review = appeal.is_a?(Appeal) ? appeal.latest_judge_case_review : appeal.judge_case_review
      attorney_case_review = appeal.is_a?(Appeal) ? appeal.latest_attorney_case_review : appeal.attorney_case_review

      target.judge_case_review_id = judge_case_review&.id || 0
      target.judge_user_id = judge_case_review&.judge_id
      if appeal.is_a?(Appeal)
        check_equal(original.id, "reviewing_judge_name",
                    appeal.reviewing_judge_name, judge_case_review&.judge&.full_name)
      else
        target.judge_user_id ||= attorney_case_review&.reviewing_judge_id ||
                                 appeal.reviewing_judge.try(:assigned_by)&.assigned_by_user_id

        # To-do: appeal.vacols_case_review is also available
      end

      target.attorney_case_review_id = attorney_case_review&.id || 0
      # Prefer the latest attorney that touched the appeal
      target.attorney_user_id = judge_case_review&.attorney_id || attorney_case_review&.attorney_id

      if judge_case_review && attorney_case_review
        check_equal(original.id, "attorney_user_id", judge_case_review.attorney_id, attorney_case_review.attorney_id)
      end

      target
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
