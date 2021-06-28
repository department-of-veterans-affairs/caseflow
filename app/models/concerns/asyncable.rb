# frozen_string_literal: true

# History of this class is in docs/asyncable-models.md
#
# Mixin module to apply to an ActiveRecord class, to make it easier to process via
# an ActiveJob and retry it beyond the retry logic of ActiveJob.
# This becomes necessary when a Job has multiple external service calls, each of
# which may fail and cause retries beyond the "normal" retry window.
# See ClaimReview and RequestIssuesUpdate e.g.

# rubocop:disable Metrics/ModuleLength
module Asyncable
  extend ActiveSupport::Concern

  include RunAsyncable

  included do
    has_many :job_notes, as: :job
  end

  # class methods to scope queries based on class-defined columns
  # we expect 5 column types:
  #  * last_submitted_at : when the job is eligible to run (can be reset to restart the job)
  #  * submitted_at : when the job first became eligible to run
  #  * attempted_at : flag the job as having run
  #  * processed_at : flag the job as concluded
  #  * error        : any error message captured from a failed attempt.
  # These column names can be overridden in consuming classes as needed.
  class_methods do
    REQUIRES_PROCESSING_WINDOW_DAYS = 4
    EXPIRATION_WINDOW_BUFFER_HOURS = 1
    DEFAULT_REQUIRES_PROCESSING_RETRY_WINDOW_HOURS = 3
    PROCESS_DELAY_VBMS_OFFSET_HOURS = 7

    def processing_retry_interval_hours
      self::DEFAULT_REQUIRES_PROCESSING_RETRY_WINDOW_HOURS
    end

    def requires_processing_until
      self::REQUIRES_PROCESSING_WINDOW_DAYS.days.ago
    end

    def last_submitted_at_column
      :last_submitted_at
    end

    def submitted_at_column
      :submitted_at
    end

    def attempted_at_column
      :attempted_at
    end

    def processed_at_column
      :processed_at
    end

    def error_column
      :error
    end

    def canceled_at_column
      :canceled_at
    end

    def unexpired
      where(arel_table[last_submitted_at_column].gt(requires_processing_until))
    end

    def canceled
      where.not(canceled_at_column => nil)
    end

    def processable
      where(arel_table[last_submitted_at_column].lteq(Time.zone.now))
        .where(processed_at_column => nil)
        .where(canceled_at_column => nil)
    end

    def never_attempted
      where(attempted_at_column => nil).where(
        arel_table[last_submitted_at_column].lteq(processing_retry_interval_hours.hours.ago)
      )
    end

    def previously_attempted_ready_for_retry
      where(arel_table[attempted_at_column].lt(processing_retry_interval_hours.hours.ago))
    end

    def attemptable
      previously_attempted_ready_for_retry.or(never_attempted).where(canceled_at_column => nil)
    end

    def order_by_oldest_submitted
      order(last_submitted_at_column => :asc)
    end

    def requires_processing
      processable.attemptable.unexpired.order_by_oldest_submitted
    end

    def expired_without_processing
      where(processed_at_column => nil)
        .where(arel_table[last_submitted_at_column].lteq(requires_processing_until))
    end

    def attempted_without_being_submitted
      where(arel_table[attempted_at_column].lteq(Time.zone.now)).where(last_submitted_at_column => nil)
    end

    def with_error
      where.not(error_column => nil)
    end

    def potentially_stuck
      processable
        .or(with_error)
        .or(attempted_without_being_submitted)
        .where(canceled_at_column => nil)
        .order_by_oldest_submitted
    end

    def processed
      where.not(processed_at_column => nil)
    end

    def processed_or_canceled
      processed.or(canceled)
    end
  end

  def submit_for_processing!(delay: 0)
    # One minute offset to prevent "this date is in the future" errors with external services
    when_to_start = delay.try(:to_datetime) ? delay.to_datetime + 1.minute : Time.zone.now + delay

    # Subtract the `processing_retry_interval_hours` from the delay time,
    # to offset its presence in the `previously_attmpted_ready_for_retry` logic.
    if delay != 0
      when_to_start -= self.class.processing_retry_interval_hours.hours
    end

    update!(
      self.class.last_submitted_at_column => when_to_start,
      self.class.submitted_at_column => delay.try(:to_datetime) ? delay.to_datetime : Time.zone.now,
      self.class.processed_at_column => nil
    )
  end

  def processed!
    update!(self.class.processed_at_column => Time.zone.now) unless processed?
  end

  def attempted!
    update!(self.class.attempted_at_column => Time.zone.now)
  end

  def canceled!
    return if processed?

    update!(self.class.canceled_at_column => Time.zone.now)
  end

  def processed?
    !!self[self.class.processed_at_column]
  end

  def attempted?
    !!self[self.class.attempted_at_column]
  end

  def submitted?
    !!self[self.class.submitted_at_column]
  end

  def canceled?
    !!self[self.class.canceled_at_column]
  end

  def asyncable_status
    if processed?
      :processed
    elsif canceled?
      :canceled
    elsif attempted?
      :attempted
    elsif submitted?
      :submitted
    else
      :not_yet_submitted
    end
  end

  def asyncable_user
    nil # abstract method intended to be overridden
  end

  def sanitized_error
    # keep PII out of output
    (self[self.class.error_column] || "none").gsub(/\s.+/m, "")
  end

  def expired_without_processing?
    return false if processed?

    last_submitted = self[self.class.last_submitted_at_column]
    return false unless last_submitted

    last_submitted < (self.class.requires_processing_until + self.class::EXPIRATION_WINDOW_BUFFER_HOURS.hours)
  end

  def submitted_and_ready?
    submitted? && self[self.class.last_submitted_at_column] <= Time.zone.now
  end

  def submitted_not_processed?
    submitted? && !processed?
  end

  def previously_attempted?
    self[self.class.last_submitted_at_column] != self[self.class.submitted_at_column]
  end

  def sort_by_last_submitted_at
    self[self.class.last_submitted_at_column] || Time.zone.now
  end

  def clear_error!
    update!(self.class.error_column => nil)
  end

  def update_error!(err)
    update!(self.class.error_column => err)
  end

  def restart!
    update!(
      self.class.last_submitted_at_column => Time.zone.now,
      self.class.processed_at_column => nil,
      self.class.attempted_at_column => nil,
      self.class.canceled_at_column => nil,
      self.class.error_column => nil
    )
  end

  def asyncable_ui_hash
    {
      klass: self.class.to_s,
      id: id,
      last_submitted_at: self[self.class.last_submitted_at_column],
      submitted_at: self[self.class.submitted_at_column],
      attempted_at: self[self.class.attempted_at_column],
      processed_at: self[self.class.processed_at_column],
      canceled_at: self[self.class.canceled_at_column],
      error: self[self.class.error_column],
      veteran_file_number: try(:veteran).try(:file_number),
      user: asyncable_user&.css_id
    }
  end

  def path
    "/asyncable_jobs/#{self.class}/jobs/#{id}"
  end

  def label
    "#{self.class} #{id}"
  end
end
# rubocop:enable Metrics/ModuleLength
