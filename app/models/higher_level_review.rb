# frozen_string_literal: true

class HigherLevelReview < ClaimReview
  with_options if: :saving_review do
    validates :informal_conference, :same_office, inclusion: { in: [true, false], message: "blank" }
  end

  has_many :remand_supplemental_claims, as: :decision_review_remanded, class_name: "SupplementalClaim"

  END_PRODUCT_MODIFIERS = %w[030 031 032 033 034 035 036 037 038 039].freeze

  def self.review_title
    Constants.INTAKE_FORM_NAMES_SHORT.higher_level_review
  end

  def ui_hash
    Intake::HigherLevelReviewSerializer.new(self).serializable_hash[:data][:attributes]
  end

  def stream_attributes
    super.merge(informal_conference: informal_conference, same_office: same_office)
  end

  def on_decision_issues_sync_processed
    create_remand_supplemental_claims!
  end

  # needed for appeal status api

  def review_status_id
    "HLR#{id}"
  end

  def linked_review_ids
    Array.wrap(review_status_id)
  end

  def incomplete
    false
  end

  def alerts
    @alerts ||= ApiStatusAlerts.new(decision_review: self).all.sort_by { |alert| alert[:details][:decisionDate] }
  end

  def active_status?
    # for the purposes for appeal status api, an HLR is considered active if there are
    # still active remand claims.
    active? || active_remanded_claims?
  end

  def dta_error_event_date
    return if active?
    return unless remand_supplemental_claims.any?

    decision_issues.remanded.first.approx_decision_date.to_date
  end

  def other_close_event_date
    return if active_status?
    return unless decision_issues.empty?
    return unless end_product_establishments.any?

    end_product_establishments.first.last_synced_at.to_date
  end

  def events
    @events ||= AppealEvents.new(appeal: self).all
  end

  def api_alerts_show_decision_alert?
    # for HLR, only want to show the decision alert when the HLR is no longer active,
    # meaning any remands have been resolved.
    !active_status? && decision_issues.any?
  end

  def due_date_to_appeal_decision
    # the deadline to contest the decision for this claim
    return remand_decision_event_date + 365.days if remand_decision_event_date

    return decision_event_date + 365.days if decision_event_date
  end

  def decision_date_for_api_alert
    return remand_decision_event_date if remand_decision_event_date

    decision_event_date
  end

  def available_review_options
    ["appeal"] if benefit_type == "fiduciary"

    %w[supplemental_claim appeal]
  end

  def fetch_status
    if active?
      :hlr_received
    elsif active_remanded_claims?
      :hlr_dta_error
    elsif remand_supplemental_claims.any?
      remand_supplemental_claims.each do |rsc|
        return :hlr_decision if rsc.decision_issues.any?
      end
      :hlr_closed
    else
      decision_issues.empty? ? :hlr_closed : :hlr_decision
    end
  end

  def fetch_details_for_status
    case fetch_status
    when :hlr_decision
      issue_list = fetch_all_decision_issues
      {
        issues: api_issues_for_status_details_issues(issue_list)
      }
    else
      {}
    end
  end

  private

  def new_end_product_establishment(issue, request_issues_update = nil)
    end_product_establishments.build(
      veteran_file_number: veteran_file_number,
      claim_date: receipt_date,
      payee_code: payee_code || EndProduct::DEFAULT_PAYEE_CODE,
      code: issue.end_product_code,
      claimant_participant_id: claimant_participant_id,
      station: request_issues_update ? request_issues_update.user.station_id : end_product_station,
      benefit_type_code: veteran.benefit_type_code,
      user: request_issues_update ? request_issues_update.user : intake_processed_by
    )
  end

  def api_issues_for_status_details_issues(issue_list)
    issue_list.map do |issue|
      {
        description: issue.api_status_description,
        disposition: issue.api_status_disposition
      }
    end
  end
end
