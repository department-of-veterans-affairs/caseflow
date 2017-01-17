class CertificationCancellation
  include ActiveModel::Model

  attr_accessor :certification, :cancellation_reason, :other_reason, :email
end
