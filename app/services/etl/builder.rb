# frozen_string_literal: true

# Normally called via cron to incrementally update ETL tables.
# We define a special `full` method to bypass the checkpoint marker.

class ETL::Builder
  include ETLClasses

  def initialize(since: checkpoint_time)
    @since = since
  end

  attr_reader :since

  def incremental
    syncer_klasses.each do |klass|
      klass.new(since: true, etl_build: build_record).call
    end
    post_build_steps
    update_build_record
  rescue StandardError => error
    update_build_record
    raise error
  end

  def full
    syncer_klasses.each { |klass| klass.new(etl_build: build_record).call }
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
    # DO NOT memoize
    ETL::Build.complete.order(:created_at).last&.started_at
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

  def checkpoint_time
    @checkpoint_time ||= last_built || Time.zone.now
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
