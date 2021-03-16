# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"

module SanitizedJsonDifference
  ADDITIONAL_MAPPED_FIELDS = { User => [:display_name] }.freeze

  def configuration_mapped_fields
    # fields expected to be different;
    # corresponds with fields in SanitizedJsonExporter#sanitize and SanitizedJsonImporter
    @configuration_mapped_fields ||= [
      @configuration.sanitize_fields_hash,
      @configuration.offset_id_fields,
      *@configuration.reassociate_fields.values,
      ADDITIONAL_MAPPED_FIELDS
    ].map(&:to_a).sum.group_by(&:first).transform_values do |value|
      field_name_arrays = value.map(&:second) + ["id"]
      field_name_arrays.flatten.uniq
    end.freeze
  end

  # :reek:FeatureEnvy
  def differences(orig_initial_records, ignore_expected_diffs: true, ignore_reused_records: true)
    mapped_fields = ignore_expected_diffs ? configuration_mapped_fields : {}
    # https://blog.arkency.com/inject-vs-each-with-object/
    @configuration.records_to_export(orig_initial_records).each_with_object({}) do |(clazz, orig_records), result|
      key = clazz.table_name
      reused_records_list = ignore_reused_records ? reused_records[key] : []
      result[key] = SanitizedJsonDifference.diff_record_lists(orig_records.compact.uniq.sort_by(&:id),
                                                              imported_records[key],
                                                              reused_records_list,
                                                              mapped_fields[clazz])
    end
  end

  def self.diff_record_lists(orig_records_list, imported_records_list, reused_records_list, ignored_fields)
    orig_records_list.zip(imported_records_list).map do |original, imported|
      next if imported.nil? && reused_records_list.include?(original)

      next ["record missing", original, imported] if original.nil? || imported.nil?

      SanitizedJsonDifference.diff_records(original, imported, ignored_fields: ignored_fields)
    end.compact
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  # :reek:BooleanParameter
  def self.diff_records(record_a, record_b, ignored_fields: nil,
                        ignore_id_offset: false, convert_timestamps: true)
    hash_a = SanitizedJsonExporter.record_to_hash(record_a).except(*ignored_fields)
    hash_b = SanitizedJsonExporter.record_to_hash(record_b).except(*ignored_fields)
    # https://stackoverflow.com/questions/4928789/how-do-i-compare-two-hashes
    array_diff = (hash_b.to_a - hash_a.to_a) + (hash_a.to_a - hash_b.to_a)

    # Ignore some differences if they are expected or equivalent
    fieldnames_of_differences = array_diff.map(&:first).uniq
    fieldnames_of_differences.map do |fieldname|
      compare_values(fieldname, hash_a[fieldname], hash_b[fieldname],
                     ignore_id_offset: ignore_id_offset,
                     convert_timestamps: convert_timestamps)
    end.compact
  end

  def self.compare_values(key, value_a, value_b, ignore_id_offset: false, convert_timestamps: true)
    return nil if value_a == value_b

    if ignore_id_offset && (value_a.is_a?(Integer) || value_b.is_a?(Integer))
      return nil if (value_b.to_i - value_a.to_i).abs == ID_OFFSET
    end

    if convert_timestamps
      return try_to_compare_timestamps(key, value_a, value_b)
    end

    [key, value_a, value_b]
  end

  # Compare a timestamp with the string equivalent recognized by JSON.parse
  def self.try_to_compare_timestamps(key, value_a, value_b)
    if value_a.try(:to_time) || value_b.try(:to_time)
      time_a = value_a.try(:to_time)&.to_s || value_a
      time_b = value_b.try(:to_time)&.to_s || value_b
      return nil if time_a == time_b
    end
    [key, time_a, time_b]
  rescue ArgumentError
    # occurs when `to_time` is called on a string that is a UUID
    ["#{key} (ArgumentError)", value_a, value_b]
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
