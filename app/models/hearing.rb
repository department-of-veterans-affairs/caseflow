# frozen_string_literal: true

class Hearing < ApplicationRecord
  include HasVirtualHearing

  belongs_to :hearing_day
  belongs_to :appeal
  belongs_to :judge, class_name: "User"
  belongs_to :created_by, class_name: "User"
  belongs_to :updated_by, class_name: "User"
  has_one :transcription
  has_many :hearing_views, as: :hearing
  has_one :hearing_location, as: :hearing
  has_one :hearing_task_association,
          -> { includes(:hearing_task).where(tasks: { status: Task.open_statuses }) },
          as: :hearing
  has_many :hearing_issue_notes

  class HearingDayFull < StandardError; end

  accepts_nested_attributes_for :hearing_issue_notes
  accepts_nested_attributes_for :transcription
  accepts_nested_attributes_for :hearing_location

  alias_attribute :location, :hearing_location

  UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/.freeze

  delegate :request_type, to: :hearing_day
  delegate :veteran_first_name, to: :appeal
  delegate :veteran_last_name, to: :appeal
  delegate :appellant_first_name, to: :appeal
  delegate :appellant_last_name, to: :appeal
  delegate :appellant_address_line_1, to: :appeal
  delegate :appellant_city, to: :appeal
  delegate :appellant_state, to: :appeal
  delegate :appellant_zip, to: :appeal
  delegate :veteran_age, to: :appeal
  delegate :veteran_gender, to: :appeal
  delegate :veteran_file_number, to: :appeal
  delegate :veteran_email_address, to: :appeal
  delegate :docket_number, to: :appeal
  delegate :docket_name, to: :appeal
  delegate :request_issues, to: :appeal
  delegate :decision_issues, to: :appeal
  delegate :available_hearing_locations, :closest_regional_office, :advanced_on_docket?, to: :appeal
  delegate :external_id, to: :appeal, prefix: true
  delegate :regional_office, to: :hearing_day, prefix: true
  delegate :hearing_day_full?, to: :hearing_day
  delegate :timezone, :name, to: :regional_office, prefix: true

  after_create :update_fields_from_hearing_day
  before_create :check_available_slots, unless: :override_full_hearing_day_validation
  before_create :assign_created_by_user
  before_update :assign_updated_by_user

  attr_accessor :override_full_hearing_day_validation

  HEARING_TYPES = {
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

  def hearing_task?
    !hearing_task_association.nil?
  end

  def disposition_task
    if hearing_task?
      hearing_task_association.hearing_task.children.detect { |child| child.type == AssignHearingDispositionTask.name }
    end
  end

  def disposition_task_in_progress
    disposition_task ? disposition_task.open_with_no_children? : false
  end

  def disposition_editable
    disposition_task_in_progress || !hearing_task?
  end

  def representative
    appeal.representative_name
  end

  def representative_email_address
    appeal&.representative_email_address
  end

  def claimant_id
    return nil if appeal.appellant.nil?

    Person.find_by(participant_id: appeal.appellant.participant_id).id
  end

  def advance_on_docket_motion
    # we're only really interested if the AOD was granted
    AdvanceOnDocketMotion.where(person_id: claimant_id).order("granted DESC NULLS LAST").first
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
    # saved as 13:30 (with the eastern time +5 offset added) rather than 16:30
    # (with the pacific time +8 offset added).
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

  def time
    @time ||= HearingTimeService.new(hearing: self)
  end

  delegate :central_office_time_string, :scheduled_time_string, to: :time

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

  private

  def assign_created_by_user
    self.created_by ||= RequestStore[:current_user]
  end

  def assign_updated_by_user
    self.updated_by ||= RequestStore[:current_user]
  end
end
