class Hearing < ActiveRecord::Base
  include CachedAttributes
  include AssociatedVacolsModel
  include HearingConcern
  include AppealConcern

  vacols_attr_accessor :veteran_first_name, :veteran_middle_initial, :veteran_last_name
  vacols_attr_accessor :appellant_first_name, :appellant_middle_initial, :appellant_last_name
  vacols_attr_accessor :date, :type, :venue_key, :vacols_record, :disposition
  vacols_attr_accessor :aod, :hold_open, :transcript_requested, :notes, :add_on
  vacols_attr_accessor :representative_name, :representative
  vacols_attr_accessor :regional_office_key, :master_record

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

  # rubocop:disable Metrics/MethodLength
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
      master_record: master_record,
      veteran_first_name: veteran_first_name,
      veteran_middle_initial: veteran_middle_initial,
      veteran_last_name: veteran_last_name,
      appellant_first_name: appellant_first_name,
      appellant_middle_initial: appellant_middle_initial,
      appellant_last_name: appellant_last_name
    }
  end

  cache_attribute :cached_number_of_documents do
    number_of_documents
  end

  delegate \
    :veteran_age, \
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
        :transcript_requested,
        :hold_open, :notes,
        :add_on, :master_record,
        :representative,
        :representative_name,
        :regional_office_name,
        :venue, :appellant_last_first_mi,
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
                :appellant_city,
                :appellant_state,
                :military_service,
                :appellant_mi_formatted,
                :veteran_mi_formatted]
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
      RegionalOffice::CITIES.merge(RegionalOffice::SATELLITE_OFFICES)
    end

    def repository
      @repository ||= HearingRepository
    end

    def create_from_vacols_record(vacols_record)
      transaction do
        find_or_initialize_by(vacols_id: vacols_record.hearing_pkseq).tap do |hearing|
          hearing.update(
            appeal: Appeal.find_or_create_by(vacols_id: vacols_record.folder_nr),
            user: User.find_by(css_id: vacols_record.css_id)
          ) if hearing.new_record?
        end
      end
    end
  end
end
