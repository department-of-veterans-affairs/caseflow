# frozen_string_literal: true

# transformed Hearing model, with associations "flattened" for reporting.

class ETL::LegacyHearing < ETL::Hearing
  class << self
    private

    def merge_original_attributes_to_target(original, target)
      super
    rescue Caseflow::Error::VacolsRecordNotFound => error
      Rails.logger.error(error)
      target
    ensure
      # whether we catch an error or not, make sure these are populated
      target.hearing_request_type ||= "unknown"
      target.vacols_id = original.vacols_id
      target.scheduled_time = original.scheduled_for
      target.judge_id = original.user_id
      target
    end
  end
end
