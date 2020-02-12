# frozen_string_literal: true

# Normally called via cron to incrementally update ETL tables.
# We define a special `full` method to bypass the checkpoint marker.

class ETL::Builder
  ETL_KLASSES = %w[
    Appeal
    AttorneyCaseReview
    DecisionIssue
    Organization
    OrganizationsUser
    Person
    Task
    User
  ].freeze

  CHECKPOINT_KEY = "etl-last-build-checkpoint"

  def initialize(since: checkpoint_time)
    @since = since
  end

  attr_reader :since, :build_record

  def incremental
    checkmark
    syncer_klasses.each do |klass|
      klass.new(since: since).call(build_record)
    end
    post_build_steps
    update_build_record
  end

  def full
    checkmark
    syncer_klasses.each { |klass| klass.new.call(build_record) }
    post_build_steps
    update_build_record
  end

  def built
    build_record.reload.built
  end

  def last_built
    Time.zone.parse(checkpoint)
  end

  private

  def build_record
    @build_record ||= ETL::Build.create(started_at: Time.zone.now, status: :running)
  end

  def update_build_record
    build_record.update!(finished_at: Time.zone.now, status: :complete)
    build_record
  end

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

  def post_build_steps
    mark_aod_for_today
  end

  def mark_aod_for_today
    ETL::Appeal.active
      .where("claimant_dob <= ?", 75.years.ago)
      .where(aod_due_to_dob: false)
      .update_all(aod_due_to_dob: true)
  end
end
