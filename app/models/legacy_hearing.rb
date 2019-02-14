class LegacyHearing < ApplicationRecord
  include CachedAttributes
  include AssociatedVacolsModel
  include AppealConcern

  vacols_attr_accessor :veteran_first_name, :veteran_middle_initial, :veteran_last_name
  vacols_attr_accessor :appellant_first_name, :appellant_middle_initial, :appellant_last_name
  vacols_attr_accessor :scheduled_for, :request_type, :venue_key, :vacols_record, :disposition
  vacols_attr_accessor :aod, :hold_open, :transcript_requested, :notes, :add_on
  vacols_attr_accessor :transcript_sent_date, :appeal_vacols_id
  vacols_attr_accessor :representative_name, :representative, :hearing_day_id
  vacols_attr_accessor :regional_office_key, :master_record
  vacols_attr_accessor :docket_number, :appeal_type, :appellant_address_line_1
  vacols_attr_accessor :appellant_address_line_2, :appellant_city, :appellant_state
  vacols_attr_accessor :appellant_zip, :appellant_country, :room, :bva_poc, :judge_id

  belongs_to :appeal, class_name: "LegacyAppeal"
  belongs_to :user # the judge
  has_many :hearing_views, as: :hearing
  has_many :appeal_stream_snapshots, foreign_key: :hearing_id
  has_one :hearing_location, as: :hearing
  has_one :hearing_task_association, as: :hearing

  alias_attribute :location, :hearing_location
  accepts_nested_attributes_for :hearing_location

  # this is used to cache appeal stream for hearings
  # when fetched intially.
  has_many :appeals, class_name: "LegacyAppeal", through: :appeal_stream_snapshots

  CO_HEARING = "Central".freeze
  VIDEO_HEARING = "Video".freeze

  def judge
    user
  end

  def venue
    self.class.venues[venue_key]
  end

  def external_id
    vacols_id
  end

  def request_type_location
    if request_type == HearingDay::REQUEST_TYPES[:central]
      "Board of Veterans' Appeals in Washington, DC"
    else
      venue[:label]
    end
  end

  def closed?
    !!disposition
  end

  def no_show?
    disposition == :no_show
  end

  def held?
    disposition == :held
  end

  def scheduled_pending?
    scheduled_for && !closed?
  end

  def held_open?
    hold_open && hold_open > 0
  end

  def hold_release_date
    return unless held_open?

    scheduled_for.to_date + hold_open.days
  end

  def no_show_excuse_letter_due_date
    scheduled_for.to_date + 15.days
  end

  def active_appeal_streams
    return appeals if appeals.any?

    appeals << self.class.repository.appeals_ready_for_hearing(appeal.vbms_id)
  end

  def update_caseflow_and_vacols(hearing_hash)
    ActiveRecord::Base.multi_transaction do
      self.class.repository.update_vacols_hearing!(vacols_record, hearing_hash)
      update!(hearing_hash)
    end
  end

  def regional_office_timezone
    HearingMapper.timezone(regional_office_key)
  end

  def readable_location
    if request_type == LegacyHearing::CO_HEARING
      return "Washington DC"
    end

    regional_office_name
  end

  def readable_request_type
    Hearing::HEARING_TYPES[request_type.to_sym]
  end

  # rubocop:disable Metrics/MethodLength
  def vacols_attributes
    {
      scheduled_for: scheduled_for,
      type: type,
      venue_key: venue_key,
      vacols_record: vacols_record,
      disposition: disposition,
      aod: aod,
      hold_open: hold_open,
      transcript_requested: transcript_requested,
      transcript_sent_date: transcript_sent_date,
      notes: notes,
      add_on: add_on,
      representative: representative,
      representative_name: representative_name,
      vdkey: vdkey,
      regional_office_key: regional_office_key,
      master_record: master_record,
      veteran_first_name: veteran_first_name,
      veteran_middle_initial: veteran_middle_initial,
      veteran_last_name: veteran_last_name,
      appellant_first_name: appellant_first_name,
      appellant_middle_initial: appellant_middle_initial,
      appellant_last_name: appellant_last_name,
      appeal_vacols_id: appeal_vacols_id
    }
  end

  cache_attribute :cached_number_of_documents do
    begin
      number_of_documents
    rescue Caseflow::Error::EfolderError, VBMS::HTTPError
      nil
    end
  end

  delegate \
    :veteran_age, \
    :veteran_gender, \
    :vbms_id, \
    :number_of_documents, \
    :number_of_documents_after_certification, \
    :veteran,  \
    :veteran_file_number, \
    :docket_name,
    :veteran_closest_regional_office,
    :veteran_available_hearing_locations,
    to: :appeal, allow_nil: true

  delegate :external_id, to: :appeal, prefix: true

  def to_hash(current_user_id)
    serializable_hash(
      methods: [
        :scheduled_for,
        :readable_request_type,
        :disposition,
        :aod,
        :transcript_requested,
        :hold_open,
        :notes,
        :add_on,
        :master_record,
        :representative,
        :representative_name,
        :regional_office_key,
        :hearing_day_id,
        :regional_office_name,
        :regional_office_timezone,
        :venue,
        :veteran_first_name,
        :veteran_last_name,
        :appellant_first_name,
        :appellant_last_name,
        :vbms_id,
        :current_issue_count,
        :prepped,
        :docket_number,
        :docket_name,
        :appeal_type,
        :appellant_address_line_1,
        :appellant_city,
        :appellant_state,
        :appellant_zip,
        :location,
        :readable_location,
        :appeal_external_id,
        :external_id,
        :veteran_file_number,
        :veteran_closest_regional_office,
        :veteran_available_hearing_locations
      ],
      except: [:military_service, :vacols_id]
    ).merge(
      viewed_by_current_user: hearing_views.all.any? do |hearing_view|
        hearing_view.user_id == current_user_id
      end
    )
  end

  def fetch_veteran_age
    veteran_age
  rescue Module::DelegationError
    nil
  end

  def fetch_veteran_gender
    veteran_gender
  rescue Module::DelegationError
    nil
  end

  def to_hash_for_worksheet(current_user_id)
    serializable_hash(
      methods: [:appeal_id,
                :judge,
                :summary,
                :appeals_ready_for_hearing,
                :cached_number_of_documents,
                :military_service]
    ).merge(
      to_hash(current_user_id)
    ).merge(
      veteran_gender: fetch_veteran_gender,
      veteran_age: fetch_veteran_age
    )
  end

  def slot_new_hearing(parent_record_id, scheduled_time:, appeal:, hearing_location_attrs: nil)
    HearingRepository.slot_new_hearing(parent_record_id,
                                       scheduled_time: scheduled_time,
                                       hearing_location_attrs: hearing_location_attrs,
                                       appeal: appeal)
  end

  def appeals_ready_for_hearing
    active_appeal_streams.map(&:attributes_for_hearing)
  end

  def current_issue_count
    active_appeal_streams.map(&:worksheet_issues).flatten
      .reject do |issue|
      issue.deleted? || (issue.disposition && issue.disposition =~ /Remand/ && issue.from_vacols?)
    end
      .count
  end

  # If we do not yet have the military_service saved in Caseflow's DB, then
  # we want to fetch it from BGS, save it to the DB, then return it
  def military_service
    super || begin
      update(military_service: veteran.periods_of_service.join("\n")) if persisted? && veteran
      super
    end
  end

  class << self
    def venues
      RegionalOffice::CITIES.merge(RegionalOffice::SATELLITE_OFFICES)
    end

    def repository
      HearingRepository
    end

    def user_nil_or_assigned_to_another_judge?(user, vacols_css_id)
      user.nil? || (user.css_id != vacols_css_id)
    end

    def assign_or_create_from_vacols_record(vacols_record, legacy_hearing: nil)
      transaction do
        hearing = legacy_hearing ||
                  find_or_initialize_by(vacols_id: vacols_record.hearing_pkseq)

        # update hearing if user is nil, it's likely when the record doesn't exist and is being created
        # or if vacols record css is different from
        # who it's assigned to in the db.
        if user_nil_or_assigned_to_another_judge?(hearing.user, vacols_record.css_id)
          hearing.update(
            appeal: LegacyAppeal.find_or_create_by(vacols_id: vacols_record.folder_nr),
            user: User.find_by(css_id: vacols_record.css_id)
          )
        end

        hearing
      end
    end
  end
end
# rubocop:enable Metrics/MethodLength
