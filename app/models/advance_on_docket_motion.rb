# frozen_string_literal: true

class AdvanceOnDocketMotion < CaseflowRecord
  belongs_to :person
  belongs_to :user
  belongs_to :appeal, polymorphic: true

  validates :appeal, presence: true

  enum reason: {
    Constants.AOD_REASONS.financial_distress.to_sym => Constants.AOD_REASONS.financial_distress,
    Constants.AOD_REASONS.age.to_sym => Constants.AOD_REASONS.age,
    Constants.AOD_REASONS.serious_illness.to_sym => Constants.AOD_REASONS.serious_illness,
    Constants.AOD_REASONS.other.to_sym => Constants.AOD_REASONS.other
  }

  scope :granted, -> { where(granted: true) }
  scope :eligible_due_to_age, -> { age }
  scope :eligible_due_to_appeal, ->(appeal) { where(appeal: appeal).where.not(id: age) }
  scope :for_person, ->(person_id) { where(person_id: person_id) }

  class << self
    def granted_for_person?(person_id, appeal)
      eligible_motions(person_id, appeal).granted.any?
    end

    def eligible_motions(person_id, appeal)
      eligible_due_to_appeal(appeal)
        .or(eligible_due_to_age)
        .for_person(person_id)
    end

    def create_or_update_by_appeal(appeal, attrs)
      person_id = appeal.claimant.person.id
      motion = eligible_due_to_appeal(appeal).for_person(person_id).first ||
               create(person_id: person_id, appeal: appeal)

      motion.update(attrs)
    end
  end
end
