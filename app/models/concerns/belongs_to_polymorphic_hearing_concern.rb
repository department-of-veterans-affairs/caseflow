# frozen_string_literal: true

require "helpers/association_wrapper.rb"

##
# This concern dynamically defines the following when `belongs_to_polymorphic_hearing :hearing` is called,
# where `base_table_name` is the table name of the model that is including this concern:

#   belongs_to :hearing, polymorphic: true
#
#   scope :ama, -> { where(type_column => "Hearing") }
#   scope :legacy, -> { where(type_column => "LegacyHearing") }
#   belongs_to :ama_hearing,
#      -> { includes(base_table_name).where(base_table_name => {'hearing_type' => "Hearing"}) },
#      class_name: "Hearing", foreign_key: 'hearing_id', optional: true
#   belongs_to :legacy_hearing,
#      -> { includes(base_table_name).where(base_table_name => {'hearing_type' => "LegacyHearing"}) },
#      class_name: "LegacyHearing", foreign_key: 'hearing_id', optional: true
#
#   def ama_hearing
#     super() if self.send(type_column) == "Hearing"
#   end
#   def legacy_hearing
#     super() if self.send(type_column) == "LegacyHearing"
#   end
#
# When calling `belongs_to_polymorphic_hearing :decision_review`, it defines similar associations to HLR and SC.
#
# These associations enable, for example, `has_many ama_decision_issues through: :ama_hearing`, which provides
# 1. easy access to decision_issues through a polymorphic association and
# 2. efficient queries when joining with other tables
# See RSpec for examples.

module BelongsToPolymorphicHearingConcern
  extend ActiveSupport::Concern

  class_methods do
    # Since we can't pass an argument to a concern, call this method instead
    def belongs_to_polymorphic_hearing(associated_class_symbol)
      # Define polymorphic association before calling AssocationWrapper
      belongs_to associated_class_symbol, polymorphic: true

      associated_class = associated_class_symbol.to_s.classify.constantize
      association = AssocationWrapper.new(self).belongs_to.polymorphic.associated_with_type(associated_class)
        .select_associations.first

      type_column = association.foreign_type
      scope :ama, -> { where(type_column => "Hearing") }
      scope :legacy, -> { where(type_column => "LegacyHearing") }

      add_method_for_polymorphic_association("Hearing", association)
      add_method_for_polymorphic_association("LegacyHearing", association)
    end

    private

    # This method creates a belongs_to association and method. For example, for type_name = "Hearing":
    # belongs_to :ama_hearing, -> { includes(base_table_name).where(base_table_name => {type_column => "Hearing"}) },
    #    class_name: "Hearing", foreign_key: id_column.to_s, optional: true
    #
    # def ama_hearing
    #   super() if self.send(type_column) == "Hearing"  # ensure nil is returned if type is not an AMA hearing
    # end
    #
    # For type_name = "LegacyHearing", the method_name will be legacy_hearing.
    def add_method_for_polymorphic_association(type_name, association)
      # Use `:ama_hearing` instead of `:hearing`
      # because `.hearing` is already defined by `belongs_to associated_class_symbol, polymorphic: true` above
      method_name = (type_name == "Hearing") ? :ama_hearing : type_name.underscore.to_sym

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
    end
  end
end
