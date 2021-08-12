# frozen_string_literal: true

# transformed JudgeCaseReview model, with denormalized User attributes

class ETL::JudgeCaseReview < ETL::Record
  belongs_to :actual_task, primary_key: :task_id, class_name: "ETL::Task"

  class << self
    def origin_primary_key
      :review_id
    end

    private

    def mirrored_hearing_attributes
      [
        :areas_for_improvement,
        :comment,
        :complexity,
        :factors_not_considered,
        :location,
        :one_touch_initiative,
        :positive_feedback,
        :quality
      ]
    end

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def merge_original_attributes_to_target(original, target)
      # memoize to save SQL calls
      attorney = user_cache(original.attorney_id)
      judge = user_cache(original.judge_id)
      appeal = original.appeal

      target.review_created_at = original.created_at
      target.review_updated_at = original.updated_at

      target.review_id = original.id

      target.judge_id = judge.id
      target.judge_css_id = judge.css_id
      target.judge_full_name = judge.full_name
      target.judge_sattyid = judge.vacols_user&.sattyid

      target.attorney_id = attorney.id
      target.attorney_css_id = attorney.css_id
      target.attorney_full_name = attorney.full_name
      target.attorney_sattyid = attorney.vacols_user&.sattyid

      target.original_task_id = original.task_id
      target.actual_task_id = original.task_id if appeal.is_a?(Appeal)
      target.vacols_id = original.vacols_id if appeal.is_a?(LegacyAppeal)

      target.appeal_id = appeal.id
      target.appeal_type = appeal.class.name

      mirrored_hearing_attributes.each do |attr|
        target[attr] = original.send(attr)
      end

      target
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
  end
end
