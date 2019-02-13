class SupplementalClaim < ClaimReview
  END_PRODUCT_MODIFIERS = %w[040 041 042 043 044 045 046 047 048 049].freeze

  belongs_to :decision_review_remanded, polymorphic: true

  def ui_hash
    super.merge(
      formType: "supplemental_claim",
      isDtaError: decision_review_remanded?
    )
  end

  def start_processing_job!
    if run_async?
      DecisionReviewProcessJob.perform_later(self)
    else
      DecisionReviewProcessJob.perform_now(self)
    end
  end

  def create_remand_issues!
    create_issues!(build_request_issues_from_remand)
  end

  def decision_review_remanded?
    !!decision_review_remanded
  end

  # needed for appeal status api

  def review_status_id
    "SC#{id}"
  end

  def linked_review_ids
    Array.wrap(review_status_id)
  end

  def active?
    end_product_establishments.any? { |ep| ep.status_active?(sync: false) }
  end

  def status_hash
    # need to implement. returns the details object for the status

    { type: fetch_status, details: fetch_details_for_status }
  end

  def alerts
    @alerts ||= ApiStatusAlerts.new(decision_review: self).all
  end

  def decision_event_date
    return unless decision_issues.any?

    if end_product_establishments.any?
      decision_issues.first.approx_decision_date
    else
      decision_issues.first.promulgation_date
    end
  end

  def other_close_event_date
    return if active?
    return unless decision_issues.empty?
    return unless end_product_establishments.any?

    end_product_establishments.first.last_synced_at
  end

  def events
    @events ||= AppealEvents.new(appeal: self).all
  end

  def fetch_all_decision_issues_for_api_status
    decision_issues
  end

  def available_review_options
    # the decision review options available to contest the decision for this claim
    # need to check if decision_review_remanded is contested claim somehow and only return ["appeal"]
    return ["higher_level_review", "appeal"] if benefit_type == "fiduciary"

    ["supplemental_claim", "higher_level_review", "appeal"]
  end

  def due_date_to_appeal_decision
    # the deadline to contest the decision for this claim
    decision_event_date + 365.days
  end

  def have_decision?
    fetch_status == :sc_decision
  end

  def decision_date_for_api_alert
    decision_event_date
  end

  private

  def end_product_created_by
    decision_review_remanded? ? User.system_user : intake_processed_by
  end

  def end_product_station
    decision_review_remanded? ? "397" : super
  end

  def new_end_product_establishment(ep_code)
    end_product_establishments.build(
      veteran_file_number: veteran_file_number,
      claim_date: receipt_date,
      payee_code: payee_code || EndProduct::DEFAULT_PAYEE_CODE,
      code: ep_code,
      claimant_participant_id: claimant_participant_id,
      station: end_product_station,
      benefit_type_code: veteran.benefit_type_code,
      user: end_product_created_by
    )
  end

  def build_request_issues_from_remand
    remanded_decision_issues_needing_request_issues.map do |remand_decision_issue|
      RequestIssue.new(
        review_request: self,
        contested_decision_issue_id: remand_decision_issue.id,
        contested_rating_issue_reference_id: remand_decision_issue.rating_issue_reference_id,
        contested_rating_issue_profile_date: remand_decision_issue.profile_date,
        contested_issue_description: remand_decision_issue.description,
        issue_category: remand_decision_issue.issue_category,
        benefit_type: benefit_type,
        decision_date: remand_decision_issue.approx_decision_date
      )
    end
  end

  def remanded_decision_issues_needing_request_issues
    remanded_decision_issues.reject(&:contesting_request_issue)
  end

  def remanded_decision_issues
    decision_review_remanded.decision_issues.remanded.where(benefit_type: benefit_type)
  end

  def fetch_status
    if active?
      :sc_recieved
    else
      decision_issues.empty? ? :sc_closed : :sc_decision
    end
  end

  def fetch_details_for_status
    case fetch_status
    when :sc_decision
      {
        issues: api_issues_for_status_details_issues
      }
    else
      {}
    end
  end

  def api_issues_for_status_details_issues
    decision_issues.map do |issue|
      {
        description: issue.api_status_description,
        disposition: issue.api_status_disposition
      }
    end
  end
end
