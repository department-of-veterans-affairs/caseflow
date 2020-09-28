# frozen_string_literal: true

# Record to store information captured when processing a cavc remand in caseflow
class CavcRemand < CaseflowRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  belongs_to :appeal

  validates :created_by, :updated_by, :appeal, :cavc_docket_number, :attorney_represented, :cavc_judge_full_name,
            :cavc_type, :decision_date, :decision_issue_ids, :instructions, presence: true
  validates :judgement_date, :mandate_date, presence: true, if: -> { jmr? || jmpr? }
  validates :cavc_judge_full_name, inclusion: { in: Constants::CAVC_JUDGE_FULL_NAMES }
  validate :decision_issue_ids_match_appeal_decision_issues, if: :jmr?

  enum cavc_type: {
    Constants.CAVC_TYPES.remand.to_sym => Constants.CAVC_TYPES.remand,
    Constants.CAVC_TYPES.straight_reversal.to_sym => Constants.CAVC_TYPES.straight_reversal,
    Constants.CAVC_TYPES.death_dismissal.to_sym => Constants.CAVC_TYPES.death_dismissal
  }

  enum remand_type: {
    Constants.CAVC_REMAND_TYPES.jmr.to_sym => Constants.CAVC_REMAND_TYPES.jmr,
    Constants.CAVC_REMAND_TYPES.jmpr.to_sym => Constants.CAVC_REMAND_TYPES.jmpr,
    Constants.CAVC_REMAND_TYPES.mdr.to_sym => Constants.CAVC_REMAND_TYPES.mdr
  }

  def decision_issue_ids_match_appeal_decision_issues
    appeal.decision_issues.to_set == decision_issue_ids.to_set
  end
end
