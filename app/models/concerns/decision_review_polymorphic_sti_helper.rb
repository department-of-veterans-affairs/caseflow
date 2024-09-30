# frozen_string_literal: true

module DecisionReviewPolymorphicSTIHelper
  extend ActiveSupport::Concern

  class_methods do
    def define_polymorphic_decision_review_sti_associations(association_name, from_association_name, types = nil)
      # Mappings between STI types and their associated parent type and parent database table
      sti_table_mapping = { "Remand" => :supplemental_claims }
      sti_type_mapping = { "Remand" => "SupplementalClaim" }

      types ||= %w[Remand]

      types.each do |type|
        type_symbol = type.underscore.to_sym
        belongs_to_association_name = type_symbol
        sti_type = sti_type_mapping[type] || type
        sti_table_name = sti_table_mapping[type] || association_name

        belongs_to belongs_to_association_name,
                   lambda {
                     where(from_association_name => { "#{association_name}_type": sti_type })
                       .where(Arel::Table.new(sti_table_name)[:type].eq(type))
                   },
                   class_name: type, foreign_key: "#{association_name}_id", optional: true
      end
    end
  end
end
