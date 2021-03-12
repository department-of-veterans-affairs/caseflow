# frozen_string_literal: true

module SanitizedJsonDifference
  # fields expected to be different
  MAPPED_FIELDS = {
    Appeal => %w[id veteran_file_number],
    Veteran => %w[id file_number first_name middle_name last_name ssn],
    Claimant => %w[id decision_review_id],
    User => %w[id file_number first_name middle_name last_name ssn css_id email full_name] + [:display_name],
    Task => %w[id appeal_id parent_id assigned_by_id assigned_to_id],
    TaskTimer => %w[id task_id]
  }.freeze

  # :reek:BooleanParameter
  # :reek:FeatureEnvy
  def differences(orig_appeals, orig_users, ignore_expected_diffs: true)
    mapped_fields = ignore_expected_diffs ? MAPPED_FIELDS : {}
    orig_appeals = orig_appeals.uniq.sort_by(&:id)
    orig_tasks = orig_appeals.map(&:tasks).flatten.sort_by(&:id)

    {
      Appeal => orig_appeals,
      Veteran => orig_appeals.map(&:veteran).uniq.sort_by(&:id),
      Claimant => orig_appeals.map(&:claimants).flatten.uniq.sort_by(&:id),
      User => orig_users,
      Task => orig_appeals.map(&:tasks).flatten.sort_by(&:id),
      TaskTimer => TaskTimer.where(task_id: orig_tasks.map(&:id)).sort_by(&:id)
    }.each_with_object({}) do |(clazz, orig_records), result| # https://blog.arkency.com/inject-vs-each-with-object/
      key = clazz.table_name
      result[key] = diff_record_lists(orig_records, imported_records[key], mapped_fields[clazz])
    end
  end

  def diff_record_lists(orig_records, imported_records, ignored_fields)
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
      if ignore_id_offset && integer?(hash_b[key])
        next diffs if (hash_b[key].to_i - hash_a[key].to_i).abs == ID_OFFSET
      end

      # Handle comparing a timestamp with the string equivalent recognized by JSON.parse
      if convert_timestamps && (hash_a[key].try(:to_time) || hash_b[key].try(:to_time))
        time_a = hash_a[key].try(:to_time)&.to_s || hash_a[key]
        time_b = hash_b[key].try(:to_time)&.to_s || hash_b[key]
        next diffs if time_a == time_b

        next diffs << [key, time_a, time_b]
      end

      next diffs << [key, hash_a[key], hash_b[key]]
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/AbcSize, Metrics/PerceivedComplexity
end
