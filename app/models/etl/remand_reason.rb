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

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: remand_reasons
#
#  id                       :bigint           not null, primary key
#  code                     :string(30)       indexed
#  post_aoj                 :boolean          indexed
#  remand_reason_created_at :datetime         indexed
#  remand_reason_updated_at :datetime         indexed
#  created_at               :datetime         not null, indexed
#  updated_at               :datetime         not null, indexed
#  decision_issue_id        :integer          indexed
#
