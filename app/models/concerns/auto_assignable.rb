# frozen_string_literal: true

module AutoAssignable
  extend ActiveSupport::Concern
  include ActiveModel::Validations

  STATUS_STARTED = "started"
  STATUS_COMPLETED = "completed"
  STATUS_ERROR = "error"

  VALID_STATUSES = [
    STATUS_STARTED,
    STATUS_COMPLETED,
    STATUS_ERROR
  ]

  included do
    validates :status, inclusion: { in: VALID_STATUSES }
  end
end
