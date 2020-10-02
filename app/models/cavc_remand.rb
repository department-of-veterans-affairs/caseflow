# frozen_string_literal: true

# Model to store information captured when processing a form for an appeal remanded by CAVC

class CavcRemand < CaseflowRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  belongs_to :appeal

  validates :created_by, :updated_by, :appeal, :cavc_docket_number, :represented_by_attorney, :cavc_judge_full_name,
            :cavc_decision_type, :decision_date, :decision_issue_ids, :instructions, presence: true
  validates :remand_subtype, presence: true, if: :remand?
  validates :judgement_date, :mandate_date, presence: true, unless: :mdr?
  validates :cavc_judge_full_name, inclusion: { in: Constants::CAVC_JUDGE_FULL_NAMES }
  validate :decision_issue_ids_match_appeal_decision_issues, if: :jmr?

  enum cavc_decision_type: {
    Constants.CAVC_DECISION_TYPES.remand.to_sym => Constants.CAVC_DECISION_TYPES.remand,
    Constants.CAVC_DECISION_TYPES.straight_reversal.to_sym => Constants.CAVC_DECISION_TYPES.straight_reversal,
    Constants.CAVC_DECISION_TYPES.death_dismissal.to_sym => Constants.CAVC_DECISION_TYPES.death_dismissal
  }

  # Joint Motion Remand, Joint Motion Partial Remand, and Memorandum Decision on Remand
  # The Board uses the initialisms more than the full words, so we are following that norm
  enum remand_subtype: {
    Constants.CAVC_REMAND_SUBTYPES.jmr.to_sym => Constants.CAVC_REMAND_SUBTYPES.jmr,
    Constants.CAVC_REMAND_SUBTYPES.jmpr.to_sym => Constants.CAVC_REMAND_SUBTYPES.jmpr,
    Constants.CAVC_REMAND_SUBTYPES.mdr.to_sym => Constants.CAVC_REMAND_SUBTYPES.mdr
  }

  def decision_issue_ids_match_appeal_decision_issues
    unless (appeal.decision_issues.map(&:id) - decision_issue_ids).empty?
      fail Caseflow::Error::JmrAppealDecisionIssueMismatch, message: "JMR remands must address all decision issues"
    end
  end
end
