# frozen_string_literal: true

# This is a helper class for SanitizedJsonConfiguration to automate identifying certain
# fieldnames (a.k.a. foreign keys) that associate with other records.
# https://stackoverflow.com/questions/13355549/rails-activerecord-detect-if-a-column-is-an-association-or-not
##

class AssocationWrapper
  def initialize(klass)
    @associations = klass.reflect_on_all_associations
    @selects = []
  end

  module BuilderMethods
    def belongs_to
      @selects << ->(assoc) { assoc.macro == :belongs_to }
      self
    end

    def polymorphic
      @selects << ->(assoc) { assoc.polymorphic? }
      self
    end

    def without_type_field
      # Ignoring scenario where assoc.foreign_key.is_a?(Symbol)
      @selects << ->(assoc) { assoc.foreign_type.nil? && assoc.foreign_key.is_a?(String) }
      self
    end

    def having_type_field
      @selects << ->(assoc) { assoc.foreign_type }
      self
    end

    def associated_with_type(assoc_class)
      @selects << ->(assoc) { assoc.class_name == assoc_class.name }
      self
    end

    def except_fieldnames(ignore_fieldnames)
      @selects << ->(assoc) { !ignore_fieldnames.include?(assoc.foreign_key) } if ignore_fieldnames&.any?
      self
    end
  end

  include BuilderMethods

  def fieldnames
    select_associations.map(&:foreign_key)
  end

  # Return associations that satisfy all specified select clauses
  def select_associations
    @associations.select { |assoc| @selects.map { |select_clause| select_clause.call(assoc) }.all? }
  end

  module ConvenienceMethods
    # and usage examples

    def fieldnames_of_typed_associations(excluding: [])
      belongs_to.having_type_field.except_fieldnames(excluding).fieldnames
    end

    def fieldnames_of_typed_associations_with(assoc_class)
      belongs_to.having_type_field.associated_with_type(assoc_class).fieldnames
    end

    def fieldnames_of_untyped_associations_with(assoc_class)
      belongs_to.without_type_field.associated_with_type(assoc_class).fieldnames
    end

    def grouped_fieldnames_of_typed_associations_with(known_classes)
      # Foreign keys that are not strings (e.g., Claimant.participant_id) involves
      # more complex association that isn't currently handled (and may not need to be)
      belongs_to.select_associations.group_by(&:class_name)
        .slice(*known_classes)
        .transform_values { |assocs| assocs.map(&:foreign_key).select { |fk| fk.is_a?(String) } }
        .compact
    end
  end

  include ConvenienceMethods

  # To-do: bootstrap Jailer schema-documentation generator with polymorphic associations
  # clazz=VACOLS::Case
  # ag=AssocationWrapper.new(klass).belongs_to.select_associations.group_by(&:class_name);
  # ag.transform_values { |assocs| assocs.map{|assoc| [assoc.foreign_key, assoc.foreign_type] } }
  def to_jailer_association_csv
    assocs = belongs_to.associations.transform_values { |assocs|
      assocs.map{|assoc| [assoc.foreign_key, assoc.foreign_type] }
    }
    binding.pry
  end
end
