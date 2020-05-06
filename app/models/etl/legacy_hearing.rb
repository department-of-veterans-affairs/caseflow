# frozen_string_literal: true

# transformed Hearing model, with associations "flattened" for reporting.

class ETL::LegacyHearing < ETL::Hearing
  class << self
    def mirrored_hearing_attributes
      super + [:vacols_id]
    end

    private

    def merge_original_attributes_to_target(original, target)
      super

      target.judge_id = original.user_id
      target.scheduled_time = original.scheduled_for

      target
    end
  end
end
