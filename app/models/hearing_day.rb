# frozen_string_literal: true

##
# HearingDay groups hearings, both AMA and legacy, by a regional office and a room at the BVA.
# Hearing Admin can create a HearingDay either individually or in bulk at the begining of
# each year by uploading bunch of spreadsheets.
#
# Each HearingDay has a request type which applies to all hearings associated for that day.
# Request types:
#   'V' (also known as video hearing):
#       The veteran/appellant travels to a regional office to have a hearing through video conference
#       with a VLJ (Veterans Law Judge) who joins from the board at Washington D.C.
#   'C' (also known as Central):
#       The veteran/appellant travels to the board in D.C to have a in-person hearing with the VLJ.
#   'T' (also known as travel board)
#       The VLJ travels to the the Veteran/Appellant's closest regional office to conduct the hearing.
#
# If the request type is video('V'), then the HearingDay has a regional office associated.
# Currently, a video hearing can be switched to a virtual hearing represented by VirtualHearing.
#
# Each HearingDay has a maximum number of hearings that can be held which is either based on the
# timezone of associated regional office or 12 if the request type is central('C).
#
# A HearingDay can be assigned to a judge.

class HearingDay < CaseflowRecord
  include UpdatedByUserConcern

  acts_as_paranoid

  belongs_to :judge, class_name: "User"
  belongs_to :created_by, class_name: "User"
  has_many :hearings, -> { not_scheduled_in_error }

  class HearingDayHasChildrenRecords < StandardError; end

  REQUEST_TYPES = Constants::HEARING_REQUEST_TYPES.with_indifferent_access.freeze

  SLOTS_BY_REQUEST_TYPE = {
    REQUEST_TYPES[:central] => 10,
    REQUEST_TYPES[:virtual] => 8 # TBD. Dummy value for testing until we know more.
  }.freeze

  SLOTS_BY_TIMEZONE = {
    "America/New_York" => 12,
    "America/Chicago" => 12,
    "America/Indiana/Indianapolis" => 12,
    "America/Kentucky/Louisville" => 12,
    "America/Denver" => 12,
    "America/Phoenix" => 12,
    "America/Los_Angeles" => 12,
    "America/Boise" => 12,
    "America/Puerto_Rico" => 12,
    "Asia/Manila" => 12,
    "Pacific/Honolulu" => 12,
    "America/Anchorage" => 12
  }.freeze

  before_create :assign_created_by_user
  after_update :update_children_records

  # Validates if the judge id maps to an actual record.
  validates :judge, presence: true, if: -> { judge_id.present? }

  validates :regional_office, absence: true, if: :central_office_or_virtual?
  validates :regional_office,
            inclusion: {
              in: RegionalOffice.all.map(&:key),
              message: "key (%<value>s) is invalid"
            },
            unless: :central_office_or_virtual?

  validates :request_type,
            inclusion: {
              in: REQUEST_TYPES.values,
              message: "is invalid"
            }

  def central_office?
    request_type == REQUEST_TYPES[:central]
  end

  def central_office_or_virtual?
    [REQUEST_TYPES[:central], REQUEST_TYPES[:virtual]].include?(request_type)
  end

  def scheduled_for_as_date
    scheduled_for.to_date
  end

  def confirm_no_children_records
    fail HearingDayHasChildrenRecords if !vacols_hearings.empty? || !hearings.empty?
  end

  def vacols_hearings
    HearingRepository.fetch_hearings_for_parent(id)
  end

  def open_hearings
    closed_hearing_dispositions = [
      Constants.HEARING_DISPOSITION_TYPES.postponed,
      Constants.HEARING_DISPOSITION_TYPES.cancelled,
      Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error
    ]

    (hearings + vacols_hearings).reject { |hearing| closed_hearing_dispositions.include?(hearing.disposition) }
  end

  def hearings_for_user(current_user)
    caseflow_and_vacols_hearings = vacols_hearings + hearings

    if current_user.vso_employee?
      caseflow_and_vacols_hearings = caseflow_and_vacols_hearings.select do |hearing|
        hearing.assigned_to_vso?(current_user)
      end
    end

    if current_user.roles.include?("Hearing Prep")
      caseflow_and_vacols_hearings = caseflow_and_vacols_hearings.select do |hearing|
        hearing.assigned_to_judge?(current_user)
      end
    end

    caseflow_and_vacols_hearings
  end

  def to_hash
    video_hearing_days_request_types = if VirtualHearing::VALID_REQUEST_TYPES.include? request_type
                                         HearingDayRequestTypeQuery
                                           .new(HearingDay.where(id: id))
                                           .call
                                       else
                                         {}
                                       end

    ::HearingDaySerializer.new(
      self,
      params: { video_hearing_days_request_types: video_hearing_days_request_types }
    ).serializable_hash[:data][:attributes]
  end

  def hearing_day_full?
    lock || open_hearings.count >= total_slots
  end

  def total_slots
    return SLOTS_BY_REQUEST_TYPE[request_type] if central_office_or_virtual?

    SLOTS_BY_TIMEZONE[RegionalOffice.find!(regional_office).timezone]
  end

  def judge_first_name
    judge ? judge.full_name.split(" ").first : nil
  end

  def judge_last_name
    judge ? judge.full_name.split(" ").last : nil
  end

  private

  def assign_created_by_user
    self.created_by ||= RequestStore[:current_user]
  end

  def update_children_records
    vacols_hearings.each do |hearing|
      hearing.update_caseflow_and_vacols(
        **only_changed(room: room, bva_poc: bva_poc, judge_id: judge&.id)
      )
    end

    hearings.each do |hearing|
      hearing.update!(
        **only_changed(room: room, bva_poc: bva_poc, judge_id: judge&.id)
      )
    end
  end

  def only_changed(possibles_hash)
    changed_hash = {}
    possibles_hash.each_key do |key|
      changed_hash[key] = possibles_hash[key] if saved_changes.key?(key)
    end

    changed_hash
  end

  class << self
    def create_schedule(scheduled_hearings)
      scheduled_hearings.each do |hearing_hash|
        HearingDay.create(hearing_hash)
      end
    end

    def update_schedule(updated_hearing_days)
      updated_hearing_days.each do |hearing_day|
        HearingDay.find(hearing_day.id).update!(
          judge: User.find_by_css_id_or_create_with_default_station_id(hearing_day.judge.css_id)
        )
      end
    end

    private

    def current_user_css_id
      RequestStore.store[:current_user].css_id.upcase
    end
  end
end
