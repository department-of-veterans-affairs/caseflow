# frozen_string_literal: true

##
# See BelongsToPolymorphicAppealConcern and BelongsToPolymorphicHearingConcern for uses of this module

module BelongsToPolymorphicConcern
  extend ActiveSupport::Concern

  class_methods do
    private

    # This method creates a belongs_to association. For example, for type_name = "Appeal":
    # belongs_to :ama_appeal,
    #            -> { includes(association_name).where(base_table_name => {type_column => "Appeal"}) },
    #            class_name: "Appeal", foreign_key: id_column.to_s, optional: true
    def add_method_for_polymorphic_association(type_name, association, method_name = type_name.underscore.to_sym)
      type_column = association.foreign_type
      id_column = association.foreign_key
      # Define self_table_name here so it can be used in the belongs_to lambda, where `self.table_name` is different
      self_table_name = table_name

      belongs_to method_name,
                 -> { where(self_table_name => { type_column => type_name }) },
                 class_name: type_name, foreign_key: id_column.to_s, optional: true
    end
  end
end
