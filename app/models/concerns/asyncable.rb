# History of this class is in docs/asyncable-models.md
#
# Mixin module to apply to an ActiveRecord class, to make it easier to process via
# an ActiveJob and retry it beyond the retry logic of ActiveJob.
# This becomes necessary when a Job has multiple external service calls, each of
# which may fail and cause retries beyond the "normal" retry window.
# See ClaimReview and RequestIssuesUpdate e.g.
module Asyncable
  extend ActiveSupport::Concern

  # class methods to scope queries based on class-defined columns
  # we expect 4 column types:
  #  * submitted_at : make the job eligible to run
  #  * attempted_at : flag the job as having run
  #  * processed_at : flag the job as concluded
  #  * error        : any error message captured from a failed attempt.
  # These column names can be overridden in consuming classes as needed.
  class_methods do
    REQUIRES_PROCESSING_WINDOW_DAYS = 4
    REQUIRES_PROCESSING_RETRY_WINDOW_HOURS = 3

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

    def unexpired
      where(arel_table[submitted_at_column].gt(REQUIRES_PROCESSING_WINDOW_DAYS.days.ago))
    end

    def processable
      where(arel_table[submitted_at_column].lteq(Time.zone.now)).where(processed_at_column => nil)
    end

    def never_attempted
      where(attempted_at_column => nil)
    end

    def previously_attempted_ready_for_retry
      where(arel_table[attempted_at_column].lt(REQUIRES_PROCESSING_RETRY_WINDOW_HOURS.hours.ago))
    end

    def attemptable
      previously_attempted_ready_for_retry.or(never_attempted)
    end

    def order_by_oldest_submitted
      order(submitted_at_column => :asc)
    end

    def requires_processing
      processable.attemptable.unexpired.order_by_oldest_submitted
    end

    def expired_without_processing
      where(processed_at_column => nil)
        .where(arel_table[submitted_at_column].lteq(REQUIRES_PROCESSING_WINDOW_DAYS.days.ago))
        .order_by_oldest_submitted
    end

    def run_async?
      !Rails.env.development? && !Rails.env.test?
    end
  end

  def submit_for_processing!(delay: 0)
    update!(self.class.submitted_at_column => (Time.zone.now + delay), self.class.processed_at_column => nil)
  end

  def processed!
    update!(self.class.processed_at_column => Time.zone.now) unless processed?
  end

  def attempted!
    update!(self.class.attempted_at_column => Time.zone.now)
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

  def clear_error!
    update!(self.class.error_column => nil)
  end

  def update_error!(err)
    update!(self.class.error_column => err)
  end

  private

  def run_async?
    self.class.run_async?
  end
end
