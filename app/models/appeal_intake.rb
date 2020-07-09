# frozen_string_literal: true

class AppealIntake < DecisionReviewIntake
  attr_reader :request_params

  def find_or_build_initial_detail
    Appeal.new(veteran_file_number: veteran_file_number)
  end

  def ui_hash
    super.merge(docket_type: detail.docket_type)
  end

  def review!(request_params)
    @request_params = request_params

    transaction do
      detail.assign_attributes(appeal_params)
      create_claimant!
      detail.save(context: :intake_review)
    end
  rescue ActiveRecord::RecordInvalid
    set_review_errors
  end

  def complete!(request_params)
    super(request_params) do
      detail.update!(established_at: Time.zone.now)
      detail.set_target_decision_date!
      detail.create_tasks_on_intake_success!
      detail.submit_for_processing!
      if run_async?
        DecisionReviewProcessJob.perform_later(detail)
      else
        DecisionReviewProcessJob.perform_now(detail)
      end
    end
  end

  private

  def create_claimant!
    Claimant.find_or_initialize_by(
      decision_review: detail,
      type: claimant_type
    ).tap do |claimant|
      claimant.participant_id = participant_id
      claimant.notes = request_params[:claimant_notes]
      claimant.save!
    end
    update_person!
  end

  # If user has specified a different claimant, use that
  # Otherwise we use the veteran's participant_id, even for OtherClaimant
  def participant_id
    request_params[:claimant] || veteran.participant_id
  end

  def claimant_type
    if request_params[:claimant_type]
      "#{request_params[:claimant_type].capitalize}Claimant"
    elsif request_params[:veteran_is_not_claimant] == true
      "DependentClaimant"
    else
      "VeteranClaimant"
    end
  end

  def review_params
    request_params.permit(
      :claimant,
      :claimant_type,
      :claimant_notes,
      :id,
      :payee_code,
      :receipt_date,
      :docket_type,
      :veteran_is_not_claimant,
      :legacy_opt_in_approved
    )
  end

  def appeal_params
    keys_to_extract = [
      :receipt_date,
      :docket_type,
      :veteran_is_not_claimant,
      :legacy_opt_in_approved
    ]
    review_params.select { |key, _| keys_to_extract.include? key }
  end
end
