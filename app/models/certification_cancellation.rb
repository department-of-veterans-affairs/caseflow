# frozen_string_literal: true

class CertificationCancellation < CaseflowRecord
  belongs_to :certification
  validates :cancellation_reason, :email, :certification_id, presence: true
end
