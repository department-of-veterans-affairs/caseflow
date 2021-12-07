# frozen_string_literal: true

class CertificationCancellation < CaseflowRecord
  belongs_to :certification
  validates :cancellation_reason, :email, :certification_id, presence: true
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: certification_cancellations
#
#  id                  :integer          not null, primary key
#  cancellation_reason :string
#  email               :string
#  other_reason        :string
#  created_at          :datetime
#  updated_at          :datetime         indexed
#  certification_id    :integer          indexed
#
# Foreign Keys
#
#  fk_rails_f67d0b282b  (certification_id => certifications.id)
#
