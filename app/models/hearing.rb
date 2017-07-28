class Hearing < ActiveRecord::Base
  belongs_to :appeal
  belongs_to :user

  attr_accessor :date, :type, :venue_key, :vacols_record, :disposition,
                :aod, :hold_open, :transcript_requested, :notes

  belongs_to :appeal
  belongs_to :user # the judge
  has_many :issues, foreign_key: :appeal_id, primary_key: :appeal_id
  accepts_nested_attributes_for :issues

  def venue
    self.class.venues[venue_key]
  end

  def closed?
    !!disposition
  end

  def scheduled_pending?
    date && !closed?
  end

  def update(hearing_hash)
    transaction do
      self.class.repository.update_vacols_hearing!(vacols_id, hearing_hash)
      super
    end
  end

  def request_type
    type != :central_office ? type.to_s.capitalize : "CO"
  end

  delegate \
    :representative_name, \
    :appellant_last_first_mi, \
    :regional_office_name, \
    :vbms_id, \
    to: :appeal

  def to_hash
    serializable_hash(
      methods: [
        :date,
        :request_type,
        :disposition,
        :aod,
        :transcript_requested,
        :hold_open,
        :notes,
        :appellant_last_first_mi,
        :representative_name,
        :venue, :vbms_id
      ]
    )
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
          date: AppealRepository.normalize_vacols_date(vacols_hearing.hearing_date),
          appeal: Appeal.find_or_create_by(vacols_id: vacols_hearing.folder_nr),
          user: User.find_by_vacols_id(vacols_hearing.user_id),
          aod: VACOLS::CaseHearing::HEARING_AODS[vacols_hearing.aod.try(:to_sym)],
          hold_open: vacols_hearing.holddays,
          transcript_requested: VACOLS::CaseHearing::BOOLEAN_MAP[vacols_hearing.tranreq.try(:to_sym)],
          notes: vacols_hearing.notes1,
          type: VACOLS::CaseHearing::HEARING_TYPES[vacols_hearing.hearing_type.to_sym]
        }
      end
    end

    def repository
      @repository ||= HearingRepository
    end
  end
end
