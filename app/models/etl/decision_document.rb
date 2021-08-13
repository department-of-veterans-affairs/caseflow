# frozen_string_literal: true

# copy of decision_documents

class ETL::DecisionDocument < ETL::Record
  class << self
    private

    def merge_original_attributes_to_target(original, target)
      target.attributes = original.attributes.reject { |key| %w[created_at updated_at].include?(key) }
      target.decision_document_created_at = original.created_at
      target.decision_document_updated_at = original.updated_at

      target.docket_number = original.appeal.stream_docket_number

      judge_case_review = original.appeal.latest_judge_case_review
      target.judge_case_review_id = judge_case_review.id
      target.attorney_case_review_id = original.appeal.latest_attorney_case_review.id

      target.judge_user_id = judge_case_review.judge.id
      check_equal(original.id, "reviewing_judge_name",
        original.appeal.reviewing_judge_name, judge_case_review.judge.full_name)
      target.attorney_user_id = judge_case_review.attorney.id

      target
    end
  end
end
