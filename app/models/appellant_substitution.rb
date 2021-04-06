# frozen_string_literal: true

# Model to store Appellant Substitution information captured from the Granted Substitution creation process

class AppellantSubstitution < CaseflowRecord
  belongs_to :created_by, class_name: "User"
  belongs_to :source_appeal, class_name: "Appeal"
  belongs_to :target_appeal, class_name: "Appeal"

  validates :created_by, :source_appeal, :substitution_date,
            :substitute_participant_id, :poa_participant_id,
            presence: true

  before_save :establish_appeal_stream

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
    self.target_appeal ||= source_appeal.create_stream(:granted_substitution).tap do |target_appeal|
      AdvanceOnDocketMotion.copy_granted_motions_to_appeal(source_appeal, target_appeal)
      InitialTasksFactory.new(target_appeal).create_root_and_sub_tasks!
    end
  end
end
