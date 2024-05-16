# frozen_string_literal: true

# Abstract service class for ETL synchronization.
# Subclasses should define a origin_class and a target_class
# and the target_class is expected to inherit from ETL::Record.
# The `call` method default behavior is to find all origin_class
# instances that have been updated "since" a Time,
# then sync and save the corresponding target_class instance.

class ETL::Syncer
  class << self
    def origin_class
      new(etl_build: false).origin_class
    end

    def target_class
      new(etl_build: false).target_class
    end
  end

  def initialize(since: nil, etl_build:, id_offset: 0)
    @orig_since = since # different name since we calculate since()
    @etl_build = etl_build
    @id_offset = id_offset
  end

  # :reek:UtilityFunction
  def slack_url
    ENV["SLACK_DISPATCH_ALERT_URL"]
  end

  def slack_service
    @slack_service ||= SlackService.new(url: slack_url)
  end

  # :reek:FeatureEnvy
  def dump_messages_to_slack(target_class)
    return unless target_class.messages

    slack_msg = target_class.messages.join("\n")
    slack_service.send_notification(slack_msg, target_class.name)
    target_class.clear_messages
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def call
    inserted = 0
    updated = 0
    rejected = 0

    # query can take up to 90 seconds
    CaseflowRecord.connection.execute "SET statement_timeout = 90000"

    # create build record only if we intend to use it.
    build_record if instances_needing_update.any?

    instances_needing_update.find_in_batches.with_index do |originals, batch|
      Rails.logger.debug("Starting batch #{batch} for #{target_class}")

      target_class.transaction do
        possible = originals.length
        saved = 0
        originals.reject { |original| filter?(original) }.each do |original|
          target = target_class.sync_with_original(original)
          next unless target

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
        status: :running,
        rows_inserted: inserted,
        rows_updated: updated,
        rows_rejected: rejected
      )
    end
    build_record.update!(
      status: :complete,
      finished_at: Time.zone.now
    )
    dump_messages_to_slack(target_class)
  rescue StandardError => error
    build_record.update!(
      rows_inserted: inserted,
      rows_updated: updated,
      rows_rejected: rejected,
      comments: error,
      status: :error,
      finished_at: Time.zone.now
    )
    # re-raise so sentry and parent build record know.
    raise error
  ensure
    CaseflowRecord.connection.execute "SET statement_timeout = 30000" # restore to 30 seconds
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

  def since
    return nil if @orig_since.nil?

    # if it's a boolean true value, calculate based on last build_record
    @since ||= if @orig_since == true
                 calculate_since
               else
                 @orig_since
               end
  end

  private

  attr_reader :orig_since, :etl_build

  def build_record
    @build_record ||= ETL::BuildTable.create(
      etl_build: etl_build,
      table_name: target_class.table_name,
      started_at: Time.zone.now,
      status: :running
    )
  end

  def calculate_since
    last_build = ETL::BuildTable.complete.where(table_name: target_class.table_name).order(:created_at).last
    last_build&.started_at
  end

  def incremental?
    !!since
  end

  protected

  def instances_needing_update
    return instances_after_id_offset.where("updated_at >= ?", since) if incremental?

    instances_after_id_offset
  end

  def instances_after_id_offset
    origin_class.unscoped.where("id >= ?", @id_offset)
  end
end
