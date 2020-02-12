# frozen_string_literal: true

# Abstract service class for ETL synchronization.
# Subclasses should define a origin_class and a target_class
# and the target_class is expected to inherit from ETL::Record.
# The `call` method default behavior is to find all origin_class
# instances that have been updated "since" a Time,
# then sync and save the corresponding target_class instance.

class ETL::Syncer
  def initialize(since: nil)
    @since = since
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def call(etl_build)
    inserted = 0
    updated = 0
    rejected = 0
    create_build_record(etl_build)
    instances_needing_update.find_in_batches.with_index do |originals, batch|
      Rails.logger.debug("Starting batch #{batch} for #{target_class}")
      target_class.transaction do
        possible = originals.length
        saved = 0
        originals.reject { |original| filter?(original) }.each do |original|
          target = target_class.sync_with_original(original)
          if target.persisted?
            updated += 1
          else
            inserted += 1
          end
          target.save!
          saved += 1
        end
        rejected += (possible - saved)
      end
      build_record.update!(
        status: :complete,
        finished_at: Time.zone.now,
        rows_inserted: inserted,
        rows_updated: updated,
        rows_rejected: rejected
      )
    rescue StandardError => error
      build_record.update!(
        rows_inserted: inserted,
        rows_updated: updated,
        rows_rejected: rejected,
        comments: error,
        status: :error,
        finished_at: Time.zone.now
      )
    end
    build_record
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize

  def origin_class
    fail "Must override abstract method origin_class"
  end

  def target_class
    fail "Must override abstract method target_class"
  end

  def filter?(_original)
    false
  end

  private

  attr_reader :since, :build_record

  def create_build_record(etl_build)
    @build_record = ETL::BuildTable.create(
      etl_build: etl_build,
      table_name: target_class.table_name,
      started_at: Time.zone.now,
      status: :running
    )
  end

  def incremental?
    !!since
  end

  def instances_needing_update
    return origin_class.where("updated_at >= ?", since) if incremental?

    origin_class
  end
end
