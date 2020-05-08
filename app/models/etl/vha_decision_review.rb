# frozen_string_literal: true

# Model to capture reporting data scoped to those Decision Reviews (Appeal, HLR, SC)
# that have an associated benefit type corresponding to VHA.
#
# This includes the following tables:
#   * HIGHER_LEVEL_REVIEWS: Intake data for Higher level Reviews
#   * SUPPLEMENTAL CLAIMS: Intake data for Supplemental Claims
#   * APPEALS: Used to keep track of information for AMA appeals
#
# To make it simple for VHA to pull the data they need, we're reporting data as a single table.

class ETL::VhaDecisionReview < ETL::Record
  self.inheritance_column = :decision_review_type

  class << self
    def find_sti_class(type_name)
      super("ETL::Vha#{type_name}")
    end

    def sti_name
      name.delete_prefix("ETL::Vha")
    end

    def unique_attributes
      fail "subclass #{self} must implement unique_attributes method"
    end

    private

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
