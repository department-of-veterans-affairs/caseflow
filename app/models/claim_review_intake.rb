# frozen_string_literal: true

class ClaimReviewIntake < DecisionReviewIntake
  attr_reader :request_params

  def ui_hash
    Intake::ClaimReviewIntakeSerializer.new(self).serializable_hash[:data][:attributes]
  end

  def review!(request_params)
    detail.start_review!

    @request_params = request_params

    transaction do
      detail.assign_attributes(review_params)
      create_claimant!
      detail.save!
    end
  rescue ActiveRecord::RecordInvalid
    set_review_errors
  end

  def complete!(request_params)
    super(request_params) do
      detail.submit_for_processing!
      detail.add_user_to_business_line!
      detail.create_business_line_tasks!
      if run_async?
        DecisionReviewProcessJob.perform_later(detail)
      else
        DecisionReviewProcessJob.perform_now(detail)
      end
    end
  end

  private

  def need_payee_code?
    # payee_code is only required for claim reviews where the claimant is a dependent
    # and the benefit_type is compensation, pension, and fiduciary
    return unless claimant_class_name == "DependentClaimant"

    ClaimantValidator::BENEFIT_TYPE_REQUIRES_PAYEE_CODE.include?(request_params[:benefit_type])
  end
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: intakes
#
#  id                    :integer          not null, primary key
#  cancel_other          :string
#  cancel_reason         :string
#  completed_at          :datetime
#  completion_started_at :datetime
#  completion_status     :string
#  detail_type           :string           indexed => [detail_id]
#  error_code            :string
#  started_at            :datetime
#  type                  :string           indexed, indexed => [veteran_file_number]
#  veteran_file_number   :string           indexed, indexed => [type]
#  created_at            :datetime
#  updated_at            :datetime         indexed
#  detail_id             :integer          indexed => [detail_type]
#  user_id               :integer          not null, indexed, indexed
#  veteran_id            :bigint           indexed
#
# Foreign Keys
#
#  fk_rails_2f8c8dd745  (veteran_id => veterans.id)
#  fk_rails_5601279132  (user_id => users.id)
#
