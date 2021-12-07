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
      target.vacols_id = original.vacols_id if original.appeal_type == "LegacyAppeal"
      target.work_product = original.work_product

      target
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: attorney_case_reviews
#
#  id                        :bigint           not null, primary key
#  appeal_type               :string           not null, indexed
#  attorney_full_name        :string(255)      not null
#  attorney_sattyid          :string(20)
#  document_type             :string(20)       indexed
#  note                      :text
#  overtime                  :boolean
#  review_created_at         :datetime         not null, indexed
#  review_updated_at         :datetime         not null, indexed
#  reviewing_judge_full_name :string(255)      not null
#  reviewing_judge_sattyid   :string(20)
#  untimely_evidence         :boolean
#  work_product              :string(20)
#  created_at                :datetime         not null, indexed
#  updated_at                :datetime         not null, indexed
#  appeal_id                 :bigint           not null, indexed
#  attorney_css_id           :string(50)       not null
#  attorney_id               :bigint           not null, indexed
#  document_reference_id     :string(50)
#  review_id                 :bigint           not null, indexed
#  reviewing_judge_css_id    :string(50)       not null
#  reviewing_judge_id        :bigint           not null, indexed
#  task_id                   :string           not null, indexed
#  vacols_id                 :string           indexed
#
