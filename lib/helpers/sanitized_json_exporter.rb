# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"

# Given a set of records, this class sanitizes specified fields and exports them as JSON.
# The fields to be sanitized is specified by the SanitizedJsonConfiguration, which also provides
# a list of methods (e.g., those in SanitizationTransforms) that will be applied to the original values.
# The resulting JSON can then imported by SanitizedJsonImporter.
##

class SanitizedJsonExporter
  attr_accessor :value_mapping
  attr_accessor :records_hash

  # :reek:BooleanParameter
  def initialize(*initial_records,
                 configuration: SanitizedJsonConfiguration.new,
                 sanitize: true)
    @configuration = configuration
    @sanitize = sanitize
    @value_mapping = {}
    @records_hash = { "metadata" => { "exported_at": Time.zone.now } }

    return if initial_records.compact.blank?

    @configuration.records_to_export(initial_records).each do |clazz, records|
      # puts "Exporting #{clazz.table_name}"
      @records_hash[clazz.table_name] = sanitize_records(records)
    end
  end

  def save(filename, purpose: nil)
    @records_hash["metadata"]["purpose"] = purpose if purpose
    File.open(filename.to_s, "w") { |file| file.puts file_contents }
  end

  def file_contents
    JSON.pretty_generate(@records_hash)
  end

  def self.record_to_hash(record)
    record.attributes
  end

  private

  def sanitize_records(records)
    # keep records in order so that comparisons can be done after import
    records.uniq.compact.sort_by(&:id).map { |record| sanitize(record) }
  end

  def supported_classes
    @supported_classes ||= @configuration.sanitize_fields_hash.keys.freeze
  end

  def sanitize_table_fields
    @sanitize_table_fields ||= @configuration.sanitize_fields_hash.transform_keys(&:table_name).freeze
  end

  def sanitize(record)
    obj_hash = self.class.record_to_hash(record)
    return obj_hash unless @sanitize

    @configuration.before_sanitize_hook(record, obj_hash)

    if supported_classes.any? { |klass| record.is_a?(klass) }
      # Use table_name to handle subclasses/STI: e.g., a HearingTask record maps to table "tasks"
      sanitize_table_fields[record.class.table_name].each do |fieldname_expression|
        sanitize_object_hash(obj_hash, fieldname_expression, record)
      end
      return obj_hash
    end

    fail "Unsupported record type: #{record.class.name}"
  end

  def sanitize_object_hash(obj_hash, fieldname_expression, record)
    if fieldname_expression.is_a?(Regexp)
      obj_hash.keys.select { |key| key.match?(fieldname_expression) }.each do |key|
        find_or_create_mapped_value_for(obj_hash, key, obj_class: record.class)
      end
    elsif fieldname_expression.is_a?(String)
      unless obj_hash.key?(fieldname_expression)
        fail "#{record.class} record doesn't have attribute '#{fieldname_expression}': #{obj_hash}"
      end

      find_or_create_mapped_value_for(obj_hash, fieldname_expression, obj_class: record.class)
    else
      fail "Expecting string or regex for the #{record.class}'s field name: #{fieldname_expression}"
    end
  end

  # :reek:FeatureEnvy
  def find_or_create_mapped_value_for(obj_hash, field_name, **kwargs)
    return unless obj_hash[field_name]

    # Loop to ensure hash @value_mapping has a different value for each distinct key
    10.times do
      obj_hash[field_name] = find_or_create_mapped_value(obj_hash[field_name], field_name, **kwargs)
      break if @value_mapping.values.uniq.size == @value_mapping.size

      puts "Value '#{obj_hash[field_name]}' for field #{field_name} is already used; trying again"
    end
    obj_hash[field_name]
  end

  def find_or_create_mapped_value(orig_value, field_name = nil, **kwargs)
    mapped_value = @value_mapping.fetch(orig_value) do
      if orig_value.is_a?(Array)
        value_and_transforms = orig_value.map { |val| map_value(val, field_name, **kwargs) }
        value_and_transforms.map(&:first)
      else
        map_value(orig_value, field_name, **kwargs).first
      end
    end

    return mapped_value if mapped_value

    default_mapped_value(orig_value, field_name, **kwargs)
  end

  def default_mapped_value(orig_value, field_name, **kwargs)
    puts("WARNING: Don't know how to map value '#{orig_value}' #{orig_value.class.name} "\
      "for field '#{field_name}'; #{kwargs}")
    case orig_value
    when Integer
      0
    when String
      ""
    when Array
      []
    end
  end

  # :reek:LongParameterList
  def map_value(orig_value, field_name, obj_class: nil, transform_method: nil)
    # find the first of the transform_methods that returns a non-nil value
    transform_method ||= @configuration.transform_methods.find do |method|
      @configuration.send(method, field_name, orig_value, obj_class: obj_class)
    end

    unless transform_method
      puts "WARNING: Could not find a transform_method for #{obj_class&.name} field '#{field_name}'"\
           " with value '#{orig_value}' of class #{orig_value.class}."
      return [nil, nil]
    end

    new_value = @configuration.send(transform_method, field_name, orig_value, obj_class: obj_class)

    # Don't save the value_mapping for certain transforms
    if @configuration.save_mapped_value?(transform_method, field_name, orig_value, new_value)
      @value_mapping[orig_value] = new_value
    end

    [new_value, transform_method]
  end
end
