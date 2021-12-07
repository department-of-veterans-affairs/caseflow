# frozen_string_literal: true

class SupplementalClaimIntake < ClaimReviewIntake
  enum error_code: Intake::ERROR_CODES

  def find_or_build_initial_detail
    SupplementalClaim.new(veteran_file_number: veteran_file_number)
  end

  private

  def review_param_keys
    %w[receipt_date benefit_type legacy_opt_in_approved]
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
