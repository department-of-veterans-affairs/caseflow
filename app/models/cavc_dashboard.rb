# frozen_string_literal: true

class CavcDashboard < CaseflowRecord
  include CreatedAndUpdatedByUserConcern

  has_many :cavc_dashboard_dispositions
  has_many :cavc_dashboard_issues
  belongs_to :cavc_remand

  validates :cavc_remand, presence: true

  before_create :set_attributes_from_cavc_remand

  def set_attributes_from_cavc_remand
    self.board_decision_date = cavc_remand.source_appeal.decision_date
    self.board_docket_number = cavc_remand.source_appeal.stream_docket_number
    self.cavc_decision_date = cavc_remand.decision_date
    self.cavc_docket_number = cavc_remand.cavc_docket_number
    self.joint_motion_for_remand =
      cavc_remand.remand_subtype == Constants.CAVC_REMAND_SUBTYPES.jmr ||
      cavc_remand.remand_subtype == Constants.CAVC_REMAND_SUBTYPES.jmpr ||
      cavc_remand.remand_subtype == Constants.CAVC_REMAND_SUBTYPES.jmr_jmpr
  end

  def source_request_issues
    cavc_remand.source_appeal.request_issues
  end
end
