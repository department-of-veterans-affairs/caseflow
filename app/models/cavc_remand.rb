# frozen_string_literal: true

# Model to store information captured when processing a form for an appeal remanded by CAVC
#
# CAVC Remands Overview: https://github.com/department-of-veterans-affairs/caseflow/wiki/CAVC-Remands

class CavcRemand < CaseflowRecord
  self.ignored_columns = ["appeal_id"]
  include UpdatedByUserConcern

  belongs_to :created_by, class_name: "User"
  belongs_to :source_appeal, class_name: "Appeal"

  validates :created_by, :source_appeal, :cavc_docket_number, :cavc_judge_full_name, :cavc_decision_type,
            :decision_date, :decision_issue_ids, :instructions, presence: true
  validates :represented_by_attorney, inclusion: { in: [true, false] }
  validates :cavc_judge_full_name, inclusion: { in: Constants::CAVC_JUDGE_FULL_NAMES }
  validates :remand_subtype, presence: true, if: :remand?
  validates :judgement_date, :mandate_date, presence: true, unless: -> { remand? && mdr? }
  validate :decision_issue_ids_match_appeal_decision_issues, if: -> { remand? && jmr? }

  after_save :establish_appeal_stream, if: :cavc_remand_form_complete?

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

  private

  def decision_issue_ids_match_appeal_decision_issues
    unless (source_appeal.decision_issues.map(&:id) - decision_issue_ids).empty?
      fail Caseflow::Error::JmrAppealDecisionIssueMismatch, message: "JMR remands must address all decision issues"
    end
  end

  def cavc_remand_form_complete?
    if mdr?
      valid?
    else
      valid? && !mandate_date.nil? && !judgement_date.nil?
    end
  end

  def establish_appeal_stream
    source_appeal.create_stream(:court_remand).tap do |cavc_appeal|
      DecisionIssue.find(decision_issue_ids).map do |cavc_remanded_issue|
        cavc_remanded_issue.create_contesting_request_issue!(cavc_appeal)
      end
      AdvanceOnDocketMotion.copy_granted_motions_to_appeal(source_appeal, cavc_appeal)
      InitialTasksFactory.new(cavc_appeal).create_root_and_sub_tasks!
    end
  end
end
