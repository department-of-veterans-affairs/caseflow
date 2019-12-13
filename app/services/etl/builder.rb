# frozen_string_literal: true

# Normally called via cron to incrementally update ETL tables.
# We define a special `full` method to bypass the checkpoint marker.

class ETL::Builder
  ETL_KLASSES = %w[
    Appeal
    Task
    User
    Organization
    OrganizationsUser
  ].freeze

  CHECKPOINT_KEY = "etl-last-build-checkpoint"

  def initialize(since: checkpoint_time)
    @since = since
  end

  attr_reader :since

  def incremental
    built = 0
    checkmark
    syncer_klasses.each do |klass|
      built += klass.new(since: since).call
    end
    built
  end

  def full
    built = 0
    checkmark
    syncer_klasses.each { |klass| built += klass.new.call }
    built
  end

  def last_built
    Time.zone.parse(checkpoint)
  end

  private

  def syncer_klasses
    ETL_KLASSES.map { |klass| "ETL::#{klass}Syncer".constantize }
  end

  def checkpoint_time
    @checkpoint_time ||= last_built || Time.zone.now
  end

  def checkpoint
    # if more than 30 days pass w/o an incremental build,
    # we want to trigger a full build automatically.
    # the 30 day window is arbitrary, failsafe.
    Rails.cache.fetch(CHECKPOINT_KEY, expires_in: 30.days) do
      Time.zone.now.to_s
    end
  end

  def checkmark
    Rails.cache.write(CHECKPOINT_KEY, Time.zone.now.to_s)
  end
end
