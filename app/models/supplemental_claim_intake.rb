class SupplementalClaimIntake < Intake
  include CachedAttributes

  enum error_code: {
    did_not_receive_supplemental_claim: "did_not_receive_supplemental_claim",
    supplemental_claim_already_complete: "supplemental_claim_already_complete",
    no_eligible_appeals: "no_eligible_appeals",
    no_active_compensation_appeals: "no_active_compensation_appeals",
    no_active_fully_compensation_appeals: "no_active_fully_compensation_appeals",
    no_active_appeals: "no_active_appeals",
    # This status will be set on successful intakes to signify that we had to
    # connect an existing EP, which in theory, shouldn't happen, but does in practice.
    connected_preexisting_ep: "connected_preexisting_ep"
  }.merge(Intake::ERROR_CODES)

  def supplemental_claim
    detail
  end

  def find_or_build_initial_detail
    matching_supplemental_claim
  end

  def review!(request_params)
    supplemental_claim.start_review!
    supplemental_claim.update_attributes(request_params.permit(:receipt_date, :option_selected))
  end

  def review_errors
    supplemental_claim.errors.messages
  end

  def complete!(_request_params)
    if supplemental_claim.create_or_connect_end_product! == :connected
      update!(error_code: "connected_preexisting_ep")
    end

    Appeal.close(
      appeals: eligible_appeals,
      user: user,
      closed_on: Time.zone.today,
      disposition: "RAMP Opt-in",
      election_receipt_date: supplemental_claim.receipt_date
    )

    transaction do
      complete_with_status!(:success)

      eligible_appeals.each do |appeal|
        RampClosedAppeal.create!(
          vacols_id: appeal.vacols_id,
          supplemental_claim_id: supplemental_claim.id,
          nod_date: appeal.nod_date
        )
      end
    end
  end

  def cancel!(reason:, other: nil)
    return if complete?

    transaction do
      detail.update_attributes!(
        receipt_date: nil,
        option_selected: nil
      )
      add_cancel_reason!(reason: reason, other: other)
      complete_with_status!(:canceled)
    end
  end

  cache_attribute :cached_serialized_appeal_issues, expires_in: 10.minutes do
    serialized_appeal_issues
  end

  def serialized_appeal_issues
    eligible_appeals.map do |appeal|
      {
        id: appeal.id,
        issues: appeal.compensation_issues.map(&:description_attributes)
      }
    end
  end

  def ui_hash
    super.merge(
      notice_date: supplemental_claim.notice_date,
      option_selected: supplemental_claim.option_selected,
      receipt_date: supplemental_claim.receipt_date,
      end_product_description: supplemental_claim.end_product_description,
      appeals: serialized_appeal_issues
    )
  end

  private

  # Appeals in VACOLS that will be closed out in favor of a new format review
  def eligible_appeals
    active_fully_compensation_appeals.select(&:eligible_for_ramp?)
  end

  # Temporarily only allow RAMP appeals with 100% compensation issues.
  # TODO: Take this out when we allow partial closing of appeals.
  def active_fully_compensation_appeals
    active_veteran_appeals.select(&:fully_compensation?)
  end

  def active_compensation_appeals
    active_veteran_appeals.select(&:compensation?)
  end

  def active_veteran_appeals
    @veteran_appeals ||= Appeal.fetch_appeals_by_file_number(veteran_file_number).select(&:active?)
  end

  def validate_detail_on_start
    if matching_supplemental_claim.established?
      self.error_code = :supplemental_claim_already_complete
      @error_data = { receipt_date: matching_supplemental_claim.receipt_date }

    elsif active_veteran_appeals.empty?
      self.error_code = :no_active_appeals

    elsif active_compensation_appeals.empty?
      self.error_code = :no_active_compensation_appeals

    elsif active_fully_compensation_appeals.empty?
      self.error_code = :no_active_fully_compensation_appeals

    elsif eligible_appeals.empty?
      self.error_code = :no_eligible_appeals
    end
  end

  def matching_supplemental_claim
    @supplemental_claim_on_create ||= veteran_supplemental_claims.all.first || veteran_supplemental_claims.build
  end

  def veteran_supplemental_claims
    RampElection.where(veteran_file_number: veteran_file_number)
  end
end
