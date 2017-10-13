class VACOLS::CaseHearing < VACOLS::Record
  self.table_name = "vacols.hearsched"
  self.primary_key = "hearing_pkseq"

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

  TABLE_NAMES = {
    notes: :notes1,
    disposition: :hearing_disp,
    hold_open: :holddays,
    aod: :aod,
    transcript_requested: :tranreq,
    add_on: :addon,
    representative_name: :repname
  }.freeze

  after_update :update_hearing_action, if: :hearing_disp_changed?
  after_update :create_or_update_diaries

  # :nocov:
  class << self
    def upcoming_for_judge(css_id)
      id = connection.quote(css_id)

      select_hearings.where("staff.sdomainid = #{id}")
                     .where("hearing_date > ?", 1.week.ago)
    end

    def for_appeal(appeal_vacols_id)
      select_hearings.where(folder_nr: appeal_vacols_id)
    end

    def load_hearing(pkseq)
      select_hearings.find_by(hearing_pkseq: pkseq)
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
             :holddays, :tranreq,
             :repname, :addon,
             :board_member, :mduser,
             :mdtime, :sattyid,
             :bfregoff, :bfso)
        .joins("left outer join vacols.staff on staff.sattyid = board_member")
        .joins("left outer join vacols.brieff on brieff.bfkey = folder_nr")
        .where(hearing_type: HEARING_TYPES.keys)
    end
  end

  def master_record_type
    return :video if folder_nr =~ /VIDEO/
  end

  def update_hearing!(hearing_info)
    slogid = staff.try(:slogid)
    attrs = hearing_info.each_with_object({}) { |(k, v), result| result[TABLE_NAMES[k]] = v }
    MetricsService.record("VACOLS: update_hearing! #{hearing_pkseq}",
                          service: :vacols,
                          name: "update_hearing") do
      update(attrs.merge(mduser: slogid, mdtime: VacolsHelper.local_time_with_utc_timezone))
    end
  end

  private

  def update_hearing_action
    brieff.update(bfha: HearingMapper.bfha_vacols_code(self))
  end

  def create_or_update_diaries
    create_or_update_abeyance_diary if holddays_changed?
    create_or_update_aod_diary if aod_changed?
  end

  def current_user_css_id
    @css_id ||= RequestStore.store[:current_user].css_id.upcase
  end

  def case_id
    @case_id ||= brieff.bfkey
  end

  def create_or_update_abeyance_diary
    # If hold open is set to nil or 0, delete the diary
    return delete_diary([:A]) if !holddays || holddays == 0

    VACOLS::Note.update_or_create!(case_id: case_id,
                                   text: "Record held open by VLJ at hearing for additional evidence.",
                                   code: :A,
                                   days_to_complete: holddays + 5,
                                   days_til_due: holddays + 5,
                                   assigned_to: VACOLS::Note.assignee(:A),
                                   user_id: current_user_css_id)
  end

  def create_or_update_aod_diary
    # If the representative is the Paralyzed Veterans of America (BRIEFF.BFSO = 'G'),
    # then a second diary entry should be created
    codes = brieff.bfso == "G" ? [:B, :B1] : [:B]
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
