# frozen_string_literal: true

require "helpers/association_wrapper.rb"

module BelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern

  class_methods do
    # Since we can't pass an argument to a concern, call this method instead
    def belongs_to_polymorphic_appeal(associated_class_symbol, include_decision_review_classes: false)
      # Define polymorphic association before calling AssocationWrapper
      belongs_to associated_class_symbol, polymorphic: true

      unless self.reflect_on_association(:self_ref)
        has_one :self_ref, class_name: self.name, foreign_key: :id
      end

      associated_class = associated_class_symbol.to_s.classify.constantize
      association = AssocationWrapper.new(self).belongs_to.polymorphic.associated_with_type(associated_class)
        .select_associations.first

      type_column = association.foreign_type
      scope :ama, -> { where(type_column => "Appeal") }
      scope :legacy, -> { where(type_column => "LegacyAppeal") }

      # Use `:ama_appeal` instead of `:appeal`
      # because `.appeal` is already defined by `belongs_to associated_class_symbol, polymorphic: true` above
      has_one :ama_appeal, through: :self_ref, source: associated_class_symbol, source_type: "Appeal"
      has_one :legacy_appeal, through: :self_ref, source: associated_class_symbol, source_type: "LegacyAppeal"

      if include_decision_review_classes || associated_class_symbol == :decision_review
        scope :supplemental_claim, -> { where(type_column => "SupplementalClaim") }
        scope :higher_level_review, -> { where(type_column => "HigherLevelReview") }

        has_one :supplemental_claim, through: :self_ref, source: associated_class_symbol, source_type: "SupplementalClaim"
        has_one :higher_level_review, through: :self_ref, source: associated_class_symbol, source_type: "HigherLevelReview"
      end
    end
  end
end
