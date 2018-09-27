# Represents the action where a Caseflow user updates the request issues on
# a review, typically to make a correction.

class RequestIssuesUpdate < ApplicationRecord
  include Asyncable

  belongs_to :user
  belongs_to :review, polymorphic: true

  attr_writer :request_issues_data
  attr_reader :error_code

  REQUIRES_PROCESSING_WINDOW_DAYS = 4
  REQUIRES_PROCESSING_RETRY_WINDOW_HOURS = 3

  class << self
    def unexpired
      where("submitted_at > ?", REQUIRES_PROCESSING_WINDOW_DAYS.days.ago)
    end

    def processable
      where.not(submitted_at: nil).where(processed_at: nil)
    end

    def never_attempted
      where(attempted_at: nil)
    end

    def previously_attempted_ready_for_retry
      where("attempted_at < ?", REQUIRES_PROCESSING_RETRY_WINDOW_HOURS.hours.ago)
    end

    def attemptable
      previously_attempted_ready_for_retry.or(never_attempted)
    end

    def order_by_oldest_submitted
      order("submitted_at ASC")
    end

    def requires_processing
      processable.attemptable.unexpired.order_by_oldest_submitted
    end

    def expired_without_processing
      where(processed_at: nil)
        .where("submitted_at <= ?", REQUIRES_PROCESSING_WINDOW_DAYS.days.ago)
        .order("submitted_at ASC")
    end
  end

  def submit_for_processing!
    update!(submitted_at: Time.zone.now, processed_at: nil)
  end

  def processed!
    update!(processed_at: Time.zone.now) unless processed?
  end

  def attempted!
    update!(attempted_at: Time.zone.now)
  end

  def processed?
    !!processed_at
  end

  def perform!
    return false unless validate_before_perform
    return false if processed?

    transaction do
      review.create_issues!(new_issues)
      strip_removed_issues!

      update!(
        before_request_issue_ids: before_issues.map(&:id),
        after_request_issue_ids: after_issues.map(&:id)
      )
      submit_for_processing!
    end

    if run_async?
      RequestIssuesUpdateJob.perform_later(self)
    else
      RequestIssuesUpdateJob.perform_now(self)
    end

    true
  end

  def created_issues
    after_issues - before_issues
  end

  def removed_issues
    before_issues - after_issues
  end

  private

  def changes?
    review.request_issues.count != @request_issues_data.count || !new_issues.empty?
  end

  def new_issues
    after_issues.reject(&:persisted?)
  end

  def before_issues
    @before_issues ||= before_request_issue_ids ? fetch_before_issues : calculate_before_issues
  end

  def after_issues
    @after_issues ||= after_request_issue_ids ? fetch_after_issues : calculate_after_issues
  end

  def calculate_after_issues
    # need to calculate and store before issues before we add new request issues
    before_issues

    @request_issues_data.map do |issue_data|
      review.request_issues.find_or_initialize_by(
        rating_issue_profile_date: issue_data[:profile_date],
        rating_issue_reference_id: issue_data[:reference_id],
        description: issue_data[:decision_text]
      )
    end
  end

  def calculate_before_issues
    review.request_issues.select(&:persisted?)
  end

  def validate_before_perform
    if @request_issues_data.blank?
      @error_code = :request_issues_data_empty
    elsif !changes?
      @error_code = :no_changes
    end

    !@error_code
  end

  def fetch_before_issues
    RequestIssue.where(id: before_request_issue_ids)
  end

  def fetch_after_issues
    RequestIssue.where(id: after_request_issue_ids)
  end

  # Instead of fully deleting removed issues, we instead strip them from the review so we can
  # maintain a record of the other data that was on them incase we need to revert the update.
  def strip_removed_issues!
    removed_issues.each { |issue| issue.update!(review_request: nil) }
  end
end
