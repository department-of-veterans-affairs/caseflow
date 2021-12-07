# frozen_string_literal: true

# copy of decision_documents

class ETL::DecisionDocument < ETL::Record
  class << self
    private

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/PerceivedComplexity
    def merge_original_attributes_to_target(original, target)
      # To-do: ETL legacy appeals; AMA appeals are sufficient for now
      return unless original.appeal_type == "Appeal"

      target.attributes = original.attributes.reject { |key| %w[created_at updated_at].include?(key) }
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

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: decision_documents
#
#  id                           :bigint           not null, primary key
#  appeal_type                  :string           not null, indexed => [appeal_id]
#  attempted_at                 :datetime
#  canceled_at                  :datetime
#  citation_number              :string           not null, indexed
#  decision_date                :date             not null, indexed
#  decision_document_created_at :datetime         indexed
#  decision_document_updated_at :datetime         indexed
#  docket_number                :string
#  error                        :string
#  last_submitted_at            :datetime
#  processed_at                 :datetime
#  redacted_document_location   :string           not null
#  submitted_at                 :datetime
#  uploaded_to_vbms_at          :datetime
#  created_at                   :datetime         not null, indexed
#  updated_at                   :datetime         not null, indexed
#  appeal_id                    :bigint           not null, indexed => [appeal_type]
#  attorney_case_review_id      :bigint           not null, indexed
#  attorney_user_id             :bigint           indexed
#  judge_case_review_id         :bigint           not null, indexed
#  judge_user_id                :bigint           indexed
#
