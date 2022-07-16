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
# 1. easy access to associated records through a polymorphic association and
# 2. efficient queries when joining with other tables
# See RSpec for examples.

module BelongsToPolymorphicHearingConcern
  extend ActiveSupport::Concern

  include BelongsToPolymorphicConcern

  class_methods do
    # Since we can't pass an argument to a concern, call this method instead
    def belongs_to_polymorphic_hearing(associated_class_symbol)
      # Define polymorphic association before calling AssocationWrapper
      belongs_to associated_class_symbol, polymorphic: true

      associated_class = associated_class_symbol.to_s.classify.constantize
      association = AssocationWrapper.new(self).belongs_to.polymorphic.associated_with_type(associated_class)
        .select_associations.first

      type_column = association.foreign_type
      scope :ama_h, -> { where(type_column => "Hearing") }
      scope :legacy_h, -> { where(type_column => "LegacyHearing") }

      # Use `:ama_hearing` instead of `:hearing`
      # because `.hearing` is already defined by `belongs_to associated_class_symbol, polymorphic: true` above
      add_method_for_polymorphic_association("Hearing", association, :ama_hearing)
      add_method_for_polymorphic_association("LegacyHearing", association)
    end
  end
end
