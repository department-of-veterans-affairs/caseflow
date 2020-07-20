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

    # If there was a claimant of a different type for this appeal, remove it
    # This largely only happens in testing
    Claimant.where(decision_review: detail).where.not(type: claimant_type).take&.destroy!

    update_person!
  end

  def review_param_keys
    %w[receipt_date docket_type legacy_opt_in_approved]
  end
end
