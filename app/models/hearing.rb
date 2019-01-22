class Hearing < ApplicationRecord
  belongs_to :hearing_day
  belongs_to :appeal
  belongs_to :judge, class_name: "User"
  has_one :transcription
  has_many :hearing_views, as: :hearing

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
  delegate :representative_name, to: :appeal, prefix: true
  delegate :external_id, to: :appeal, prefix: true

  accepts_nested_attributes_for :transcription, allow_destroy: true

  HEARING_TYPES = {
    V: "Video",
    T: "Travel",
    C: "Central"
  }.freeze

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

  #:nocov:
  # This is all fake data that will be refactored in a future PR.
  def regional_office_key
    "RO19"
  end

  def regional_office_name
    "Winston-Salem, NC"
  end

  def regional_office_timezone
    "America/New_York"
  end

  def current_issue_count
    1
  end
  #:nocov:

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
        :regional_office_name,
        :regional_office_timezone,
        :readable_request_type,
        :judge,
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
        :appeal_representative_name
      ]
    )
  end
  # rubocop:enable Metrics/MethodLength

  def to_hash_for_worksheet(current_user_id)
    to_hash(current_user_id)
  end
end
