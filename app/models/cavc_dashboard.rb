# frozen_string_literal: true

class CavcDashboard < CaseflowRecord
  include CreatedAndUpdatedByUserConcern

  has_many :cavc_dashboard_dispositions
  has_many :cavc_dashboard_issues
  belongs_to :cavc_remand

  validates :cavc_remand, presence: true
  validates :board_decision_date, :board_docket_number, :cavc_decision_date, :cavc_docket_number,
            presence: true, on: :update

  before_create :set_attributes_from_cavc_remand
  after_create :create_dispositions_for_remand_request_issues

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

  def remand_request_issues
    remand_appeal_issues = if cavc_remand.remand_appeal
                             cavc_remand.remand_appeal&.request_issues.order(:id)
                           else
                             []
                           end
    source_issues = cavc_remand.source_appeal&.request_issues.order(:id)

    remand_appeal_issues + source_issues.reject do |ri|
      remand_appeal_issues.any? do |rai|
        rai.description.gsub(/#\d+\z/, "").rstrip == ri.description && rai.benefit_type == ri.benefit_type
      end
    end
  end

  def create_dispositions_for_remand_request_issues
    remand_request_issues&.map do |issue|
      CavcDashboardDisposition.create(cavc_dashboard: self, request_issue: issue)
    end
  end
end
