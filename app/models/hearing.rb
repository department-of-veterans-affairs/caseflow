class Hearing < ActiveRecord::Base
  include AssociatedVacolsModel
  belongs_to :appeal
  belongs_to :user

  vacols_attr_accessor :date, :type, :venue_key, :vacols_record, :disposition,
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

  def active_appeal_streams
    self.class.repository.appeals_ready_for_hearing(appeal.vbms_id)
  end

  def update(hearing_hash)
    transaction do
      self.class.repository.update_vacols_hearing!(vacols_record, hearing_hash)
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
      include: :issues,
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

  def set_issues_from_appeal
    return unless appeal
    appeal.issues.each do |issue|
      Issue.find_or_create_by(appeal: appeal, vacols_sequence_id: issue.vacols_sequence_id)
    end
  end

  class << self
    attr_writer :repository

    def venues
      VACOLS::RegionalOffice::CITIES.merge(VACOLS::RegionalOffice::SATELLITE_OFFICES)
    end

    def repository
      @repository ||= HearingRepository
    end

    def create_from_vacols_record(vacols_record)
      Hearing.transaction do
        find_or_create_by(vacols_id: vacols_record.hearing_pkseq).tap do |hearing|
          hearing.update(appeal: Appeal.find_or_create_by(vacols_id: vacols_record.folder_nr),
                         user: User.find_by(css_id: vacols_record.css_id))
          hearing.set_issues_from_appeal
          hearing
        end
      end
    end
  end
end
