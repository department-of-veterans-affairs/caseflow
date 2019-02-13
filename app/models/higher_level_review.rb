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
    super.merge(
      formType: "higher_level_review",
      sameOffice: same_office,
      informalConference: informal_conference
    )
  end

  def on_decision_issues_sync_processed(_end_product_establishment)
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

  def status_hash
    { type: fetch_status, details: fetch_details_for_status }
  end

  def alerts
    # need to implement. add logic to return alert enum
  end

  def dta_error_event_date
    return if active?
    return unless remand_supplemental_claims.any?

    decision_issues.remanded.first.approx_decision_date
  end

  def other_close_event_date
    return if active? || active_remanded_claims?
    return unless decision_issues.empty?
    return unless end_product_establishments.any?

    end_product_establishments.first.last_synced_at
  end

  def events
    @events ||= AppealEvents.new(appeal: self).all
  end

  private

  def informal_conference?
    informal_conference
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
      user: intake_processed_by
    )
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

  def api_issues_for_status_details_issues(issue_list)
    issue_list.map do |issue|
      {
        description: issue.api_status_description,
        disposition: issue.api_status_disposition
      }
    end
  end
end
