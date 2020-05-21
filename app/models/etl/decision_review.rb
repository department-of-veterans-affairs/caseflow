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
