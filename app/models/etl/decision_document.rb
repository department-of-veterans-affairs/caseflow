# frozen_string_literal: true

# copy of decision_documents

class ETL::DecisionDocument < ETL::Record
  class << self
    private

    def merge_original_attributes_to_target(original, target)
      target.attributes = original.attributes.reject { |key| %w[created_at updated_at].include?(key) }
      target.decision_document_created_at = original.created_at
      target.decision_document_updated_at = original.updated_at

      appeal = original.appeal
      target.docket_number = appeal.docket_number

      attorney_case_review = if appeal.is_a?(Appeal)
                              appeal.latest_attorney_case_review
                            else
                              appeal.attorney_case_review
                            end
      target.attorney_case_review_id = attorney_case_review&.id || 0
      target.attorney_user_id = attorney_case_review&.attorney_id

      if appeal.is_a?(Appeal)
        judge_case_review = appeal.latest_judge_case_review
        target.judge_case_review_id = judge_case_review.id

        target.judge_user_id = judge_case_review.judge_id
        check_equal(original.id, "reviewing_judge_name",
                    appeal.reviewing_judge_name, judge_case_review.judge.full_name)
      else
        judge_case_review = appeal.judge_case_review
        target.judge_case_review_id = judge_case_review&.id || 0
        target.judge_user_id = judge_case_review&.judge_id || appeal.reviewing_judge.try(:assigned_by)&.assigned_by_user_id

        # To-do: appeal.vacols_case_review is also available
      end

      target
    end
  end
end
