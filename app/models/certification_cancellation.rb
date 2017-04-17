class CertificationCancellation < ActiveRecord::Base
  belongs_to :certification
  validates_presence_of :cancellation_reason, :email, :certification_id
end
