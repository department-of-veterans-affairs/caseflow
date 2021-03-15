# frozen_string_literal: true

require "helpers/sanitized_json_configuration.rb"

module SanitizedJsonDifference
  ADDITIONAL_MAPPED_FIELDS = {
    User => [:display_name]
  }.freeze

  # fields expected to be different; corresponds with fields in SanitizedJsonExporter#sanitize and SanitizedJsonImporter
  MAPPED_FIELDS = [
    SanitizedJsonConfiguration::SANITIZE_FIELDS,
    SanitizedJsonConfiguration::OFFSET_ID_FIELDS,
    *SanitizedJsonConfiguration::REASSOCIATE_FIELDS.values,
    ADDITIONAL_MAPPED_FIELDS
  ].map(&:to_a).sum.group_by(&:first).transform_values do |value|
    field_name_arrays = value.map(&:second) + ["id"]
    field_name_arrays.flatten.uniq
  end.freeze

  def differences(sje, **kwargs)
    orig_appeals = Appeal.where(id: sje.records_hash[Appeal.table_name].pluck("id")).order(:id)
    orig_users = User.where(id: sje.records_hash[User.table_name].pluck("id")).order(:id)
    compare_with(sje, orig_appeals, orig_users, **kwargs)
  end

  # :reek:BooleanParameter
  # :reek:FeatureEnvy
  def compare_with(sje, orig_appeals, orig_users, ignore_expected_diffs: true)
    mapped_fields = ignore_expected_diffs ? MAPPED_FIELDS : {}
    orig_appeals = orig_appeals.uniq.sort_by(&:id)
    orig_tasks = orig_appeals.map(&:tasks).flatten.sort_by(&:id)

    {
      Appeal => orig_appeals,
      Veteran => orig_appeals.map(&:veteran).uniq.sort_by(&:id),
      Claimant => orig_appeals.map(&:claimants).flatten.uniq.sort_by(&:id),
      User => orig_users,
      Task => orig_appeals.map(&:tasks).flatten.sort_by(&:id),
      TaskTimer => TaskTimer.where(task_id: orig_tasks.map(&:id)).sort_by(&:id),
      CavcRemand => CavcRemand.where(id: sje.records_hash[CavcRemand.table_name].pluck("id")).order(:id),
      Hearing => nil,
      HearingDay => nil,
      VirtualHearing => nil,
      HearingTaskAssociation => nil
      # TODO: add cavc_r, ri, di, rdi
      # TODO: print warning about missing by using JSON hashes
    }.each_with_object({}) do |(clazz, orig_records), result| # https://blog.arkency.com/inject-vs-each-with-object/
      key = clazz.table_name
      orig_records ||= clazz.where(id: sje.records_hash[clazz.table_name].pluck("id")).order(:id)
      result[key] = SanitizedJsonDifference.diff_record_lists(orig_records, imported_records[key], mapped_fields[clazz])
    end
  end

  def self.diff_record_lists(orig_records, imported_records, ignored_fields)
    orig_records.zip(imported_records).map do |original, imported|
      SanitizedJsonDifference.diff_records(original, imported, ignored_fields: ignored_fields)
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity
  # :reek:BooleanParameter
  # :reek:LongParameterList
  def self.diff_records(record_a, record_b,
                        ignore_id_offset: false,
                        convert_timestamps: true,
                        ignored_fields: nil)
    hash_a = SanitizedJsonExporter.record_to_hash(record_a).except(*ignored_fields)
    hash_b = SanitizedJsonExporter.record_to_hash(record_b).except(*ignored_fields)
    # https://stackoverflow.com/questions/4928789/how-do-i-compare-two-hashes
    array_diff = (hash_b.to_a - hash_a.to_a) + (hash_a.to_a - hash_b.to_a)

    # Ignore some differences if they are expected or equivalent
    array_diff.map(&:first).uniq.inject([]) do |diffs, key|
      value_a = hash_a[key]
      value_b = hash_b[key]
      if ignore_id_offset && (value_b.is_a?(Integer) || integer?(value_b))
        next diffs if (value_b.to_i - value_a.to_i).abs == ID_OFFSET
      end

      # Handle comparing a timestamp with the string equivalent recognized by JSON.parse
      begin
        if convert_timestamps && (value_a.try(:to_time) || value_b.try(:to_time))
          time_a = value_a.try(:to_time)&.to_s || value_a
          time_b = value_b.try(:to_time)&.to_s || value_b
          next diffs if time_a == time_b

          next diffs << [key, time_a, time_b]
        end
      rescue ArgumentError
        # occurs when `to_time` is called on a string that is a UUID
      end

      next diffs << [key, value_a, value_b]
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity

  def self.integer?(thing)
    begin
      Integer(thing)
    rescue StandardError
      false
    end
  end
end
