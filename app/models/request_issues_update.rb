# frozen_string_literal: true

# Represents the action where a Caseflow user updates the request issues on
# a review, typically to make a correction.

class RequestIssuesUpdate < ApplicationRecord
  include Asyncable

  belongs_to :user
  belongs_to :review, polymorphic: true

  attr_writer :request_issues_data
  attr_reader :error_code

  delegate :veteran, to: :review

  def perform!
    return false unless validate_before_perform
    return false if processed?

    transaction do
      review.create_issues!(new_issues)
      process_removed_issues!
      process_legacy_issues!
      process_withdrawn_issues!
      review.mark_rating_request_issues_to_reassociate!

      update!(
        before_request_issue_ids: before_issues.map(&:id),
        after_request_issue_ids: after_issues.map(&:id),
        withdrawn_request_issue_ids: withdrawn_issues.map(&:id)
      )
      cancel_active_tasks
      submit_for_processing!
      process_job
    end

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

    potential_end_products_to_remove = []
    removed_or_withdrawn_issues.select(&:end_product_establishment).each do |request_issue|
      request_issue.end_product_establishment.remove_contention!(request_issue)
      potential_end_products_to_remove << request_issue.end_product_establishment
    end

    potential_end_products_to_remove.uniq.each(&:cancel_unused_end_product!)
    clear_error!
    processed!
  end

  def created_issues
    after_issues - before_issues
  end

  def removed_issues
    before_issues - after_issues
  end

  def removed_or_withdrawn_issues
    removed_issues + withdrawn_issues
  end

  def persisted_issues
    after_issues - withdrawn_issues
  end

  def before_issues
    @before_issues ||= before_request_issue_ids ? fetch_before_issues : calculate_before_issues
  end

  def after_issues
    @after_issues ||= after_request_issue_ids ? fetch_after_issues : calculate_after_issues
  end

  def withdrawn_issues
    @withdrawn_issues ||= withdrawn_request_issue_ids ? fetch_withdrawn_issues : calculate_withdrawn_issues
  end

  private

  def changes?
    review.request_issues.active_or_ineligible.count != @request_issues_data.count || !new_issues.empty? ||
      !withdrawn_issues.empty?
  end

  def new_issues
    after_issues.reject(&:persisted?)
  end

  def calculate_after_issues
    # need to calculate and store before issues before we add new request issues
    before_issues

    @request_issues_data.map do |issue_data|
      review.find_or_build_request_issue_from_intake_data(issue_data)
    end
  end

  def calculate_withdrawn_issues
    withdrawn_issue_data.map do |issue_data|
      review.find_or_build_request_issue_from_intake_data(issue_data)
    end
  end

  def withdrawn_issue_data
    @request_issues_data.select { |ri| !ri[:withdrawal_date].nil? && ri[:request_issue_id] }
  end

  def calculate_before_issues
    review.request_issues.active_or_ineligible.select(&:persisted?)
  end

  def validate_before_perform
    if @request_issues_data.blank? && !allow_zero_request_issues
      @error_code = :request_issues_data_empty
    elsif !changes?
      @error_code = :no_changes
    elsif RequestIssuesUpdate.where(review: review).processable.exists?
      @error_code = :previous_update_not_done_processing
    end

    !@error_code
  end

  def allow_zero_request_issues
    FeatureToggle.enabled?(:remove_decision_reviews, user: RequestStore.store[:current_user])
  end

  def fetch_before_issues
    RequestIssue.where(id: before_request_issue_ids)
  end

  def fetch_after_issues
    RequestIssue.where(id: after_request_issue_ids)
  end

  def fetch_withdrawn_issues
    RequestIssue.where(id: withdrawn_request_issue_ids)
  end

  def process_legacy_issues!
    LegacyOptinManager.new(decision_review: review).process!
  end

  def process_withdrawn_issues!
    return if withdrawn_issues.empty?

    withdrawal_date = withdrawn_issue_data.first[:withdrawal_date]
    withdrawn_issues.each { |ri| ri.withdraw!(withdrawal_date) }
  end

  def process_removed_issues!
    removed_issues.each(&:remove!)
  end

  def cancel_active_tasks
    persisted_issues.empty? && review.cancel_active_tasks
  end
end
