# frozen_string_literal: true

module AutoAssignable
  extend ActiveSupport::Concern
  include ActiveModel::Validations

  VALID_STATUSES = [
    Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.started,
    Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.completed,
    Constants.CORRESPONDENCE_AUTO_ASSIGNMENT.statuses.error
  ].freeze

  included do
    validates :status, inclusion: { in: VALID_STATUSES }
  end
end
