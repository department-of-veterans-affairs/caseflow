# frozen_string_literal: true

# Model to store Appellant Substitution information captured from the Granted Substitution creation process

class AppellantSubstitution < CaseflowRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :source_appeal, class_name: "Appeal"
  belongs_to :target_appeal, class_name: "Appeal"

  validates :created_by, :source_appeal, :substitution_date,
            :claimant_type, # Claimant record type for the substitute
            :substitute_participant_id,
            :poa_participant_id,
            presence: true

  before_save :establish_appeal_stream

  attr_accessor :claimant_type

  def substitute_claimant
    Claimant.find_by(participant_id: substitute_participant_id)
  end

  def substitute_person
    Person.find_by(participant_id: substitute_participant_id)
  end

  def power_of_attorney
    BgsPowerOfAttorney.find_by(poa_participant_id: poa_participant_id)
  end

  private

  def establish_appeal_stream
    Claimant.create_without_intake!(participant_id: substitute_participant_id, payee_code: nil, type: claimant_type)
    unassociated_claimants = Claimant.where(participant_id: substitute_participant_id, decision_review: nil)
    self.target_appeal ||= source_appeal.create_stream(:substitution, new_claimants: unassociated_claimants)
      .tap do |target_appeal|
        copy_request_issues(source_appeal, target_appeal)

        # AOD Status: If the deceased appellant’s appeal was AOD, the substitute appellant will also receive
        # the benefit of the AOD status. This is the case for both situations where a case is returned to
        # the Board following the grant of a substitution request  AND/OR pursuant to an appeal of a denial
        # of a substitution request. See 38 C.F.R. § 20.800(f).
        subtitute_person = target_appeal.claimant.person
        AdvanceOnDocketMotion.transfer_granted_motions_to_person(source_appeal, target_appeal, subtitute_person)

        InitialTasksFactory.new(target_appeal).create_root_and_sub_tasks!
      end
  end

  def copy_request_issues(source_appeal, target_appeal)
    source_appeal.request_issues.order(:id).map do |request_issue|
      request_issue.dup.tap do |request_issue_copy|
        request_issue_copy.decision_review = target_appeal
        request_issue_copy.save!
      end
    end
  end
end
