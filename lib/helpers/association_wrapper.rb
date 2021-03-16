# frozen_string_literal: true

# https://stackoverflow.com/questions/13355549/rails-activerecord-detect-if-a-column-is-an-association-or-not
class AssocationWrapper
  attr_reader :associations

  def initialize(clazz)
    @associations = clazz.reflect_on_all_associations
  end

  def belongs_to
    @associations = @associations.select { |assoc| assoc.macro == :belongs_to }
    self
  end

  def without_type_field
    # Not sure how to handle case where assoc.foreign_key.is_a?(Symbol)
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

  def ignore_fieldnames(ignore_fieldnames)
    if ignore_fieldnames.any?
      @associations = @associations.reject { |assoc| ignore_fieldnames&.include?(assoc.foreign_key) }
    end
    self
  end

  def fieldnames
    @associations.map(&:foreign_key)
  end

  class << self
    def fieldnames_of_typed_associations_with(assoc_class, clazz)
      AssocationWrapper.new(clazz).belongs_to.associated_with_type(assoc_class).fieldnames.presence
    end

    def fieldnames_of_untyped_associations_with(assoc_class, clazz)
      AssocationWrapper.new(clazz).belongs_to.without_type_field.associated_with_type(assoc_class).fieldnames.presence
    end

    def fieldnames_of_typed_associations_for(clazz, ignore_fieldnames)
      AssocationWrapper.new(clazz).belongs_to.having_type_field.ignore_fieldnames(ignore_fieldnames).fieldnames.presence
    end

    def grouped_fieldnames_of_typed_associations_with(clazz, known_classes)
      AssocationWrapper.new(clazz).belongs_to.associations
        .group_by(&:class_name)
        .slice(*known_classes)
        .transform_values { |assocs| assocs.map(&:foreign_key) }
        .compact
    end
  end
end
