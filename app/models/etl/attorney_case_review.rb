# frozen_string_literal: true

# transformed AttorneyCaseReview model, with denormalized User attributes

class ETL::AttorneyCaseReview < ETL::Record
  class << self
    def origin_primary_key
      :review_id
    end

    private

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def merge_original_attributes_to_target(original, target)
      # memoize to save SQL calls
      attorney = user_cache(original.attorney_id)
      judge = user_cache(original.reviewing_judge_id)
      appeal = original.appeal

      target.appeal_id = original.appeal_id
      target.appeal_type = original.appeal_type
      target.attorney_css_id = attorney.css_id
      target.attorney_full_name = attorney.full_name
      target.attorney_id = attorney.id
      target.attorney_sattyid = attorney.vacols_user&.sattyid
      target.document_reference_id = original.document_id
      target.document_type = original.document_type
      target.note = original.note
      target.overtime = original.overtime
      target.review_created_at = original.created_at
      target.review_id = original.id
      target.review_updated_at = original.updated_at
      target.reviewing_judge_css_id = judge.css_id
      target.reviewing_judge_full_name = judge.full_name
      target.reviewing_judge_id = judge.id
      target.reviewing_judge_sattyid = judge.vacols_user&.sattyid
      target.task_id = original.task_id
      target.untimely_evidence = original.untimely_evidence
      target.vacols_id = original.vacols_id if appeal.is_a?(LegacyAppeal)
      target.work_product = original.work_product

      target
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end
