class Hearing < ActiveRecord::Base
  include CachedAttributes
  include AssociatedVacolsModel
  include RegionalOfficeConcern

  belongs_to :appeal
  belongs_to :user

  vacols_attr_accessor :date, :type, :venue_key, :vacols_record, :disposition,
                       :aod, :hold_open, :transcript_requested, :notes, :add_on,
                       :representative_name, :regional_office_key, :master_record

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

  cache_attribute :cached_number_of_documents do
    number_of_documents
  end

  cache_attribute :cached_number_of_documents_after_certification do
    number_of_documents_after_certification
  end

  delegate \
    :veteran_age, \
    :veteran_name, \
    :appellant_last_first_mi, \
    :appellant_city, \
    :appellant_state, \
    :vbms_id, \
    :number_of_documents, \
    :number_of_documents_after_certification, \
    :representative, \
    to: :appeal, allow_nil: true

  # rubocop:disable Metrics/MethodLength
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
        :add_on,
        :master_record,
        :appellant_last_first_mi,
        :appellant_city,
        :appellant_state,
        :representative_name,
        :veteran_age,
        :veteran_name,
        :venue,
        :cached_number_of_documents,
        :cached_number_of_documents_after_certification,
        :vbms_id
      ]
    )
  end
  # rubocop:enable Metrics/MethodLength

  def to_hash_for_worksheet
    serializable_hash(
      methods: [:appeal_id,
                :regional_office_name,
                :representative,
                :appeals_ready_for_hearing],
      include: :issues
    ).merge(to_hash)
  end

  def set_issues_from_appeal
    appeal.issues.each do |issue|
      Issue.find_or_create_by(appeal: appeal, vacols_sequence_id: issue.vacols_sequence_id)
    end if appeal
  end

  def appeals_ready_for_hearing
    active_appeal_streams.map(&:attributes_for_hearing)
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
      transaction do
        find_or_initialize_by(vacols_id: vacols_record.hearing_pkseq).tap do |hearing|
          # If it is a master record, do not create a record in the hearings table
          return hearing if vacols_record.master_record?

          hearing.update(appeal: Appeal.find_or_create_by(vacols_id: vacols_record.folder_nr),
                         user: User.find_by(css_id: vacols_record.css_id))
          hearing.set_issues_from_appeal
        end
      end
    end
  end
end
