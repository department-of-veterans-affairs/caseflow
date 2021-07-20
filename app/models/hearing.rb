# frozen_string_literal: true

##
# The Veteran/Appellant, often with a representative, has a hearing with a Veterans Law Judge(VLJ) to
# provide additional details for their appeal. In this case the appeal is an AMA Appeal meaning it was filed
# after Appeals Improvement and Modernization Act (AMA) was passed.
#
# If the veterans/appellants opt in to have a hearing for their appeal process, an open ScheduleHearingTask is
# created to track the the status of hearings. Hearings are created when a hearing coordinator
# schedules the veteran/apellant for a hearing by completing the open ScheduleHearingTask.
#
# There are four types of hearings: travel board, in-person (also known as Central), video and virtual. Unlike the
# other types, virtual type has VirtualHearing model which tracks additional details about virtual conference
# and emails. Travel board hearings are only worked on in VACOLS.
#
# Hearings have a nil disposition unless the hearing is held, cancelled, postponed or the veteran/appellant
# does not show up for their hearing. AssignHearingDispositionTask is created after hearing has passed
# and allows users to set the disposition.
#
# A HearingDay organizes hearings by regional office and a room. Hearing has a HearingLocation where the
# hearing will place as well as a Trascription which is the trascribed record of the hearing if hearing was held.
# If a hearing is virtual then it has EmailEvents which is a record of virtual hearing emails sent to
# different recipients.

class Hearing < CaseflowRecord
  include HasHearingTask
  include HasVirtualHearing
  include HearingTimeConcern
  include HearingLocationConcern
  include HasSimpleAppealUpdatedSince
  include UpdatedByUserConcern
  include HearingConcern
  include HasHearingEmailRecipientsConcern

  belongs_to :hearing_day
  belongs_to :appeal
  belongs_to :judge, class_name: "User"
  belongs_to :created_by, class_name: "User"
  has_one :transcription, -> { order(created_at: :desc) }
  has_many :hearing_views, as: :hearing
  has_one :hearing_location, as: :hearing
  has_many :hearing_issue_notes
  has_many :email_events, class_name: "SentHearingEmailEvent"
  has_many :email_recipients, class_name: "HearingEmailRecipient"

  class HearingDayFull < StandardError; end

  accepts_nested_attributes_for :hearing_issue_notes
  accepts_nested_attributes_for :transcription, reject_if: proc { |attributes| attributes.blank? }
  accepts_nested_attributes_for :hearing_location, reject_if: proc { |attributes| attributes.blank? }

  alias_attribute :location, :hearing_location

  UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/.freeze

  delegate :appellant_first_name, :appellant_last_name, :representative_address,
           :representative_type, :appellant_city, :appellant_state, :appellant_relationship,
           :appellant_zip, :appellant_address_line_1, :appellant_email_address, :appellant_tz,
           :representative_tz, :veteran_age, :veteran_gender, :veteran_first_name,
           :veteran_last_name, :veteran_file_number, :veteran_email_address, :docket_number,
           :docket_name, :request_issues, :decision_issues, :available_hearing_locations,
           :closest_regional_office, :advanced_on_docket?,
           to: :appeal
  delegate :external_id, to: :appeal, prefix: true
  delegate :hearing_day_full?, :request_type, to: :hearing_day
  delegate :regional_office, to: :hearing_day, prefix: true
  delegate :timezone, :name, to: :regional_office, prefix: true

  after_create :update_fields_from_hearing_day
  before_create :check_available_slots, unless: :override_full_hearing_day_validation
  before_create :assign_created_by_user

  attr_accessor :override_full_hearing_day_validation

  scope :with_no_disposition, -> { where(disposition: nil) }
  scope :not_scheduled_in_error,
        lambda {
          where(
            "disposition != ? or disposition is null",
            Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error
          )
        }

  HEARING_TYPES = {
    R: "Virtual",
    V: "Video",
    T: "Travel",
    C: "Central"
  }.freeze

  def check_available_slots
    fail HearingDayFull if hearing_day_full?
  end

  def update_fields_from_hearing_day
    update!(judge: hearing_day.judge, room: hearing_day.room, bva_poc: hearing_day.bva_poc)
  end

  def self.find_hearing_by_uuid_or_vacols_id(id)
    if UUID_REGEX.match?(id)
      find_by_uuid!(id)
    else
      LegacyHearing.find_by!(vacols_id: id)
    end
  end

  def readable_location
    return "Washington, DC" if request_type == HearingDay::REQUEST_TYPES[:central]
    return "#{location.city}, #{location.state}" if location

    nil
  end

  def readable_request_type
    HEARING_TYPES[request_type.to_sym]
  end

  alias original_request_type request_type

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

  def representative
    appeal.representative_name
  end

  def representative_email_address
    appeal&.representative_email_address
  end

  def claimant_id
    return nil if appeal.appellant.nil?

    appeal.appellant.person.id
  end

  def aod?
    advance_on_docket_motion.present?
  end

  def advance_on_docket_motion
    # we're only really interested if the AOD was granted
    AdvanceOnDocketMotion
      .for_person(claimant_id)
      .order("granted DESC NULLS LAST, created_at DESC")
      .first
  end

  def scheduled_for
    # returns the date and time a hearing is scheduled for in the regional office's
    # time zone
    #
    # When a hearing is scheduled, we save the hearing time to the scheduled_time
    # field. The time is converted to UTC upon save *relative to the timezone of
    # the user who saved it*, not relative to the timezone of the RO where the
    # veteran will attend the hearing. For example, if a user in New York
    # schedules an 8:30am hearing for a veteran in Los Angeles, the time will be
    # saved as 13:30 (with the eastern time -5 offset added) rather than 16:30
    # (with the pacific time -8 offset added).
    #
    # The offset will *always* be +5 for a user in the eastern time zone,
    # regardless of when the hearing is scheduled, because Rails associates a
    # date of 01 Jan 2000 with the time whenever it's read from the database.
    # Because that date did not fall during daylight savings time, the conversion
    # remains the same no matter what time of year it's done.
    #
    # So when we need to display the time the hearing is scheduled for, we have
    # to explicitly convert it to the time zone of the person who scheduled it,
    # then assemble and return a TimeWithZone object cast to the regional
    # office's time zone.

    updated_by_timezone = updated_by&.timezone || Time.zone.name
    scheduled_time_in_updated_by_timezone = scheduled_time.utc.in_time_zone(updated_by_timezone)

    Time.use_zone(regional_office_timezone) do
      Time.zone.local(
        hearing_day.scheduled_for.year,
        hearing_day.scheduled_for.month,
        hearing_day.scheduled_for.day,
        scheduled_time_in_updated_by_timezone.hour,
        scheduled_time_in_updated_by_timezone.min,
        scheduled_time_in_updated_by_timezone.sec
      )
    end
  end

  def scheduled_for_past?
    scheduled_for < DateTime.yesterday.in_time_zone(regional_office_timezone)
  end

  def worksheet_issues
    request_issues.map do |request_issue|
      HearingIssueNote.joins(:request_issue)
        .find_or_create_by(request_issue: request_issue, hearing: self).to_hash
    end
  end

  def regional_office
    @regional_office ||= begin
                            RegionalOffice.find!(regional_office_key)
                         rescue RegionalOffice::NotFoundError
                           nil
                          end
  end

  def regional_office_key
    hearing_day_regional_office || "C"
  end

  def current_issue_count
    request_issues.size
  end

  def external_id
    uuid
  end

  def military_service
    super || begin
      update(military_service: appeal.veteran.periods_of_service.join("\n")) if persisted? && appeal.veteran
      super
    end
  end

  def quick_to_hash(_current_user_id)
    ::HearingSerializer.quick(self).serializable_hash[:data][:attributes]
  end

  def to_hash(_current_user_id)
    ::HearingSerializer.default(self).serializable_hash[:data][:attributes]
  end

  def to_hash_for_worksheet(_current_user_id)
    ::HearingSerializer.worksheet(self).serializable_hash[:data][:attributes]
  end

  def serialized_email_events
    email_events.order(sent_at: :desc).map do |event|
      SentEmailEventSerializer.new(event).serializable_hash[:data][:attributes]
    end
  end

  private

  def assign_created_by_user
    self.created_by ||= RequestStore[:current_user]
  end
end
