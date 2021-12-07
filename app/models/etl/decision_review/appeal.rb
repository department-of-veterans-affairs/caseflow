# frozen_string_literal: true

class ETL::DecisionReview::Appeal < ETL::DecisionReview
  class << self
    def unique_attributes
      [
        :closest_regional_office,
        :docket_range_date,
        :docket_type,
        :established_at,
        :poa_participant_id,
        :stream_docket_number,
        :stream_type,
        :target_decision_date
      ]
    end

    def merge_original_attributes_to_target(original, target)
      super

      target.benefit_type = original.request_issues.pluck(:benefit_type).uniq.join(",")

      target
    end
  end
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: decision_reviews
#
#  id                            :bigint           not null, primary key
#  benefit_type                  :string           not null
#  closest_regional_office       :string           indexed
#  decision_review_created_at    :datetime         indexed
#  decision_review_remanded_type :string           indexed => [decision_review_remanded_id]
#  decision_review_type          :string           not null, indexed => [decision_review_id]
#  decision_review_updated_at    :datetime         indexed
#  docket_range_date             :date             indexed
#  docket_type                   :string           indexed
#  established_at                :datetime         indexed
#  establishment_processed_at    :datetime
#  establishment_submitted_at    :datetime
#  informal_conference           :boolean          indexed
#  legacy_opt_in_approved        :boolean          indexed
#  receipt_date                  :date             indexed
#  same_office                   :boolean          indexed
#  stream_docket_number          :string           indexed
#  stream_type                   :string           indexed
#  target_decision_date          :date             indexed
#  uuid                          :uuid             not null, indexed
#  veteran_file_number           :string           not null, indexed
#  veteran_is_not_claimant       :boolean          indexed
#  created_at                    :datetime         not null, indexed
#  updated_at                    :datetime         not null, indexed
#  decision_review_id            :bigint           not null, indexed => [decision_review_type]
#  decision_review_remanded_id   :bigint           indexed => [decision_review_remanded_type]
#  poa_participant_id            :string           indexed
#
