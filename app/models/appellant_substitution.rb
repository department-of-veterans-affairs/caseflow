# frozen_string_literal: true

# Model to store Appellant Substitution information captured from the Granted Substitution creation process

class AppellantSubstitution < CaseflowRecord
  belongs_to :created_by, class_name: "User", optional: false
  belongs_to :source_appeal, class_name: "Appeal", optional: false
  belongs_to :target_appeal, class_name: "Appeal"

  has_many :histories, class_name: "AppellantSubstitutionHistory"

  scope :updated_since_for_appeals, lambda { |since|
    select(:target_appeal_id).where("#{table_name}.updated_at >= ?", since)
  }

  validates :created_by, :source_appeal, :substitution_date,
            :claimant_type, # Claimant record type for the substitute
            :substitute_participant_id,
            presence: true
  validates :selected_task_ids,
            :task_params,
            presence: true, allow_blank: true

  attr_accessor :cancelled_task_ids, :cavc_remand_appeal_substitution, :skip_cancel_tasks

  before_create :establish_substitution_on_same_appeal, if: :same_appeal_substitution_allowed?
  before_create :establish_separate_appeal_stream, unless: :same_appeal_substitution_allowed?
  before_create :establish_sustitution_on_cavc_remand_appeal, if: :cavc_remand_appeal_substitution
  before_update :establish_substitution_on_same_appeal_on_update, if: :cavc_remand_appeal_substitution
  after_commit :initialize_tasks
  after_commit :initialize_tasks, unless: :same_appeal_substitution_allowed?
  after_commit :create_substitute_tasks, if: :can_create_substitute_tasks?

  def substitute_claimant
    target_appeal.claimant
  end

  def substitute_person
    Person.find_by(participant_id: substitute_participant_id)
  end

  def power_of_attorney
    poa_participant_id ? BgsPowerOfAttorney.find_by(poa_participant_id: poa_participant_id) : nil
  end

  def same_appeal_substitution_allowed?
    (ClerkOfTheBoard.singleton.user_is_admin?(created_by) || !!source_appeal.veteran.date_of_death) &&
      source_appeal.request_issues.none?(&:death_dismissed?)
  end

  private

  def establish_substitution_on_same_appeal
    return if cavc_remand_appeal_substitution

    # Need to update source appeal veteran_is_not_claimant before creating the substitute claimant.
    # This ensures that substitute claimant is the correct type.
    source_appeal.update!(veteran_is_not_claimant: true)
    Claimant.create!(
      participant_id: substitute_participant_id,
      payee_code: nil,
      type: claimant_type,
      decision_review_id: source_appeal.id,
      decision_review_type: "Appeal"
    )
    self.target_appeal = source_appeal.reload
  end

  def establish_sustitution_on_cavc_remand_appeal
    target_appeal.update!(veteran_is_not_claimant: true)

    Claimant.create!(
      participant_id: substitute_participant_id,
      payee_code: nil,
      type: claimant_type,
      decision_review_id: target_appeal.id,
      decision_review_type: "Appeal"
    )
  end

  def establish_substitution_on_same_appeal_on_update
    target_appeal.claimant&.update(participant_id: substitute_participant_id)
  end

  def establish_separate_appeal_stream
    return if cavc_remand_appeal_substitution

    unassociated_claimant = Claimant.create!(
      participant_id: substitute_participant_id,
      payee_code: nil,
      type: claimant_type,
      # Setting the values here to 0 and '' because of the non-null constraint in the schema for claimant records.
      # This will be corrected when `create_stream` is called.
      decision_review_id: 0,
      decision_review_type: ""
    )

    # To-do: Implement this and the DB schema once we understand the requirements for selecting a
    # POA for unknown appellants.
    # find_or_create_power_of_attorney_for(unassociated_claimant)

    self.target_appeal ||= source_appeal.create_stream(source_appeal.stream_type,
                                                       new_claimants: [unassociated_claimant])
      .tap do |target_appeal|
        copy_request_issues(source_appeal, target_appeal)

        # AOD Status: If the deceased appellant’s appeal was AOD, the substitute appellant will also receive
        # the benefit of the AOD status. This is the case for both situations where a case is returned to
        # the Board following the grant of a substitution request  AND/OR pursuant to an appeal of a denial
        # of a substitution request. See 38 C.F.R. § 20.800(f).
        substitute_person = target_appeal.claimant.person
        AdvanceOnDocketMotion.transfer_granted_motions_to_person(source_appeal, target_appeal, substitute_person)
      end
  end

  def initialize_tasks
    InitialTasksFactory.new(target_appeal).create_root_and_sub_tasks! unless cavc_remand_appeal_substitution
  end

  def create_substitute_tasks
    task_ids = {}
    task_ids[:selected] = selected_task_ids
    task_ids[:cancelled] = cancelled_task_ids
    SameAppealSubstitutionTasksFactory.new(target_appeal,
                                           task_ids,
                                           created_by,
                                           task_params,
                                           skip_cancel_tasks).create_substitute_tasks!
  end

  def find_or_create_power_of_attorney_for(unassociated_claimant)
    return power_of_attorney if unassociated_claimant.power_of_attorney&.poa_participant_id == poa_participant_id

    # To-do: fail "Not yet implemented: create BgsPowerOfAttorney for unknown substitute"
  end

  def copy_request_issues(source_appeal, target_appeal)
    source_appeal.request_issues.order(:id).map do |request_issue|
      # This block of code may be a source of bugs as new columns are added to request_issues.
      # It may be better to copy specific attributes, than duplicate everything.
      request_issue.dup.tap do |request_issue_copy|
        # Death-dismissed issues should be reopened
        if request_issue.death_dismissed?
          request_issue_copy.closed_status = nil
          request_issue_copy.closed_at = nil
        end
        request_issue_copy.decision_review = target_appeal
        request_issue_copy.save!
      end
    end
  end

  def can_create_substitute_tasks?
    same_appeal_substitution_allowed? || cavc_remand_appeal_substitution
  end
end
