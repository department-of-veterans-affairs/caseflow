# frozen_string_literal: true

# transformed Hearing model, with associations "flattened" for reporting.

class ETL::LegacyHearing < ETL::HearingRecord
  class << self
    private

    def merge_original_attributes_to_target(original, target)
      merge_original_attributes_to_target_shared(original, target)

      target.evidence_window_waived = nil
      target.scheduled_time = original.scheduled_for
      target.uuid = original.external_id

      target
    rescue Caseflow::Error::VacolsRecordNotFound => error
      Rails.logger.error(error)
      nil # skip this target
    end
  end
end
