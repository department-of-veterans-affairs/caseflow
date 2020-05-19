# frozen_string_literal: true

# transformed Hearing model, with associations "flattened" for reporting.

class ETL::LegacyHearing < ETL::Hearing
  class << self
    private

    def merge_original_attributes_to_target(original, target)
      super
    rescue Caseflow::Error::VacolsRecordNotFound => error
      Rails.logger.error(error)
      nil # skip this target
    end
  end
end
