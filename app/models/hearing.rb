class Hearing < ActiveRecord::Base
  belongs_to :appeal
  belongs_to :user

  attr_accessor :date, :type, :venue_key, :vacols_record

  def attributes
    {
      date: date,
      type: type,
      venue: venue
    }
  end

  def venue
    self.class.venues[venue_key]
  end

  class << self
    attr_writer :repository

    def venues
      VACOLS::RegionalOffice::CITIES.merge(VACOLS::RegionalOffice::SATELLITE_OFFICES)
    end

    def load_from_vacols(vacols_hearing, vacols_user_id)
      find_or_create_by(vacols_id: vacols_hearing.hearing_pkseq).tap do |hearing|
        hearing.attributes = {
          vacols_record: vacols_hearing,
          venue_key: vacols_hearing.hearing_venue,
          date: AppealRepository.normalize_vacols_date(vacols_hearing.hearing_date),
          appeal: Appeal.find_or_create_by(vacols_id: vacols_hearing.folder_nr),
          user: User.find_by_vacols_id(vacols_user_id),
          type: VACOLS::CaseHearing::HEARING_TYPES[vacols_hearing.hearing_type.to_sym]
        }
      end
    end

    def repository
      @repository ||= HearingRepository
    end
  end
end
