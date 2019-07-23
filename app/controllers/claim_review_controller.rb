# frozen_string_literal: true

class ClaimReviewController < ApplicationController
  before_action :verify_access, :react_routed, :set_application

  def edit
    # force sync on initial edit call so that we have latest EP status.
    # This helps prevent us editing something that recently closed upstream.
    claim_review.sync_end_product_establishments!

    # we call the serialization method here before the view does so we can rescue any data errors
    claim_review.ui_hash
  rescue RequestIssue::MissingDecisionDate
    flash[:error] = "VBMS or SHARE: One or more ratings may be locked on this Claim. Please try again in 24 hours."
    render "errors/500", layout: "application", status: :unprocessable_entity
  end

  def update
    if request_issues_update.perform!
      render_success
    else
      render json: { error_code: request_issues_update.error_code }, status: :unprocessable_entity
    end
  end

  private

  def source_type
    fail "Must override source_type"
  end

  def request_issues_update
    @request_issues_update ||= RequestIssuesUpdate.new(
      user: current_user,
      review: claim_review,
      request_issues_data: params[:request_issues]
    )
  end

  def claim_review
    @claim_review ||= source_type.constantize.find_by_uuid_or_reference_id!(url_claim_id)
  end

  def url_claim_id
    params.permit(:claim_id)[:claim_id]
  end

  helper_method :url_claim_id

  def set_application
    RequestStore.store[:application] = "intake"
  end

  def verify_access
    verify_authorized_roles("Mail Intake", "Admin Intake")
  end

  def render_success
    if claim_review.processed_in_caseflow?
      set_flash_success_message

      render json: { redirect_to: claim_review.business_line.tasks_url,
                     beforeIssues: request_issues_update.before_issues.map(&:ui_hash),
                     afterIssues: request_issues_update.after_issues.map(&:ui_hash),
                     withdrawnIssues: request_issues_update.withdrawn_issues.map(&:ui_hash),
                     correctedIssues: request_issues_update.corrected_issues.map(&:ui_hash) }
    else
      render json: {
        redirect_to: nil,
        beforeIssues: request_issues_update.before_issues.map(&:ui_hash),
        afterIssues: request_issues_update.after_issues.map(&:ui_hash),
        updatedIssues: request_issues_update.all_updated_issues.map(&:ui_hash),
        withdrawnIssues: nil,
        reviewWithdrawn: claim_review.withdrawn?
      }
    end
  end

  def withdrawn_issues
    withdrawn = request_issues_update.withdrawn_issues

    return if withdrawn.empty?

    "withdrawn #{withdrawn.count} #{'issue'.pluralize(withdrawn.count)}"
  end

  def added_issues
    new_issues = request_issues_update.after_issues - request_issues_update.before_issues
    return if new_issues.empty?

    "added #{new_issues.count} #{'issue'.pluralize(new_issues.count)}"
  end

  def removed_issues
    removed = request_issues_update.before_issues - request_issues_update.after_issues

    return if removed.empty?

    "removed #{removed.count} #{'issue'.pluralize(removed.count)}"
  end

  def review_edited_message
    "You have successfully " + [added_issues, removed_issues, withdrawn_issues].compact.to_sentence + "."
  end

  def set_flash_success_message
    flash[:edited] = if request_issues_update.after_issues.empty?
                       decisions_removed_message
                     elsif (request_issues_update.after_issues - request_issues_update.withdrawn_issues).empty?
                       review_withdrawn_message
                     else
                       review_edited_message
                     end
  end

  def decisions_removed_message
    claimant_name = claim_review.veteran_full_name
    "You have successfully removed #{claim_review.class.review_title} for #{claimant_name}
    (ID: #{claim_review.veteran.ssn})."
  end

  def review_withdrawn_message
    "You have successfully withdrawn a review."
  end
end
