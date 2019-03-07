# frozen_string_literal: true

class Person < ApplicationRecord
  has_many :advance_on_docket_motions
  has_many :claimants, primary_key: :participant_id, foreign_key: :participant_id
  validates :participant_id, presence: true

  def advanced_on_docket(appeal_receipt_date)
    advanced_on_docket_based_on_age || advanced_on_docket_motion_granted(appeal_receipt_date)
  end

  # If we do not yet have the date of birth saved in Caseflow's DB, then
  # we want to fetch it from BGS, save it to the DB, then return it
  def date_of_birth
    super || begin
      update(date_of_birth: BGSService.new.fetch_person_info(participant_id)[:birth_date]) if persisted?
      super
    end
  end

  private

  def advanced_on_docket_based_on_age
    date_of_birth && date_of_birth < 75.years.ago
  end

  def advanced_on_docket_motion_granted(appeal_receipt_date)
    advance_on_docket_motions.any? do |advance_on_docket_motion|
      advance_on_docket_motion.granted && appeal_receipt_date < advance_on_docket_motion.created_at
    end
  end
end
