# frozen_string_literal: true

class CavcDashboardDisposition < CaseflowRecord
  include CreatedAndUpdatedByUserConcern

  belongs_to :cavc_remand

  validates :cavc_remand, presence: true
  # disposition can be nil on create, so only validate on update
  validates :disposition, presence: true, on: :update

  # invert the hash so the database entries have underscores and the return value is the formatted string
  enum disposition: Constants::CAVC_DASHBOARD_DISPOSITIONS.invert
end
