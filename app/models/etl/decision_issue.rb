# frozen_string_literal: true

# copy of decision_issues

class ETL::DecisionIssue < ETL::Record
  class << self
    private

    def merge_original_attributes_to_target(original, target)
      target.attributes = original.attributes.reject { |key| %w[created_at updated_at deleted_at].include?(key) }
      target.issue_created_at = original.created_at
      target.issue_updated_at = original.updated_at
      target.issue_deleted_at = original.deleted_at

      target
    end
  end
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: decision_issues
#
#  id                           :bigint           not null, primary key
#  benefit_type                 :string(20)       indexed
#  caseflow_decision_date       :date
#  decision_review_type         :string(20)       indexed => [decision_review_id]
#  decision_text                :string
#  description                  :string
#  diagnostic_code              :string(20)
#  disposition                  :string(50)       indexed
#  end_product_last_action_date :date
#  issue_created_at             :datetime         indexed
#  issue_deleted_at             :datetime         indexed
#  issue_updated_at             :datetime         indexed
#  percent_number               :string
#  rating_profile_date          :datetime
#  rating_promulgation_date     :datetime
#  subject_text                 :text
#  created_at                   :datetime         not null, indexed
#  updated_at                   :datetime         not null, indexed
#  decision_review_id           :bigint           indexed => [decision_review_type]
#  participant_id               :bigint           not null, indexed
#  rating_issue_reference_id    :bigint           indexed
#
