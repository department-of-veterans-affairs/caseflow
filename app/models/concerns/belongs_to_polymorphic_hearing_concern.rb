# frozen_string_literal: true

require "helpers/association_wrapper.rb"

module BelongsToPolymorphicHearingConcern
  extend ActiveSupport::Concern

  class_methods do
    # Since we can't pass an argument to a concern, call this method instead
    def belongs_to_polymorphic_hearing(associated_class_symbol)
      # Define polymorphic association before calling AssocationWrapper
      belongs_to associated_class_symbol, polymorphic: true

      unless self.reflect_on_association(:self_ref)
        has_one :self_ref, class_name: self.name, foreign_key: :id
      end

      associated_class = associated_class_symbol.to_s.classify.constantize
      association = AssocationWrapper.new(self).belongs_to.polymorphic.associated_with_type(associated_class)
        .select_associations.first

      type_column = association.foreign_type
      scope :ama, -> { where(type_column => "Hearing") }
      scope :legacy, -> { where(type_column => "LegacyHearing") }

      # Use `:ama_hearing` instead of `:hearing`
      # because `.hearing` is already defined by `belongs_to associated_class_symbol, polymorphic: true` above
      has_one :ama_hearing, through: :self_ref, source: associated_class_symbol, source_type: "Hearing"
      has_one :legacy_hearing, through: :self_ref, source: associated_class_symbol, source_type: "LegacyHearing"
    end
  end
end
