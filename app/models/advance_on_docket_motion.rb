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
  # 'age' below filters to reason: age due to scope+enum Rails magic
  scope :eligible_due_to_age, -> { age }
  scope :for_appeal, ->(appeal) { where(appeal: appeal) }
  # not(id: age) means to exclude AOD motions with reason="age" provided by the `age` enum
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

      existing_motions = AdvanceOnDocketMotion.for_appeal(appeal).for_person(person_id).order(:id)

      motion = for_appeal(appeal).for_person(person_id).where(reason: attrs[:reason]).order(:id).last
      if motion
        motion.update(attrs)
      elsif age_related_motion?(attrs[:reason])
        # There is only one age-related reason, so if the above didn't find it, there are none.
        create(person_id: person_id, appeal: appeal).update(attrs)
      else
        # However, there are multiple non-age-related reasons, and can only be one.
        if existing_motions.any? { |m| non_age_related_motion?(m[:reason])}
          # This would be a duplicate, so update the latest one with our parameters:
          motion = existing_motions.select { |m| non_age_related_motion?(m[:reason]) }.last
          motion.update(attrs)
        else
          create(person_id: person_id, appeal: appeal).update(attrs)
        end
      end
    end

    def age_related_motion?(reason)
      reason == Constants.AOD_REASONS.age
    end

    def non_age_related_motion?(reason)
      [
          Constants.AOD_REASONS.financial_distress,
          Constants.AOD_REASONS.serious_illness,
          Constants.AOD_REASONS.other
      ].include?(reason)
    end
  end
end
