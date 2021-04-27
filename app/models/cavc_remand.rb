# frozen_string_literal: true

# Model to store information captured when processing a form for an appeal remanded by CAVC
#
# CAVC Remands Overview: https://github.com/department-of-veterans-affairs/caseflow/wiki/CAVC-Remands

class CavcRemand < CaseflowRecord
  include UpdatedByUserConcern

  belongs_to :created_by, class_name: "User"
  belongs_to :source_appeal, class_name: "Appeal"
  belongs_to :remand_appeal, class_name: "Appeal"

  validates :created_by, :source_appeal, :cavc_docket_number, :cavc_judge_full_name, :cavc_decision_type,
            :decision_date, :decision_issue_ids, :instructions, presence: true
  validates :represented_by_attorney, inclusion: { in: [true, false] }
  validates :cavc_judge_full_name, inclusion: { in: Constants::CAVC_JUDGE_FULL_NAMES }
  validates :remand_subtype, presence: true, if: :remand?
  validates :judgement_date, :mandate_date, presence: true, unless: :mandate_not_required?
  validate :decision_issue_ids_match_appeal_decision_issues, if: -> { remand? && jmr? }
  validates :federal_circuit, inclusion: { in: [true, false] }, if: -> { remand? && mdr? }

  before_create :normalize_cavc_docket_number
  before_create :establish_appeal_stream, if: :cavc_remand_form_complete?
  after_create :initialize_tasks

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

  # called from the Add Cavc Date Modal
  def add_cavc_dates(params)
    if already_has_mandate?
      fail Caseflow::Error::CannotUpdateMandatedRemands
    end

    update_with_instructions(params)
    end_mandate_hold
  end

  # called from the Edit Remand Form
  def update(params)
    # Identify changes
    decision_issue_ids_as_ints = params[:decision_issue_ids].map(&:to_i)
    decision_issue_ids_add = decision_issue_ids_as_ints - decision_issue_ids
    decision_issue_ids_remove = decision_issue_ids - decision_issue_ids_as_ints
    new_decision_date = (Date.parse(params[:decision_date]) - decision_date).to_i.abs > 0

    # Update self
    update!(params)

    # Apply changes to other records
    if decision_issue_ids_add.any? || decision_issue_ids_remove.any?
      update_request_issues(add_ids: decision_issue_ids_add, remove_ids: decision_issue_ids_remove)
    end

    update_timed_hold if new_decision_date
  end

  private

  def update_timed_hold
    if mandate_not_required?
      parent_task_types = [:MdrTask, :MandateHoldTask]
      # There should only be 1 open timed_hold_parent_task
      remand_appeal.tasks.open.where(type: parent_task_types).find_each(&:update_timed_hold)
    end
  end

  def update_with_instructions(params)
    params[:instructions] = flattened_instructions(params)
    update!(params)
  end

  def flattened_instructions(params)
    instructions + " - " + params.dig(:instructions).presence
  end

  def decision_issue_ids_match_appeal_decision_issues
    unless (source_appeal.decision_issues.map(&:id) - decision_issue_ids).empty?
      fail Caseflow::Error::JmrAppealDecisionIssueMismatch, message: "JMR remands must address all decision issues"
    end
  end

  def cavc_remand_form_complete?
    valid? && (mandate_not_required? || (!mandate_date.nil? && !judgement_date.nil?))
  end

  def already_has_mandate?
    !!mandate_date
  end

  def mandate_not_required?
    straight_reversal? || death_dismissal? || (remand? && mdr?)
  end

  def establish_appeal_stream
    self.remand_appeal ||= source_appeal.create_stream(:court_remand).tap do |cavc_appeal|
      update_request_issues(cavc_appeal, add_ids: decision_issue_ids)

      person = source_appeal.claimant.person
      fail "Claimants on appeals are expected to be the same" unless person == cavc_appeal.claimant.person

      AdvanceOnDocketMotion.copy_granted_motions_to_appeal(source_appeal, cavc_appeal)
    end
  end

  def update_request_issues(cavc_appeal = remand_appeal, add_ids: [], remove_ids: [])
    DecisionIssue.find(add_ids).map do |cavc_remanded_issue|
      cavc_remanded_issue.create_contesting_request_issue!(cavc_appeal)
    end
    DecisionIssue.find(remove_ids).map do |cavc_remanded_issue|
      req_issues = remand_appeal.request_issues.where(contested_decision_issue_id: cavc_remanded_issue.id)
      req_issues.delete_all
    end
  end

  def initialize_tasks
    InitialTasksFactory.new(remand_appeal).create_root_and_sub_tasks!
  end

  def end_mandate_hold
    if remand? && mdr?
      SendCavcRemandProcessedLetterTask.create!(appeal: remand_appeal, parent: cavc_task)
      MdrTask.find_by(appeal_id: remand_appeal_id).descendants.each(&:completed!)
    elsif straight_reversal? || death_dismissal?
      CavcTask.find_by(appeal_id: remand_appeal_id).descendants.each(&:completed!)
    end
  end

  # we want to be generous to whatever the user types, but normalize to a dash
  def normalize_cavc_docket_number
    cavc_docket_number.sub!(/[‐−–—]/, "-")
  end

  def cavc_task
    CavcTask.open.find_by(appeal_id: remand_appeal_id)
  end
  # :nocov:
end
