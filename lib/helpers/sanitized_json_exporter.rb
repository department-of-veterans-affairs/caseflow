# frozen_string_literal: true

class SanitizedJsonExporter
  attr_accessor :value_mapping
  attr_accessor :records_hash

  # :reek:BooleanParameter
  def initialize(*initial_records, sanitize: true)
    @sanitize = sanitize
    @value_mapping = {}
    @records_hash = { "metadata" => { "exported_at": Time.zone.now } }

    SanitizedJsonConfiguration.records_to_export(initial_records).each do |clazz, records|
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

  def sanitize_records(records)
    # keep records in order so that comparisons can be done after import
    records.uniq.compact.sort_by(&:id).map { |record| sanitize(record) }
  end

  KNOWN_CLASSES = SanitizedJsonConfiguration::SANITIZE_FIELDS.keys.freeze
  SANITIZE_TABLE_FIELDS = SanitizedJsonConfiguration::SANITIZE_FIELDS.transform_keys(&:table_name).freeze

  def sanitize(record)
    obj_hash = self.class.record_to_hash(record)
    return obj_hash unless @sanitize

    SanitizedJsonConfiguration.before_sanitize_hook(record, obj_hash)

    if KNOWN_CLASSES.any? { |klass| record.is_a?(klass) }
      # Use table_name to handle subclasses/STI: e.g., a HearingTask record maps to table "tasks"
      SANITIZE_TABLE_FIELDS[record.class.table_name].each do |field_name|
        if field_name.is_a?(Regexp)
          obj_hash.keys.select { |key| key.match?(field_name) }.each do |key|
            find_or_create_mapped_value_for(obj_hash, key, obj_class: record.class)
          end
        elsif field_name.is_a?(String)
          find_or_create_mapped_value_for(obj_hash, field_name, obj_class: record.class)
        elsif obj_hash.key?(field_name)
          fail "#{record.class} record doesn't have field_name '#{field_name}': #{obj_hash}"
        else
          fail "Expecting string or regex for the #{record.class}'s field name: #{field_name}"
        end
      end
      return obj_hash
    end

    fail "Unsupported object type: #{record.class.name}"
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
    mapped_value || fail("Don't know how to map value '#{orig_value}' for field '#{field_name}'")
  end

  # fields whose mapped value should not be saved to the @value_mapping hash,
  # e.g., due to distinct orig_values mapping to the same new_value
  MAPPED_VALUES_IGNORED_FIELDS = %w[first_name middle_name last_name].freeze
  MAPPED_VALUES_IGNORED_TRANSFORMS = [:obfuscate_sentence, :similar_date].freeze

  # :reek:LongParameterList
  def map_value(orig_value, field_name, obj_class: nil, transform_method: nil)
    # find the first of the transform_methods that returns a non-nil value
    transform_method ||= SanitizedJsonConfiguration.transform_methods.find do |method|
      SanitizedJsonConfiguration.send(method, field_name, orig_value)
    end
    unless transform_method
      fail "For #{obj_class.name} field '#{field_name}' with value '#{orig_value}' of class #{orig_value.class}, " \
           "could not find a transform_method"
    end

    new_value = SanitizedJsonConfiguration.send(transform_method, field_name, orig_value)

    # Don't save the value_mapping for certain transforms
    if !(MAPPED_VALUES_IGNORED_TRANSFORMS.include?(transform_method) ||
      MAPPED_VALUES_IGNORED_FIELDS.include?(field_name))
      @value_mapping[orig_value] = new_value
    end
    [new_value, transform_method]
  end
end
