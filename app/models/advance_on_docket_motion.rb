# frozen_string_literal: true

class AdvanceOnDocketMotion < CaseflowRecord
  belongs_to :person
  belongs_to :user

  enum status: {
    granted: "granted",
    denied: "denied"
  }
  enum reason: {
    financial_distress: "financial_distress",
    age: "age",
    serious_illness: "serious_illness",
    other: "other"
  }

  class << self
    def granted_for_person?(person_id, appeal_receipt_date)
      eligable_motions(person_id, appeal_receipt_date).where(granted: true).any?
    end

    def eligable_motions(person_id, appeal_receipt_date)
      where(created_at: appeal_receipt_date..DateTime::Infinity.new, person_id: person_id)
    end

    def create_or_update_by_appeal(appeal, attrs)
      person_id = appeal.claimant.person.id
      motion = eligable_motions(person_id, appeal.receipt_date).first || create(person_id: person_id)

      motion.update(attrs)
    end
  end
end
