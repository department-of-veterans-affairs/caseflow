# frozen_string_literal: true

module DecisionReviewPolymorphicHelper
  extend ActiveSupport::Concern

  class_methods do
    def define_polymorphic_decision_review_associations(association_name, from_association_name, types = nil)
      belongs_to association_name, polymorphic: true

      # Specific association mappings that are uniquely different from the calculated class name to underscored symbol
      association_name_mapping = { "Appeal" => :ama_appeal, "Hearing" => :ama_hearing }
      scope_mapping = { "Appeal" => :ama, "LegacyAppeal" => :legacy, "LegacyHearing" => :legacy, "Hearing" => :ama }

      # LegacyAppeals + all of the non abstract subtypes of DecisionReview not incuding child types for STI
      types ||= %w[Appeal LegacyAppeal HigherLevelReview SupplementalClaim]

      types.each do |type|
        type_symbol = type.underscore.to_sym
        belongs_to_association_name = association_name_mapping[type] || type_symbol
        scope_name = scope_mapping[type] || type_symbol

        belongs_to belongs_to_association_name,
                   -> { where(from_association_name => { "#{association_name}_type": type }) },
                   class_name: type, foreign_key: "#{association_name}_id", optional: true

        scope scope_name.to_sym, -> { where("#{association_name}_type": type) }
      end
    end
  end
end
