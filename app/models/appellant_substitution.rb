# frozen_string_literal: true

# Model to store Appellant Substitution information captured from the Granted Substitution creation process

class AppellantSubstitution < CaseflowRecord
  belongs_to :created_by, class_name: "User", optional: false
  belongs_to :source_appeal, class_name: "Appeal", optional: false
  belongs_to :target_appeal, class_name: "Appeal"

  validates :created_by, :source_appeal, :substitution_date,
            :claimant_type, # Claimant record type for the substitute
            :substitute_participant_id,
            presence: true
  validates :selected_task_ids,
            :task_params,
            presence: true, allow_blank: true

  before_create :establish_appeal_stream
  after_create :initialize_tasks

  def substitute_claimant
    target_appeal.claimant
  end

  def substitute_person
    Person.find_by(participant_id: substitute_participant_id)
  end

  def power_of_attorney
    poa_participant_id ? BgsPowerOfAttorney.find_by(poa_participant_id: poa_participant_id) : nil
  end

  private

  def establish_appeal_stream
    unassociated_claimant = Claimant.create!(
      participant_id: substitute_participant_id,
      payee_code: nil,
      type: claimant_type
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
    InitialTasksFactory.new(target_appeal).create_root_and_sub_tasks!
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
        request_issue_copy.decision_review = target_appeal
        # Do not copy decisions for new appeal
        request_issue_copy.decision_date = nil
        request_issue_copy.save!
      end
    end
  end
end
