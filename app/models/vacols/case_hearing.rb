# frozen_string_literal: true

class VACOLS::CaseHearing < VACOLS::Record
  self.table_name = "hearsched"
  self.primary_key = "hearing_pkseq"
  self.sequence_name = "hearsched_pkseq"

  attribute :hearing_date, :datetime
  validates :hearing_type, :hearing_date, :room, presence: true, on: :create

  has_one :staff, foreign_key: :sattyid, primary_key: :board_member
  has_one :brieff, foreign_key: :bfkey, primary_key: :folder_nr, class_name: "Case"

  HEARING_TYPES = %w[V T C].freeze

  HEARING_DISPOSITIONS = {
    H: Constants.HEARING_DISPOSITION_TYPES.held,
    C: Constants.HEARING_DISPOSITION_TYPES.cancelled,
    P: Constants.HEARING_DISPOSITION_TYPES.postponed,
    N: Constants.HEARING_DISPOSITION_TYPES.no_show
  }.freeze

  HEARING_AODS = {
    G: :granted,
    Y: :filed,
    N: :none
  }.freeze

  BOOLEAN_MAP = {
    N: false,
    Y: true
  }.freeze

  COLUMN_NAMES = {
    notes: :notes1,
    disposition: :hearing_disp,
    hold_open: :holddays,
    aod: :aod,
    transcript_requested: :tranreq,
    add_on: :addon,
    representative_name: :repname,
    staff_id: :mduser,
    room: :room,
    scheduled_for: :hearing_date,
    request_type: :hearing_type,
    judge_id: :board_member,
    folder_nr: :folder_nr,
    board_member: :board_member,
    team: :team,
    bva_poc: :vdbvapoc
  }.freeze

  after_update :update_hearing_action, if: :saved_change_to_hearing_disp?
  after_update :create_or_update_diaries

  class << self
    def hearings_for_hearing_days(hearing_day_ids)
      select_hearings.where(vdkey: hearing_day_ids).where("hearing_date > ?", Date.new(2019, 1, 1))
    end

    def hearings_for_hearing_days_assigned_to_judge(hearing_day_ids, judge)
      id = connection.quote(judge.css_id.upcase)

      select_hearings.where(vdkey: hearing_day_ids)
        .where("hearing_date > ?", Date.new(2019, 1, 1))
        .where("staff.sdomainid = #{id}")
    end

    def for_appeal(appeal_vacols_id)
      select_hearings.where(folder_nr: appeal_vacols_id)
    end

    def for_appeals(vacols_ids)
      hearings = select_hearings.where(folder_nr: vacols_ids)

      hearings.reduce({}) do |memo, result|
        hearing_key = result["folder_nr"].to_s
        memo[hearing_key] = (memo[hearing_key] || []) << result
        memo
      end
    end

    def load_hearing(pkseq)
      select_hearings.find_by(hearing_pkseq: pkseq)
    end

    def create_hearing!(hearing_info)
      MetricsService.record("VACOLS: create_hearing!",
                            service: :vacols,
                            name: "create_hearing") do
        create!(hearing_info.merge(addtime: VacolsHelper.local_time_with_utc_timezone,
                                   adduser: current_user_slogid))
      end
    end

    private

    def select_hearings
      # VACOLS overloads the HEARSCHED table with other types of hearings
      # that work differently. Filter those out.
      select("#{Rails.application.config.vacols_db_name}.HEARING_VENUE(vdkey) as hearing_venue",
             :hearing_disp, :hearing_pkseq, :hearing_date, :hearing_type,
             :notes1, :folder_nr, :vdkey, :aod,
             :holddays, :tranreq, :transent,
             :repname, :addon,  :board_member, :mduser,
             :mdtime, :sattyid, :bfregoff, :bfso,
             :bfcorkey, :bfddec, :bfdc, :room, :vdbvapoc,
             "staff.sdomainid as css_id", "brieff.bfac", "staff.slogid",
             "corres.saddrst1", "corres.saddrst2", "corres.saddrcty",
             "corres.saddrstt", "corres.saddrcnty", "corres.saddrzip",
             "corres.snamef, corres.snamemi", "corres.snamel, corres.sspare1",
             "corres.sspare2, corres.sspare3, folder.tinum")
        .joins("left outer join staff on staff.sattyid = board_member")
        .joins("left outer join brieff on brieff.bfkey = folder_nr")
        .joins("left outer join folder on folder.ticknum = brieff.bfkey")
        .joins("left outer join corres on corres.stafkey = bfcorkey")
        .where(hearing_type: HEARING_TYPES)
    end
  end

  def scheduled_for
    hearing_date
  end

  def request_type
    hearing_type
  end

  def judge_id
    board_member
  end

  def master_record_type
    :video if folder_nr&.include?("VIDEO")
  end

  def update_hearing!(hearing_info)
    attrs = hearing_info.each_with_object({}) { |(k, v), result| result[COLUMN_NAMES[k]] = v }
    MetricsService.record("VACOLS: update_hearing! #{hearing_pkseq}",
                          service: :vacols,
                          name: "update_hearing") do
      update(attrs.merge(mduser: self.class.current_user_slogid, mdtime: VacolsHelper.local_time_with_utc_timezone))
    end
  end

  def current_user_css_id
    @current_user_css_id ||= RequestStore.store[:current_user].css_id.upcase
  end

  def update_hearing_action
    brieff.update(bfha: HearingMapper.bfha_vacols_code(self))
  end

  def create_or_update_diaries
    create_or_update_extension_diary if saved_change_to_holddays?
    create_or_update_aod_diary if saved_change_to_aod?
  end

  def case_id
    @case_id ||= brieff.bfkey
  end

  def create_or_update_extension_diary
    # If hold open is set to nil or 0, delete the diary
    # We have to hardcode the assignee to 25 because not all ext diaries should default to 25
    return delete_diary([:EXT]) if !holddays || holddays == 0

    VACOLS::Note.update_or_create!(case_id: case_id,
                                   text: "Record held open by VLJ at hearing for additional evidence.",
                                   code: :EXT,
                                   days_to_complete: holddays + 5,
                                   days_til_due: holddays + 5,
                                   assigned_to: "25",
                                   user_id: current_user_css_id)
  end

  def create_or_update_aod_diary
    # If the representative is the Paralyzed Veterans of America (BRIEFF.BFSO = 'G'),
    # then a second diary entry should be created
    codes = (brieff.bfso == "G") ? [:B, :B1] : [:B]
    # If aod is nil or :none, delete the diary
    return delete_diary(codes) if !aod || aod == "N"

    codes.each do |code|
      days = VACOLS::Note.default_number_of_days(code).try(:to_i)
      VACOLS::Note.update_or_create!(case_id: case_id,
                                     text: "AOD granted on Record during hearing.",
                                     code: code,
                                     days_to_complete: days,
                                     days_til_due: days,
                                     assigned_to: VACOLS::Note.assignee(code),
                                     user_id: current_user_css_id)
    end
  end

  def delete_diary(codes)
    codes.each do |code|
      VACOLS::Note.delete!(case_id: brieff.bfkey,
                           code: code,
                           user_id: current_user_css_id)
    end
  end
end
