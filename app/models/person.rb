class Person < ApplicationRecord
  has_many :advance_on_docket_grants
  validates :participant_id, presence: true

  # If we do not yet have the date of birth saved in Caseflow's DB, then
  # we want to fetch it from BGS, save it to the DB, then return it
  def date_of_birth
    super || begin
      update_attributes(date_of_birth: BGSService.new.fetch_person_info(participant_id)[:birth_date]) if persisted?
      super
    end
  end
end