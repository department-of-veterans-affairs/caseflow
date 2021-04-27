# frozen_string_literal: true

# Represents the action where a Caseflow user updates the request issues on
# a review, typically to make a correction.

class RequestIssuesUpdate < CaseflowRecord
  include Asyncable

  belongs_to :user
  belongs_to :review, polymorphic: true

  attr_writer :request_issues_data
  attr_reader :error_code

  delegate :veteran, :cancel_active_tasks, :create_business_line_tasks!, to: :review
  delegate :withdrawn_issues, to: :withdrawal
  delegate :corrected_issues, :correction_issues, to: :correction

  def perform!
    return false unless validate_before_perform
    return false if processed?

    transaction do
      process_issues!
      review.mark_rating_request_issues_to_reassociate!
      update!(
        before_request_issue_ids: before_issues.map(&:id),
        after_request_issue_ids: after_issues.map(&:id),
        withdrawn_request_issue_ids: withdrawn_issues.map(&:id),
        edited_request_issue_ids: edited_issues.map(&:id),
        corrected_request_issue_ids: corrected_issues.map(&:id)
      )
      create_business_line_tasks! if added_issues.present?
      cancel_active_tasks
      submit_for_processing!
    end

    process_job

    true
  end

  def process_job
    if run_async?
      DecisionReviewProcessJob.perform_later(self)
    else
      DecisionReviewProcessJob.perform_now(self)
    end
  end

  # establish! is called async via DecisionReviewProcessJob.
  # it is queued via submit_for_processing! in the perform! method above.
  def establish!
    attempted!

    review.establish!
    edited_issues.each { |issue| RequestIssueContention.new(issue).update_text! }
    potential_end_products_to_remove = []
    removed_or_withdrawn_issues.select(&:end_product_establishment).each do |request_issue|
      RequestIssueContention.new(request_issue).remove!
      potential_end_products_to_remove << request_issue.end_product_establishment
    end

    potential_end_products_to_remove.uniq.each(&:cancel_unused_end_product!)
    clear_error!
    processed!
  end

  def added_issues
    after_issues - before_issues
  end

  def removed_issues
    before_issues - after_issues
  end

  def removed_or_withdrawn_issues
    removed_issues + withdrawn_issues
  end

  def before_issues
    @before_issues ||= before_request_issue_ids ? fetch_before_issues : calculate_before_issues
  end

  def after_issues
    @after_issues ||= after_request_issue_ids ? fetch_after_issues : calculate_after_issues
  end

  def edited_issues
    @edited_issues ||= edited_request_issue_ids ? fetch_edited_issues : calculate_edited_issues
  end

  def all_updated_issues
    added_issues + removed_issues + withdrawn_issues + edited_issues + correction_issues
  end

  private

  def changes?
    (all_updated_issues + corrected_issues).any?
  end

  def calculate_after_issues
    # need to calculate and store before issues before we add new request issues
    before_issues

    @request_issues_data.map do |issue_data|
      review.find_or_build_request_issue_from_intake_data(issue_data)
    end
  end

  def calculate_edited_issues
    edited_issue_data.map do |issue_data|
      review.find_or_build_request_issue_from_intake_data(issue_data)
    end
  end

  def edited_issue_data
    return [] unless @request_issues_data

    @request_issues_data.select { |ri| ri[:edited_description].present? && ri[:request_issue_id] }
  end

  def calculate_before_issues
    review.request_issues.active_or_ineligible.select(&:persisted?)
  end

  def validate_before_perform
    if !changes?
      @error_code = :no_changes
    elsif RequestIssuesUpdate.where(review: review).where.not(id: id).processable.exists?
      @error_code = :previous_update_not_done_processing
    end

    !@error_code
  end

  def fetch_before_issues
    RequestIssue.where(id: before_request_issue_ids)
  end

  def fetch_after_issues
    RequestIssue.where(id: after_request_issue_ids)
  end

  def fetch_edited_issues
    RequestIssue.where(id: edited_request_issue_ids)
  end

  def process_issues!
    review.create_issues!(added_issues, self)
    process_removed_issues!
    process_legacy_issues!
    process_withdrawn_issues!
    process_edited_issues!
    process_corrected_issues!
  end

  def process_legacy_issues!
    LegacyOptinManager.new(decision_review: review).process!
  end

  def process_withdrawn_issues!
    withdrawal.call
  end

  def withdrawal
    @withdrawal ||= RequestIssueWithdrawal.new(
      user: user,
      request_issues_update: self,
      request_issues_data: @request_issues_data
    )
  end

  def process_edited_issues!
    return if edited_issues.empty?

    edited_issue_data.each do |edited_issue|
      RequestIssue.find(
        edited_issue[:request_issue_id].to_s
      ).save_edited_contention_text!(edited_issue[:edited_description])
    end
  end

  def process_removed_issues!
    removed_issues.each(&:remove!)
  end

  def correction
    @correction ||= RequestIssueCorrection.new(
      review: review,
      corrected_request_issue_ids: corrected_request_issue_ids,
      request_issues_data: @request_issues_data
    )
  end

  def process_corrected_issues!
    correction.call
  end
end
