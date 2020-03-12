# frozen_string_literal: true

class LegacyHearing < CaseflowRecord
  include CachedAttributes
  include AssociatedVacolsModel
  include AppealConcern
  include HasHearingTask
  include HasVirtualHearing
  include HearingTimeConcern

  # When these instance variable getters are called, first check if we've
  # fetched the values from VACOLS. If not, first fetch all values and save them
  # This allows us to easily call `hearing.veteran_first_name` and dynamically
  # fetch the data from VACOLS if it does not already exist in memory
  vacols_attr_accessor :veteran_first_name, :veteran_middle_initial, :veteran_last_name
  vacols_attr_accessor :appellant_first_name, :appellant_middle_initial, :appellant_last_name
  vacols_attr_accessor :scheduled_for, :request_type, :venue_key, :vacols_record, :disposition
  vacols_attr_accessor :aod, :hold_open, :transcript_requested, :notes, :add_on
  vacols_attr_accessor :transcript_sent_date, :appeal_vacols_id
  vacols_attr_accessor :representative_name, :hearing_day_vacols_id
  vacols_attr_accessor :docket_number, :appeal_type, :room, :bva_poc, :judge_id

  belongs_to :appeal, class_name: "LegacyAppeal"
  belongs_to :user # the judge
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  has_many :hearing_views, as: :hearing
  has_many :appeal_stream_snapshots, foreign_key: :hearing_id
  has_one :hearing_location, as: :hearing

  alias_attribute :location, :hearing_location
  accepts_nested_attributes_for :hearing_location

  # this is used to cache appeal stream for hearings
  # when fetched intially.
  has_many :appeals, class_name: "LegacyAppeal", through: :appeal_stream_snapshots

  delegate :veteran_age, :veteran_gender, :vbms_id, :number_of_documents, :number_of_documents_after_certification,
           :veteran, :veteran_file_number, :docket_name, :closest_regional_office, :available_hearing_locations,
           :veteran_email_address,
           to: :appeal,
           allow_nil: true

  delegate :external_id,
           to: :appeal,
           prefix: true

  delegate :appellant_address, :appellant_address_line_1, :appellant_address_line_2,
           :appellant_city, :appellant_country, :appellant_state, :appellant_zip,
           to: :appeal,
           allow_nil: true

  delegate :scheduled_time, to: :time

  delegate :timezone, :name, to: :regional_office, prefix: true

  before_create :assign_created_by_user
  before_update :assign_updated_by_user

  CO_HEARING = "Central"
  VIDEO_HEARING = "Video"

  alias aod? aod

  def judge
    user
  end

  def representative
    appeal&.representative_name
  end

  def representative_email_address
    appeal&.representative_email_address
  end

  def assigned_to_vso?(user)
    appeal.tasks.any? do |task|
      task.type == TrackVeteranTask.name &&
        task.assigned_to.is_a?(Representative) &&
        task.assigned_to.user_has_access?(user) &&
        task.open?
    end
  end

  def assigned_to_judge?(user)
    return hearing_day&.judge == user if judge.nil?

    judge == user
  end

  def venue
    self.class.venues[venue_key]
  end

  def external_id
    vacols_id
  end

  def hearing_day_id_refers_to_vacols_row?
    (request_type == HearingDay::REQUEST_TYPES[:central] && scheduled_for.to_date < Date.new(2019, 1, 1)) ||
      (request_type == HearingDay::REQUEST_TYPES[:video] && scheduled_for.to_date < Date.new(2019, 4, 1))
  end

  def hearing_day_id
    if self[:hearing_day_id].nil? && !hearing_day_id_refers_to_vacols_row?
      begin
        update!(hearing_day_id: hearing_day_vacols_id)
      rescue ActiveRecord::InvalidForeignKey
        # Hearing day doesn't exist yet in Caseflow.
        return hearing_day_vacols_id
      end
    end

    # Returns the cached value, or nil if the hearing day id refers to a VACOLS row.
    self[:hearing_day_id]
  end

  def hearing_day
    @hearing_day ||= HearingDay.find_by_id(hearing_day_id)
  end

  def regional_office_key
    if request_type == HearingDay::REQUEST_TYPES[:travel] || hearing_day.nil?
      return (venue_key || appeal&.regional_office_key)
    end

    hearing_day&.regional_office || "C"
  end

  def regional_office
    @regional_office ||= begin
                            RegionalOffice.find!(regional_office_key)
                         rescue RegionalOffice::NotFoundError
                           nil
                          end
  end

  def request_type_location
    if request_type == HearingDay::REQUEST_TYPES[:central]
      "Board of Veterans' Appeals in Washington, DC"
    elsif venue
      venue[:label]
    elsif hearing_location
      hearing_location.name
    end
  end

  def closed?
    !!disposition
  end

  def no_show?
    disposition == Constants.HEARING_DISPOSITION_TYPES.no_show
  end

  def held?
    disposition == Constants.HEARING_DISPOSITION_TYPES.held
  end

  def scheduled_pending?
    scheduled_for && !closed?
  end

  def scheduled_for_past?
    # FIXME: scheduled_for date is inconsistent in many places.
    # (https://github.com/department-of-veterans-affairs/caseflow/issues/13273)
    # scheduled_for should either pulled from VACOLS or from the associated hearing_day,
    # but some method exclusively use the value from VACOLS. The hearing_day association to
    # legacy hearings was added in #11741.
    # (https://github.com/department-of-veterans-affairs/caseflow/pull/11741)
    scheduled_date = if hearing_day_id_refers_to_vacols_row?
                       # Handles conversion of a VACOLS time (EST) to the timezone of the RO
                       time.local_time
                     else
                       # Hearing Day scheduled_for is in the timezone of the RO
                       hearing_day&.scheduled_for || time.local_time
                     end

    scheduled_date < DateTime.yesterday.in_time_zone(regional_office_timezone)
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

  def readable_location
    if request_type == LegacyHearing::CO_HEARING
      return "Washington, DC"
    end

    regional_office_name
  end

  def readable_request_type
    Hearing::HEARING_TYPES[request_type.to_sym]
  end

  cache_attribute :cached_number_of_documents do
    begin
      number_of_documents
    rescue Caseflow::Error::EfolderError, VBMS::HTTPError
      nil
    end
  end

  def to_hash(current_user_id)
    ::LegacyHearingSerializer.default(
      self,
      params: { current_user_id: current_user_id }
    ).serializable_hash[:data][:attributes]
  end

  alias quick_to_hash to_hash

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
    ::LegacyHearingSerializer.worksheet(
      self,
      params: { current_user_id: current_user_id }
    ).serializable_hash[:data][:attributes]
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

  # Sometimes, hearings get deleted in VACOLS, but not in Caseflow. Caseflow ends up
  # with dangling legacy hearings records.
  #
  # See: https://github.com/department-of-veterans-affairs/caseflow/issues/12003
  def vacols_hearing_exists?
    begin
      self.class.repository.load_vacols_data(self)
      true
    rescue Caseflow::Error::VacolsRecordNotFound => error
      capture_exception(error)
      false
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
      hearing = legacy_hearing || find_or_initialize_by(vacols_id: vacols_record.hearing_pkseq)

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

  private

  def assign_created_by_user
    self.created_by ||= RequestStore[:current_user]
  end

  def assign_updated_by_user
    self.updated_by ||= RequestStore[:current_user]
  end
end
