# frozen_string_literal: true

##
# The Veteran/Appellant, often with a representative, has a hearing with a Veterans Law Judge(VLJ) to
# provide additional details for their appeal. In this case the appeal is LegacyAppeal meaning it was filed
# before Appeals Improvement and Modernization Act (AMA) was passed.
#
# If the veterans/appellants opt in to have a hearing for their appeal process, an open ScheduleHearingTask is
# created to track the the status of hearings. Hearings are created when a hearing coordinator
# schedules the veteran/apellant for a hearing completing the open ScheduleHearingTask.
#
# There are four types of hearings: travel board, in-person (also known as Central), video and virtual. Unlike the
# other types, virtual type has VirtualHearing model which tracks additional details about virtual conference and
# emails. Travel board hearings are only worked on in VACOLS.
#
# The legacy hearings which are scheduled through caseflow are organized by a HearingDay by regional office and
# a room but all data is updated both in Caseflow and VACOLS. Caseflow also stores legacy hearings which
# were created in VACOLS. For these, there is no corresponding HearingDay in caseflow but it exists in VACOLS.
#
# Legcay Hearings have a nil disposition unless the hearing is held, cancelled, postponed or the veteran/appellant
# does not show up for their hearing. AssignHearingDispositionTask is created after hearing has passed
# and allows users to set the disposition.
#
# Legacy Hearing has a HearingLocation where the hearing will place. If a hearing is virtual then it has EmailEvents
# which is a record of virtual hearing emails sent to different recipients.

class LegacyHearing < CaseflowRecord
  include CachedAttributes
  include AssociatedVacolsModel
  include AppealConcern
  include HasHearingTask
  include HasVirtualHearing
  include HearingLocationConcern
  include HearingTimeConcern
  include UpdatedByUserConcern
  include HearingConcern

  # When these instance variable getters are called, first check if we've
  # fetched the values from VACOLS. If not, first fetch all values and save them
  # This allows us to easily call `hearing.veteran_first_name` and dynamically
  # fetch the data from VACOLS if it does not already exist in memory
  vacols_attr_accessor :veteran_first_name, :veteran_middle_initial, :veteran_last_name
  vacols_attr_accessor :appellant_first_name, :appellant_middle_initial, :appellant_last_name

  # scheduled_for is the correct hearing date and time in Eastern Time for travel
  # board and video hearings, or in the user's (Hearing Coordinator) time zone for
  # central hearings; the transformation happens in HearingMapper.datetime_based_on_type
  vacols_attr_accessor :scheduled_for

  # request_type is the current value of HEARSCHED.HEARING_TYPE in VACOLS, but one
  # should use original_request_type to make sure we consistently get the value we
  # expect, as we are now writing to this field in VACOLS when we convert a legacy
  # hearing to and from virtual.
  vacols_attr_accessor :request_type

  vacols_attr_accessor :venue_key, :vacols_record, :disposition
  vacols_attr_accessor :aod, :hold_open, :transcript_requested, :notes, :add_on
  vacols_attr_accessor :transcript_sent_date, :appeal_vacols_id
  vacols_attr_accessor :representative_name, :hearing_day_vacols_id
  vacols_attr_accessor :docket_number, :appeal_type, :room, :bva_poc, :judge_id

  belongs_to :appeal, class_name: "LegacyAppeal"
  belongs_to :user # the judge
  belongs_to :created_by, class_name: "User"
  has_many :hearing_views, as: :hearing
  has_many :appeal_stream_snapshots, foreign_key: :hearing_id
  has_one :hearing_location, as: :hearing
  has_many :email_events, class_name: "SentHearingEmailEvent", foreign_key: :hearing_id

  alias_attribute :location, :hearing_location
  accepts_nested_attributes_for :hearing_location, reject_if: proc { |attributes| attributes.blank? }

  # this is used to cache appeal stream for hearings
  # when fetched intially.
  has_many :appeals, class_name: "LegacyAppeal", through: :appeal_stream_snapshots

  delegate :veteran_age, :veteran_gender, :vbms_id, :representative_address, :number_of_documents,
           :number_of_documents_after_certification, :appellant_tz, :representative_tz,
           :representative_type, :veteran, :veteran_file_number, :docket_name,
           :closest_regional_office, :available_hearing_locations, :veteran_email_address,
           :appellant_address, :appellant_address_line_1, :appellant_address_line_2, :appellant_city,
           :appellant_country, :appellant_state, :appellant_zip, :appellant_email_address,
           :appellant_relationship,
           to: :appeal,
           allow_nil: true
  delegate :external_id, to: :appeal, prefix: true

  delegate :timezone, :name, to: :regional_office, prefix: true

  before_create :assign_created_by_user

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
    (original_request_type == HearingDay::REQUEST_TYPES[:central] && scheduled_for.to_date < Date.new(2019, 1, 1)) ||
      (original_request_type == HearingDay::REQUEST_TYPES[:video] && scheduled_for.to_date < Date.new(2019, 4, 1))
  end

  def hearing_day_id
    if self[:hearing_day_id].nil? && hearing_day_vacols_id.present? && !hearing_day_id_refers_to_vacols_row?
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

  # The logic for this method is mirrored in `HearingRepository#regional_office_for_scheduled_timezone`.
  #
  # There is a constraint within the `HearingRepository` context that means that calling
  # `LegacyHearing#regional_office_Key` triggers an unnecessary call to VACOLS.
  def regional_office_key
    if original_request_type == HearingDay::REQUEST_TYPES[:travel] || hearing_day.nil?
      return (venue_key || appeal&.regional_office_key)
    end

    hearing_day&.regional_office || "C"
  end

  def request_type_location
    if original_request_type == HearingDay::REQUEST_TYPES[:central]
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

  def update_request_type_in_vacols(new_request_type)
    if VACOLS::CaseHearing::HEARING_TYPES.exclude? new_request_type
      fail HearingMapper::InvalidRequestTypeError, "\"#{new_request_type}\" is not a valid request type."
    end

    # update original_vacols_request_type if request_type is not virtual
    if request_type != VACOLS::CaseHearing::HEARING_TYPE_LOOKUP[:virtual]
      update!(original_vacols_request_type: request_type)
    end

    update_caseflow_and_vacols(request_type: new_request_type)
  end

  def readable_location
    if original_request_type == HearingDay::REQUEST_TYPES[:central]
      return "Washington, DC"
    end

    regional_office_name
  end

  def readable_request_type
    Hearing::HEARING_TYPES[original_request_type.to_sym]
  end

  def original_request_type
    original_vacols_request_type.presence || request_type
  end

  cache_attribute :cached_number_of_documents do
    begin
      number_of_documents
    rescue Caseflow::Error::EfolderError, VBMS::HTTPError
      nil
    end
  end

  def quick_to_hash(current_user_id)
    ::LegacyHearingSerializer.quick(
      self,
      params: { current_user_id: current_user_id }
    ).serializable_hash[:data][:attributes]
  end

  def to_hash(current_user_id)
    ::LegacyHearingSerializer.default(
      self,
      params: { current_user_id: current_user_id }
    ).serializable_hash[:data][:attributes]
  end

  def to_hash_for_worksheet(current_user_id)
    ::LegacyHearingSerializer.worksheet(
      self,
      params: { current_user_id: current_user_id }
    ).serializable_hash[:data][:attributes]
  end

  def serialized_email_events
    email_events.order(sent_at: :desc).map do |event|
      SentEmailEventSerializer.new(event).serializable_hash[:data][:attributes]
    end
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

  def appeals_ready_for_hearing
    active_appeal_streams.map(&:attributes_for_hearing)
  end

  def current_issue_count
    active_appeal_streams
      .map(&:worksheet_issues)
      .flatten
      .count do |issue|
        !(issue.deleted? || (issue.disposition && issue.disposition =~ /Remand/ && issue.from_vacols?))
      end
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
      Raven.capture_exception(error)
      false
    end
  end

  class << self
    def cache_key_for_field(field, vacols_id)
      "legacy_hearing_#{field}_#{vacols_id}"
    end

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
          user: User.find_by_css_id(vacols_record.css_id)
        )
      end

      hearing
    end
  end

  private

  def assign_created_by_user
    self.created_by ||= RequestStore[:current_user]
  end
end
