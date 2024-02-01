# frozen_string_literal: true

require "helpers/association_wrapper.rb"

##
# See BelongsToPolymorphicHearingConcern for use of this module

module BelongsToPolymorphicConcern
  extend ActiveSupport::Concern

  class_methods do
    private

    # This method creates a belongs_to association and method. For example, for type_name = "Appeal":
    # belongs_to :ama_appeal, -> { includes(association_name).where(base_table_name => {type_column => "Appeal"}) },
    #    class_name: "Appeal", foreign_key: id_column.to_s, optional: true
    #
    # def ama_appeal
    #   super() if self.send(type_column) == "Appeal"  # ensure nil is returned if type is not an AMA appeal
    # end
    #
    # For type_name = "SupplementalClaim", the method_name will be supplemental_claim.
    def add_method_for_polymorphic_association(type_name, association, method_name = type_name.underscore.to_sym)
      type_column = association.foreign_type
      id_column = association.foreign_key
      # Define self_table_name here so it can be used in the belongs_to lambda, where `self.table_name` is different
      self_table_name = table_name

      # The use of `includes(self_table_name)` relies on an association being defined in the other class (eg, Appeal).
      # The association may be singular (`has_one`) or plural (`has_many`),
      # which is reflected in `inverse_association_name`.
      inverse_association_name = inverse_association_name(type_name)
      # DecisionIssue does not have an inverse association with LegacyAppeal
      return unless inverse_association_name

      belongs_to method_name,
                 -> { includes(inverse_association_name).where(self_table_name => { type_column => type_name }) },
                 class_name: type_name, foreign_key: id_column.to_s, optional: true

      define_method method_name do
        # `super()` will call the method created by the `belongs_to` above
        super() if send(type_column) == type_name
      end
    end

    def inverse_association_name(type_name)
      klass = type_name.constantize
      # Ignore polymorphic associations, which don't have a `klass` and will raise and error
      klass.reflections.values.reject(&:polymorphic?).detect { |assoc| assoc.klass == self }&.name
    end
  end
end
