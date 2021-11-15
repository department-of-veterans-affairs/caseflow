# frozen_string_literal: true

class AppealIntake < DecisionReviewIntake
  attr_reader :request_params

  def find_or_build_initial_detail
    Appeal.new(veteran_file_number: veteran_file_number)
  end

  def ui_hash
    Intake::AppealIntakeSerializer.new(self).serializable_hash[:data][:attributes]
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

  def need_payee_code?
    false
  end

  def review_param_keys
    %w[receipt_date docket_type legacy_opt_in_approved filed_by_va_gov]
  end
end
