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
      detail.assign_attributes(review_params)
      Claimant.find_or_initialize_by(
        decision_review: detail
      ).tap do |claimant|
        claimant.participant_id = claimant_participant_id
        claimant.payee_code = nil
        claimant.save!
      end
      update_person!
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

  def claimant_participant_id
    (request_params[:veteran_is_not_claimant] == true) ? request_params[:claimant] : veteran.participant_id
  end

  def review_params
    request_params.permit(
      :receipt_date,
      :docket_type,
      :veteran_is_not_claimant,
      :legacy_opt_in_approved
    )
  end
end
