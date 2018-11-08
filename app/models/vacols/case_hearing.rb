class VACOLS::CaseHearing < VACOLS::Record
  self.table_name = "vacols.hearsched"
  self.primary_key = "hearing_pkseq"
  self.sequence_name = "hearsched_pkseq"

  attribute :hearing_date, :datetime
  validates :hearing_type, :hearing_date, :room, presence: true, on: :create

  has_one :staff, foreign_key: :sattyid, primary_key: :board_member
  has_one :brieff, foreign_key: :bfkey, primary_key: :folder_nr, class_name: "Case"

  HEARING_TYPES = {
    V: :video,
    T: :travel,
    C: :central_office
  }.freeze

  HEARING_DISPOSITIONS = {
    H: :held,
    C: :cancelled,
    P: :postponed,
    N: :no_show
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
    room_info: :room,
    room: :room,
    hearing_date: :hearing_date,
    hearing_type: :hearing_type,
    judge_id: :board_member,
    folder_nr: :folder_nr,
    board_member: :board_member,
    team: :team
  }.freeze

  after_update :update_hearing_action, if: :hearing_disp_changed?
  after_update :create_or_update_diaries

  # :nocov:
  class << self
    def hearings_for_judge(css_id)
      id = connection.quote(css_id.upcase)

      select_hearings.where("staff.sdomainid = #{id}")
        .where("hearing_date > ?", 1.year.ago.beginning_of_day)
    end

    def find_hearing_day(hearing_pkseq)
      select_schedule_days.find_by(hearing_pkseq: hearing_pkseq)
    end

    def video_hearings_for_master_record(parent_hearing_pkseq)
      select_hearings.where(vdkey: parent_hearing_pkseq)
    end

    def co_hearings_for_master_record(parent_hearing_date)
      select_hearings.where("hearing_type = ? and folder_nr NOT LIKE ? and trunc(hearing_date) between ? and ?",
                            "C", "%VIDEO%", parent_hearing_date.to_date,
                            (parent_hearing_date + 1.day).to_date)
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

    def load_days_for_range(start_date, end_date)
      select_schedule_days.where("trunc(hearing_date) between ? and ?", start_date, end_date).order(:hearing_date)
    end

    def load_days_for_central_office(start_date, end_date)
      select_schedule_days.where("hearing_type = ? and (folder_nr NOT LIKE ? OR folder_nr IS NULL) " \
                                  "and trunc(hearing_date) between ? and ?",
                                 "C", "%VIDEO%", VacolsHelper.day_only_str(start_date),
                                 VacolsHelper.day_only_str(end_date)).order(:hearing_date)
    end

    def load_days_for_regional_office(regional_office, start_date, end_date)
      select_schedule_days.where("folder_nr = ? and trunc(hearing_date) between ? and ?",
                                 "VIDEO #{regional_office}", VacolsHelper.day_only_str(start_date),
                                 VacolsHelper.day_only_str(end_date)).order(:hearing_date)
    end

    def create_hearing!(hearing_info)
      attrs = hearing_info.each_with_object({}) { |(k, v), result| result[COLUMN_NAMES[k]] = v }
      attrs.except!(nil)
      # Store time value in UTC to VACOLS
      hear_date = attrs[:hearing_date]
      converted_date = hear_date.is_a?(Date) ? hear_date : Time.zone.parse(hear_date).to_datetime
      attrs[:hearing_date] = VacolsHelper.format_datetime_with_utc_timezone(converted_date)
      MetricsService.record("VACOLS: create_hearing!",
                            service: :vacols,
                            name: "create_hearing") do
        create(attrs.merge(addtime: VacolsHelper.local_time_with_utc_timezone,
                           adduser: current_user_slogid,
                           folder_nr: hearing_info[:regional_office] ? "VIDEO #{hearing_info[:regional_office]}" : nil,
                           hearing_type: "C"))
      end
    end

    def create_child_hearing!(hearing_info)
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
      select("VACOLS.HEARING_VENUE(vdkey) as hearing_venue",
             "staff.sdomainid as css_id",
             :hearing_disp, :hearing_pkseq,
             :hearing_date, :hearing_type,
             :notes1, :folder_nr,
             :vdkey, :aod,
             :holddays, :tranreq, :transent,
             :repname, :addon,
             :board_member, :mduser,
             :mdtime, :sattyid,
             :bfregoff, :bfso,
             :bfcorkey, :bfddec, :bfdc,
             "staff.slogid",
             "corres.snamef, corres.snamemi",
             "corres.snamel, corres.sspare1",
             "corres.sspare2, corres.sspare3")
        .joins("left outer join vacols.staff on staff.sattyid = board_member")
        .joins("left outer join vacols.brieff on brieff.bfkey = folder_nr")
        .joins("left outer join vacols.corres on corres.stafkey = bfcorkey")
        .where(hearing_type: HEARING_TYPES.keys)
    end

    def select_schedule_days
      select(:hearing_pkseq,
             :hearing_date, :vdbvapoc,
             "CASE WHEN folder_nr LIKE 'VIDEO%' THEN 'V' ELSE hearing_type END AS hearing_type",
             "CASE WHEN folder_nr LIKE 'VIDEO%' or folder_nr is null THEN folder_nr ELSE null END AS folder_nr",
             :room,
             :board_member,
             "snamel as judge_last_name",
             "snamemi as judge_middle_name",
             "snamef as judge_first_name",
             "snamel || CASE WHEN snamel IS NULL THEN '' ELSE ', ' END || snamef AS judge_name",
             :mduser,
             :mdtime)
        .joins("left outer join vacols.staff on staff.sattyid = board_member")
        .where("hearing_type = ? and (folder_nr != ? or folder_nr is null)", "C", "1779233")
    end
  end

  def master_record_type
    return :video if folder_nr =~ /VIDEO/
  end

  def update_hearing!(hearing_info)
    attrs = hearing_info.each_with_object({}) { |(k, v), result| result[COLUMN_NAMES[k]] = v }
    MetricsService.record("VACOLS: update_hearing! #{hearing_pkseq}",
                          service: :vacols,
                          name: "update_hearing") do
      update(attrs.merge(mduser: self.class.current_user_slogid, mdtime: VacolsHelper.local_time_with_utc_timezone))
    end
  end

  private

  def current_user_css_id
    @css_id ||= RequestStore.store[:current_user].css_id.upcase
  end

  def update_hearing_action
    brieff.update(bfha: HearingMapper.bfha_vacols_code(self))
  end

  def create_or_update_diaries
    create_or_update_extension_diary if holddays_changed?
    create_or_update_aod_diary if aod_changed?
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
  # :nocov:
end
