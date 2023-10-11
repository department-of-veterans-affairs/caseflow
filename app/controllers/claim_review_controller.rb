# frozen_string_literal: true

class ClaimReviewController < ApplicationController
  include ValidationConcern

  before_action :verify_access, :react_routed, :set_application

  EDIT_ERRORS = {
    "RequestIssue::MissingDecisionDate" => COPY::CLAIM_REVIEW_EDIT_ERROR_MISSING_DECISION_DATE,
    "StandardError" => COPY::CLAIM_REVIEW_EDIT_ERROR_DEFAULT
  }.freeze

  def edit
    redirect_to "/unauthorized" if claim_review.benefit_type == "vha" &&
                                   !VhaBusinessLine.singleton.user_is_admin?(current_user)
    unless claim_review.veteran.accessible?
      return render "errors/403",
                    layout: "application",
                    status: :forbidden,
                    locals: {
                      error_title: COPY::VETERAN_NOT_ACCESSIBLE_ERROR_TITLE,
                      error_detail: COPY::VETERAN_NOT_ACCESSIBLE_ERROR_DETAIL
                    }
    end

    claim_review.validate_prior_to_edit
  rescue ActiveRecord::RecordNotFound => error
    raise error # re-throw so base controller handles it.
  rescue StandardError => error
    render_error(error)
  end

  def update
    if request_issues_update.perform!
      render_success
    else
      render json: { error_code: request_issues_update.error_code }, status: :unprocessable_entity
    end
  end

  validates :edit_ep, using: ClaimReviewSchemas.edit_ep
  def edit_ep
    epe = claim_review.end_product_establishments.find_by(code: claim_label_edit_params[:previous_code])
    return render json: { error_code: "EP not found" }, status: :not_found if epe.nil?

    edit_ep = perform_ep_update!(epe)
    if edit_ep.error?
      render json: { error_code: "Error updating ep" }, status: :unprocessable_entity
    else
      render json: { veteran: claim_review.veteran }
    end
  rescue StandardError
    render json: { error_code: "Unknown error" }, status: :unprocessable_entity
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

  def render_error(error)
    Rails.logger.error("#{error.message}\n#{error.backtrace.join("\n")}")
    Raven.capture_exception(error, extra: { error_uuid: error_uuid })
    error_class = error.class.to_s
    flash[:error] = format(EDIT_ERRORS[error_class] || EDIT_ERRORS["StandardError"], claim_review.async_job_url)
    render "errors/500", layout: "application", status: :unprocessable_entity
  end

  def render_success
    if claim_review.processed_in_caseflow?
      set_flash_success_message

      render json: { redirect_to: claim_review.redirect_url,
                     beforeIssues: request_issues_update.before_issues.map(&:serialize),
                     afterIssues: request_issues_update.after_issues.map(&:serialize),
                     withdrawnIssues: request_issues_update.withdrawn_issues.map(&:serialize) }
    else
      render json: {
        redirect_to: nil,
        beforeIssues: request_issues_update.before_issues.map(&:serialize),
        afterIssues: request_issues_update.after_issues.map(&:serialize),
        updatedIssues: request_issues_update.all_updated_issues.map(&:serialize),
        withdrawnIssues: nil
      }
    end
  end

  def withdrawn_issues
    withdrawn = request_issues_update.withdrawn_issues

    return if withdrawn.empty?

    "withdrawn #{withdrawn.count} #{'issue'.pluralize(withdrawn.count)}"
  end

  def added_issues
    new_issues = request_issues_update.added_issues
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

  def vha_edited_decision_date_message
    COPY::VHA_ADD_DECISION_DATE_TO_ISSUE_SUCCESS_MESSAGE
  end

  def vha_established_message
    "You have successfully established #{claimant_name}'s #{claim_review.class.review_title}"
  end

  def claimant_name
    if claim_review.veteran_is_not_claimant
      claim_review.claimant.try(:name)
    else
      claim_review.veteran_full_name
    end
  end

  def vha_flash_message
    issues_without_decision_date = (request_issues_update.after_issues -
                                request_issues_update.edited_issues -
                                request_issues_update.removed_or_withdrawn_issues)
      .select { |issue| issue.decision_date.blank? && !issue.withdrawn? }

    if issues_without_decision_date.empty?
      vha_established_message
    elsif request_issues_update.edited_issues.any?
      vha_edited_decision_date_message
    else
      review_edited_message
    end
  end

  def set_flash_success_message
    flash[:edited] = if request_issues_update.after_issues.empty?
                       decisions_removed_message
                     elsif (request_issues_update.after_issues - request_issues_update.withdrawn_issues).empty?
                       review_withdrawn_message
                     elsif claim_review.benefit_type == "vha"
                       vha_flash_message
                     else
                       review_edited_message
                     end
  end

  def decisions_removed_message
    "You have successfully removed #{claim_review.class.review_title} for #{claimant_name}
    (ID: #{claim_review.veteran.ssn})."
  end

  def review_withdrawn_message
    COPY::CLAIM_REVIEW_WITHDRAWN_MESSAGE
  end

  def claim_label_edit_params
    params.permit(:previous_code, :selected_code)
  end

  def perform_ep_update!(epe)
    ep_update = EndProductUpdate.create!(
      end_product_establishment: epe,
      original_decision_review: claim_review,
      original_code: claim_label_edit_params[:previous_code],
      new_code: claim_label_edit_params[:selected_code],
      user: current_user
    )
    ep_update.perform!
    ep_update
  end
end
