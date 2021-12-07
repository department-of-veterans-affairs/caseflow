# frozen_string_literal: true

# Model for composite Decision Review (Appeal, SC or HLR)

class ETL::DecisionReview < ETL::Record
  self.inheritance_column = :decision_review_type

  class << self
    def find_sti_class(type_name)
      super("ETL::DecisionReview::#{type_name}")
    end

    def sti_name
      name.delete_prefix("ETL::DecisionReview::")
    end

    def unique_attributes
      fail "subclass #{self} must implement unique_attributes method"
    end

    private

    def find_by_primary_key(original)
      find_by(decision_review_type: original.class.name, decision_review_id: original.id)
    end

    def common_decision_review_attributes
      [
        :establishment_processed_at,
        :establishment_submitted_at,
        :legacy_opt_in_approved,
        :receipt_date,
        :uuid,
        :veteran_file_number,
        :veteran_is_not_claimant
      ]
    end

    def merge_original_attributes_to_target(original, target)
      target.decision_review_created_at = original.created_at
      target.decision_review_updated_at = original.updated_at

      target.decision_review_id = original.id
      target.decision_review_type = original.class.name

      common_decision_review_attributes.each do |attr|
        target[attr] = original[attr]
      end

      target.class.unique_attributes.each do |attr|
        target[attr] = original[attr]
      end

      # to do: based on VHA feedback we might need to add more calculated values

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
