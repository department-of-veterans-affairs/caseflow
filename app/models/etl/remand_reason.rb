# frozen_string_literal: true

# Copy of remand_reasons table

class ETL::RemandReason < ETL::Record
  class << self
    private

    def merge_original_attributes_to_target(original, target)
      target.attributes = original.attributes.reject { |key| %w[created_at updated_at].include?(key) }
      target.remand_reason_created_at = original.created_at
      target.remand_reason_updated_at = original.updated_at

      target
    end
  end
end
