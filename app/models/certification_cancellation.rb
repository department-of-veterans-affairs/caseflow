class CertificationCancellation < ActiveRecord::Base
  belongs_to :certification
  validates :cancellation_reason, :email, :certification_id, presence: true
end
