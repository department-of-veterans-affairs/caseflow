# frozen_string_literal: true

# This is a helper class for SanitizedJsonConfiguration to automate identifying certain
# fieldnames (a.k.a. foreign keys) that associate with other records.
# https://stackoverflow.com/questions/13355549/rails-activerecord-detect-if-a-column-is-an-association-or-not
##

class AssocationWrapper
  attr_reader :associations

  def initialize(klass)
    @associations = klass.reflect_on_all_associations
  end

  def belongs_to
    @associations = @associations.select { |assoc| assoc.macro == :belongs_to }
    self
  end

  def without_type_field
    # Ignoring case where assoc.foreign_key.is_a?(Symbol)
    @associations = @associations.select { |assoc| assoc.foreign_type.nil? && assoc.foreign_key.is_a?(String) }
    self
  end

  def having_type_field
    @associations = @associations.select(&:foreign_type)
    self
  end

  def associated_with_type(assoc_class)
    @associations = @associations.select { |assoc| assoc.class_name == assoc_class.name }
    self
  end

  def except_fieldnames(ignore_fieldnames)
    if ignore_fieldnames.any?
      @associations = @associations.reject { |assoc| ignore_fieldnames&.include?(assoc.foreign_key) }
    end
    self
  end

  def fieldnames
    @associations.map(&:foreign_key)
  end

  def typed_associations(excluding: [])
    belongs_to.having_type_field.except_fieldnames(excluding)
  end

  def typed_associations_with(assoc_class)
    belongs_to.having_type_field.associated_with_type(assoc_class)
  end

  def untyped_associations_with(assoc_class)
    belongs_to.without_type_field.associated_with_type(assoc_class)
  end

  def grouped_fieldnames_of_typed_associations_with(known_classes)
    # Foreign keys that are not strings (e.g., Claimant.participant_id) involves
    # more complex association that isn't currently handled (and may not need to be)
    belongs_to.associations.group_by(&:class_name)
      .slice(*known_classes)
      .transform_values { |assocs| assocs.map(&:foreign_key).select { |fk| fk.is_a?(String) } }
      .compact
  end
end
