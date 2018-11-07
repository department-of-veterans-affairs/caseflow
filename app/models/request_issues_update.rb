# Represents the action where a Caseflow user updates the request issues on
# a review, typically to make a correction.

class RequestIssuesUpdate < ApplicationRecord
  include Asyncable

  belongs_to :user
  belongs_to :review, polymorphic: true

  attr_writer :request_issues_data
  attr_reader :error_code

  def perform!
    return false unless validate_before_perform
    return false if processed?

    transaction do
      review.create_issues!(new_issues)
      strip_removed_issues!
      review.mark_rating_request_issues_to_reassociate!

      update!(
        before_request_issue_ids: before_issues.map(&:id),
        after_request_issue_ids: after_issues.map(&:id)
      )
      submit_for_processing!
    end

    process_job

    true
  end

  def process_job
    if review.respond_to?(:process_end_product_establishments!)
      if run_async?
        ClaimReviewProcessJob.perform_later(self)
      else
        ClaimReviewProcessJob.perform_now(self)
      end
    else
      # appeals should just be set to processed
      attempted!
      processed!
    end
  end

  def process_end_product_establishments!
    attempted!

    review.process_end_product_establishments!

    removed_issues.each do |request_issue|
      request_issue.end_product_establishment.remove_contention!(request_issue)
    end

    potential_end_products_to_remove = removed_issues.map(&:end_product_establishment).uniq
    potential_end_products_to_remove.each(&:cancel_unused_end_product!)
    clear_error!
    processed!
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
        rating_issue_reference_id: issue_data[:reference_id],
        rating_issue_profile_date: issue_data[:profile_date],
        description: issue_data[:decision_text],
        decision_date: issue_data[:decision_date],
        issue_category: issue_data[:issue_category],
        notes: issue_data[:notes],
        is_unidentified: issue_data[:is_unidentified],
        untimely_exemption: issue_data[:untimely_exemption],
        untimely_exemption_notes: issue_data[:untimely_exemption_notes],
        ramp_claim_id: issue_data[:ramp_claim_id]
      ).tap do |request_issue|
        request_issue.validate_eligibility!
        request_issue.rating_issue_profile_date ||= issue_data[:profile_date]
      end
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
    elsif RequestIssuesUpdate.where(review: review).processable.exists?
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

  # Instead of fully deleting removed issues, we instead strip them from the review so we can
  # maintain a record of the other data that was on them incase we need to revert the update.
  def strip_removed_issues!
    removed_issues.each { |issue| issue.update!(review_request: nil) }
  end
end
