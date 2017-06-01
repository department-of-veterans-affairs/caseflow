class Hearing < ActiveRecord::Base
  belongs_to :appeal
  belongs_to :user

  attr_accessor :date, :type, :venue_key, :vacols_record, :closed_at, :disposition

  belongs_to :appeal
  belongs_to :user # the judge
  has_many :issues, foreign_key: :appeal_id, primary_key: :appeal_id
  accepts_nested_attributes_for :issues

  def venue
    self.class.venues[venue_key]
  end

  def closed?
    !!closed_at
  end

  def scheduled_pending?
    date && !closed?
  end

  class << self
    attr_writer :repository

    def venues
      VACOLS::RegionalOffice::CITIES.merge(VACOLS::RegionalOffice::SATELLITE_OFFICES)
    end

    def load_from_vacols(vacols_hearing)
      find_or_create_by(vacols_id: vacols_hearing.hearing_pkseq).tap do |hearing|
        hearing.attributes = {
          vacols_record: vacols_hearing,
          venue_key: vacols_hearing.hearing_venue,
          disposition: VACOLS::CaseHearing::HEARING_DISPOSITIONS[vacols_hearing.hearing_disp.try(:to_sym)],
          closed_at: AppealRepository.normalize_vacols_date(vacols_hearing.clsdate),
          date: AppealRepository.normalize_vacols_date(vacols_hearing.hearing_date),
          appeal: Appeal.find_or_create_by(vacols_id: vacols_hearing.folder_nr),
          user: User.find_by_vacols_id(vacols_hearing.user_id),
          type: VACOLS::CaseHearing::HEARING_TYPES[vacols_hearing.hearing_type.to_sym]
        }
      end
    end

    def repository
      @repository ||= HearingRepository
    end
  end
end
