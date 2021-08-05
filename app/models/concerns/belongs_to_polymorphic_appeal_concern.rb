# frozen_string_literal: true

require "helpers/association_wrapper.rb"

module BelongsToPolymorphicAppealConcern
  extend ActiveSupport::Concern

  class_methods do
    # call this after `belongs_to ..., polymorphic: true`
    def associated_appeal_class(associated_class)
      association = AssocationWrapper.new(self).belongs_to.polymorphic.associated_with_type(associated_class)
        .select_associations.first

      appeal_type_column = association.foreign_type
      scope :ama, -> { where(appeal_type_column => "Appeal") }
      scope :legacy, -> { where(appeal_type_column => "LegacyAppeal") }

      add_method_for_polymorphic_association("Appeal", association)
      add_method_for_polymorphic_association("LegacyAppeal", association)

      if associated_class == DecisionReview
        # add_method_for_polymorphic_association("SupplementalClaim", association)
        # This breaks things: add_method_for_polymorphic_association("HigherLevelReview", association)
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
      method_name = (type_name == "Appeal") ? :ama_appeal : type_name.underscore.to_sym
      type_column = association.foreign_type
      id_column = association.foreign_key
      # Define self_table_name here so it can be used in the belongs_to lambda, where `self.table_name` is different.
      self_table_name = table_name

      # pp "#{self_table_name} #{method_name}"
      # binding.pry if type_name == "HigherLevelReview"
      belongs_to method_name, -> { includes(self_table_name).where(self_table_name => { type_column => type_name }) },
                 class_name: type_name, foreign_key: id_column.to_s, optional: true

      define_method method_name do
        # `super()` will call the method created by the `belongs_to` above
        super() if send(type_column) == type_name
      end
    end
  end
end
