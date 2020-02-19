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

  attr_reader :since

  def incremental
    checkmark
    syncer_klasses.each do |klass|
      klass.new(since: since).call(build_record)
    end
    post_build_steps
    update_build_record
  rescue StandardError => error
    update_build_record
    raise error
  end

  def full
    checkmark
    syncer_klasses.each { |klass| klass.new.call(build_record) }
    post_build_steps
    update_build_record
  rescue StandardError => error
    update_build_record
    raise error
  end

  def built
    build_record.reload.built
  end

  def last_built
    Time.zone.parse(checkpoint)
  end

  def build_record
    @build_record ||= ETL::Build.create(started_at: Time.zone.now, status: :running)
  end

  private

  def update_build_record
    status = build_record.reload.etl_build_tables.any?(&:error?) ? :error : :complete
    comments = nil
    if status == :error
      comments = build_record.etl_build_tables.error.map(&:comments).join("\n")
    end
    build_record.update!(finished_at: Time.zone.now, status: status, comments: comments)
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
    now = Time.zone.now.to_s
    Rails.logger.info("ETL::Builder.checkmark #{now}")
    Rails.cache.write(CHECKPOINT_KEY, now)
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
