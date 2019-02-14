class Hearing < ApplicationRecord
  belongs_to :hearing_day
  belongs_to :appeal
  belongs_to :judge, class_name: "User"
  has_one :transcription
  has_many :hearing_views, as: :hearing
  has_one :hearing_location, as: :hearing
  has_many :hearing_issue_notes

  accepts_nested_attributes_for :hearing_issue_notes
  accepts_nested_attributes_for :transcription
  accepts_nested_attributes_for :hearing_location

  alias_attribute :location, :hearing_location
  alias_attribute :regional_office_key, :hearing_day_regional_office

  UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/.freeze

  delegate :request_type, to: :hearing_day
  delegate :veteran_first_name, to: :appeal
  delegate :veteran_last_name, to: :appeal
  delegate :appellant_first_name, to: :appeal
  delegate :appellant_last_name, to: :appeal
  delegate :appellant_city, to: :appeal
  delegate :appellant_state, to: :appeal
  delegate :veteran_age, to: :appeal
  delegate :veteran_gender, to: :appeal
  delegate :veteran_file_number, to: :appeal
  delegate :docket_number, to: :appeal
  delegate :docket_name, to: :appeal
  delegate :request_issues, to: :appeal
  delegate :decision_issues, to: :appeal
  delegate :veteran_available_hearing_locations, to: :appeal
  delegate :veteran_closest_regional_office, to: :appeal
  delegate :representative_name, to: :appeal, prefix: true
  delegate :external_id, to: :appeal, prefix: true
  delegate :regional_office, to: :hearing_day, prefix: true

  after_create :update_fields_from_hearing_day

  HEARING_TYPES = {
    V: "Video",
    T: "Travel",
    C: "Central"
  }.freeze

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

  def readable_request_type
    HEARING_TYPES[request_type.to_sym]
  end

  def master_record
    false
  end

  def scheduled_for
    DateTime.new.in_time_zone(regional_office_timezone).change(
      year: hearing_day.scheduled_for.year,
      month: hearing_day.scheduled_for.month,
      day: hearing_day.scheduled_for.day,
      hour: scheduled_time.hour,
      min: scheduled_time.min,
      sec: scheduled_time.sec
    )
  end

  def worksheet_issues
    request_issues.map do |request_issue|
      HearingIssueNote.select("*").joins(:request_issue)
        .find_or_create_by(request_issue: request_issue, hearing: self).to_hash
    end
  end

  #:nocov:
  # This is all fake data that will be refactored in a future PR.
  def regional_office_name
    RegionalOffice::CITIES[regional_office_key][:label] unless regional_office_key.nil?
  end

  def regional_office_timezone
    RegionalOffice::CITIES[regional_office_key][:timezone] unless regional_office_key.nil?
    "America/New_York"
  end

  def current_issue_count
    1
  end
  #:nocov:

  def slot_new_hearing(hearing_day_id, hearing_location_attrs: nil, **_args)
    # These fields are needed for the legacy hearing's version of this method
    hearing = Hearing.create!(
      hearing_day_id: hearing_day_id,
      scheduled_time: scheduled_time,
      appeal: appeal
    )

    hearing.update(hearing_location_attributes: hearing_location_attrs) unless hearing_location_attrs.nil?
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

  # rubocop:disable Metrics/MethodLength
  def to_hash(_current_user_id)
    serializable_hash(
      methods: [
        :external_id,
        :veteran_first_name,
        :veteran_last_name,
        :appellant_first_name,
        :appellant_last_name,
        :appellant_city,
        :appellant_state,
        :regional_office_key,
        :regional_office_name,
        :regional_office_timezone,
        :readable_request_type,
        :scheduled_for,
        :veteran_age,
        :veteran_gender,
        :appeal_external_id,
        :veteran_file_number,
        :evidence_window_waived,
        :bva_poc,
        :room,
        :transcription,
        :docket_number,
        :docket_name,
        :military_service,
        :current_issue_count,
        :appeal_representative_name,
        :location,
        :worksheet_issues,
        :veteran_closest_regional_office,
        :veteran_available_hearing_locations
      ]
    )
  end
  # rubocop:enable Metrics/MethodLength

  def to_hash_for_worksheet(current_user_id)
    serializable_hash(
      methods: [:judge]
    ).merge(to_hash(current_user_id))
  end
end
