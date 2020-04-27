# frozen_string_literal: true

class AdvanceOnDocketMotion < CaseflowRecord
  belongs_to :person
  belongs_to :user

  enum reason: {
    Constants.AOD_REASONS.financial_distress.to_sym => Constants.AOD_REASONS.financial_distress,
    Constants.AOD_REASONS.age.to_sym => Constants.AOD_REASONS.age,
    Constants.AOD_REASONS.serious_illness.to_sym => Constants.AOD_REASONS.serious_illness,
    Constants.AOD_REASONS.other.to_sym => Constants.AOD_REASONS.other
  }

  scope :granted, -> { where(granted: true) }
  scope :eligable_due_to_age, -> { age }
  scope :eligable_due_to_date, lambda { |receipt_date|
    where(created_at: receipt_date..DateTime::Infinity.new).where.not(id: age)
  }
  scope :for_person, ->(person_id) { where(person_id: person_id) }

  class << self
    def granted_for_person?(person_id, appeal_receipt_date)
      eligable_motions(person_id, appeal_receipt_date).granted.any?
    end

    def eligable_motions(person_id, appeal_receipt_date)
      eligable_due_to_date(appeal_receipt_date).or(eligable_due_to_age).for_person(person_id)
    end

    def create_or_update_by_appeal(appeal, attrs)
      person_id = appeal.claimant.person.id
      motion = eligable_due_to_date(appeal.receipt_date).for_person(person_id).first || create(person_id: person_id)

      motion.update(attrs)
    end
  end
end
