class Hearing < ActiveRecord::Base
  include CachedAttributes
  include AssociatedVacolsModel
  include RegionalOfficeConcern

  vacols_attr_accessor :date, :type, :venue_key, :vacols_record, :disposition,
                       :aod, :hold_open, :transcript_requested, :notes, :add_on,
                       :representative_name, :regional_office_key, :master_record,
                       :representative

  belongs_to :appeal
  belongs_to :user # the judge

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

  def vacols_attributes
    {
      date: date,
      type: type,
      venue_key: venue_key,
      vacols_record: vacols_record,
      disposition: disposition,
      aod: aod,
      hold_open: hold_open,
      transcript_requested: transcript_requested,
      notes: notes,
      add_on: add_on,
      representative: representative,
      representative_name: representative_name,
      regional_office_key: regional_office_key,
      master_record: master_record
    }
  end

  def request_type
    type != :central_office ? type.to_s.capitalize : "CO"
  end

  cache_attribute :cached_number_of_documents do
    number_of_documents
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
    :veteran,  \
    to: :appeal, allow_nil: true

  def to_hash
    serializable_hash(
      methods: [
        :date, :request_type,
        :disposition, :aod,
        :appellant_last_first_mi, :transcript_requested,
        :hold_open, :notes,
        :add_on, :master_record,
        :representative, :representative_name,
        :regional_office_name, :venue,
        :veteran_name, :vbms_id
      ],
      except: :military_service
    )
  end

  def to_hash_for_worksheet
    serializable_hash(
      methods: [:appeal_id,
                :appeal_vacols_id,
                :appeals_ready_for_hearing,
                :cached_number_of_documents,
                :veteran_age,
                :veteran_name,
                :appellant_last_first_mi,
                :appellant_city,
                :appellant_state,
                :military_service]
    ).merge(to_hash)
  end

  def appeals_ready_for_hearing
    active_appeal_streams.map(&:attributes_for_hearing)
  end

  # If we do not yet have the military_service saved in Caseflow's DB, then
  # we want to fetch it from BGS, save it to the DB, then return it
  def military_service
    super || begin
      update_attributes(military_service: veteran.periods_of_service.join("\n")) if persisted? && veteran
      super
    end
  end

  def appeal_vacols_id
    appeal.try(:vacols_id)
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

          hearing.update(
            appeal: Appeal.find_or_create_by(vacols_id: vacols_record.folder_nr),
            user: User.find_by(css_id: vacols_record.css_id)
          ) if hearing.new_record?
        end
      end
    end
  end
end
