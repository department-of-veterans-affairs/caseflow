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
#      -> { includes(base_table_name).where(base_table_name => {'appeal_type' => "Appeal"}) },
#      class_name: "Appeal", foreign_key: 'appeal_id', optional: true
#   belongs_to :legacy_appeal,
#      -> { includes(base_table_name).where(base_table_name => {'appeal_type' => "LegacyAppeal"}) },
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
# 1. easy access to decision_issues through a polymorphic association and
# 2. efficient queries when joining with other tables
# See RSpec for examples.

module BelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern

  class_methods do
    # Since we can't pass an argument to a concern, call this method instead
    def belongs_to_polymorphic_appeal(associated_class_symbol)
      # Define polymorphic association before calling AssocationWrapper
      belongs_to associated_class_symbol, polymorphic: true

      associated_class = associated_class_symbol.to_s.classify.constantize
      association = AssocationWrapper.new(self).belongs_to.polymorphic.associated_with_type(associated_class)
        .select_associations.first

      type_column = association.foreign_type
      scope :ama, -> { where(type_column => "Appeal") }
      scope :legacy, -> { where(type_column => "LegacyAppeal") }

      add_method_for_polymorphic_association("Appeal", association)
      add_method_for_polymorphic_association("LegacyAppeal", association)

      if associated_class_symbol == :decision_review
        add_method_for_polymorphic_association("SupplementalClaim", association)
        add_method_for_polymorphic_association("HigherLevelReview", association)
      end
    end

    private

    # This method creates a belongs_to association and method. For example, for type_name = "Appeal":
    # belongs_to :ama_appeal, -> { includes(base_table_name).where(base_table_name => {type_column => "Appeal"}) },
    #    class_name: "Appeal", foreign_key: id_column.to_s, optional: true
    #
    # def ama_appeal
    #   super() if self.send(type_column) == "Appeal"  # ensure nil is returned if type is not an AMA appeal
    # end
    #
    # For type_name = "SupplementalClaim", the method_name will be supplemental_claim.
    def add_method_for_polymorphic_association(type_name, association)
      # Use `:ama_appeal` instead of `:appeal`
      # because `.appeal` is already defined by `belongs_to associated_class_symbol, polymorphic: true` above
      method_name = (type_name == "Appeal") ? :ama_appeal : type_name.underscore.to_sym

      type_column = association.foreign_type
      id_column = association.foreign_key
      # Define self_table_name here so it can be used in the belongs_to lambda, where `self.table_name` is different
      self_table_name = table_name

      belongs_to method_name,
                 -> { includes(self_table_name).where(self_table_name => { type_column => type_name }) },
                 class_name: type_name, foreign_key: id_column.to_s, optional: true

      define_method method_name do
        # `super()` will call the method created by the `belongs_to` above
        super() if send(type_column) == type_name
      end

      # Access tasks without querying through appeal
      define_method :tasks do
        Task.where(appeal_id: send(id_column), appeal_type: send(type_column))
      end
    end
  end
end
