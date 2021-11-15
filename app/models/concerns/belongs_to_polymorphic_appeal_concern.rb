# frozen_string_literal: true

require "helpers/association_wrapper.rb"

##
# This concern dynamically defines the following when `belongs_to_polymorphic_appeal :appeal` is called,
# where `base_table_name` is the table name of the model that is including this concern:

#   belongs_to :appeal, polymorphic: true
#
#   scope :ama, -> { where(type_column => "Appeal") }
#   scope :legacy, -> { where(type_column => "LegacyAppeal") }
#   belongs_to :ama_appeal,
#      -> { includes(association_name).where(base_table_name => {'appeal_type' => "Appeal"}) },
#      class_name: "Appeal", foreign_key: 'appeal_id', optional: true
#   belongs_to :legacy_appeal,
#      -> { includes(association_name).where(base_table_name => {'appeal_type' => "LegacyAppeal"}) },
#      class_name: "LegacyAppeal", foreign_key: 'appeal_id', optional: true
#
#   def ama_appeal
#     super() if self.send(type_column) == "Appeal"
#   end
#   def legacy_appeal
#     super() if self.send(type_column) == "LegacyAppeal"
#   end
#
# When calling `belongs_to_polymorphic_appeal :decision_review`, it defines similar associations to HLR and SC.
#
# These associations enable, for example, `has_many ama_decision_issues through: :ama_appeal`, which provides
# 1. easy access to associated records through a polymorphic association and
# 2. efficient queries when joining with other tables
# See RSpec for examples.

module BelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern

  include BelongsToPolymorphicConcern

  class_methods do
    # Since we can't pass an argument to a concern, call this method instead
    def belongs_to_polymorphic_appeal(associated_class_symbol, include_decision_review_classes: false)
      # Define polymorphic association before calling AssocationWrapper
      belongs_to associated_class_symbol, polymorphic: true

      associated_class = associated_class_symbol.to_s.classify.constantize
      association = AssocationWrapper.new(self).belongs_to.polymorphic.associated_with_type(associated_class)
        .select_associations.first

      type_column = association.foreign_type
      scope :ama, -> { where(type_column => "Appeal") }
      scope :legacy, -> { where(type_column => "LegacyAppeal") }

      # Use `:ama_appeal` instead of `:appeal`
      # because `.appeal` is already defined by `belongs_to associated_class_symbol, polymorphic: true` above
      add_method_for_polymorphic_association("Appeal", association, :ama_appeal)
      add_method_for_polymorphic_association("LegacyAppeal", association)

      if include_decision_review_classes || associated_class_symbol == :decision_review
        scope :supplemental_claim, -> { where(type_column => "SupplementalClaim") }
        scope :higher_level_review, -> { where(type_column => "HigherLevelReview") }

        add_method_for_polymorphic_association("SupplementalClaim", association)
        add_method_for_polymorphic_association("HigherLevelReview", association)
      end
    end
  end
end
