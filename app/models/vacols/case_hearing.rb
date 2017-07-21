class VACOLS::CaseHearing < VACOLS::Record
  self.table_name = "vacols.hearsched"
  self.primary_key = "hearing_pkseq"

  has_one :staff, foreign_key: :sattyid, primary_key: :board_member
  has_one :brieff, foreign_key: :bfkey, primary_key: :folder_nr

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
    notes: "NOTES1",
    disposition: "HEARING_DISP",
    hold_open: "HOLDDAYS",
    aod: "AOD",
    transcript_requested: "TRANREQ"
  }.freeze

  NOT_MASTER_RECORD = %(
    vdkey is NOT NULL
  ).freeze

  WITHOUT_DISPOSITION_OR_AFTER_DATE = %{
    hearing_date >= to_date(?, 'YYYY-MM-DD HH24:MI')
    -- Hearing is after a provided date (a recent hearing)

    OR hearing_disp IS NULL
    -- an older hearing still awaiting a disposition
  }.freeze

  # :nocov:
  class << self
    def upcoming_for_judge(vacols_user_id, date_diff: 7.days)
      id = connection.quote(vacols_user_id)

      select_hearings
        .where("staff.stafkey = #{id}")
        .where(WITHOUT_DISPOSITION_OR_AFTER_DATE,
               relative_vacols_date(date_diff).to_formatted_s(:oracle_date))
        .where(NOT_MASTER_RECORD)
    end

    def for_appeal(appeal_vacols_id)
      select_hearings.where(folder_nr: appeal_vacols_id)
    end

    def update_hearing!(pkseq, hearing_info)
      conn = connection

      MetricsService.record("VACOLS: update_hearing! #{pkseq}",
                            service: :vacols,
                            name: "update_hearing") do
        conn.transaction do
          conn.execute(<<-SQL)
            UPDATE HEARSCHED
            SET #{hearing_values(hearing_info)}
            WHERE HEARING_PKSEQ = #{pkseq}
          SQL
        end
      end
    end

    private

    def hearing_values(hearing_info)
      hearing_info.inject("") do |result, value|
        result << TABLE_NAMES[value[0]] + " = " + connection.quote(value[1])
        result << ", " unless value[0] == hearing_info.keys.last
        result
      end
    end

    def select_hearings
      # VACOLS overloads the HEARSCHED table with other types of hearings
      # that work differently. Filter those out.
      select("VACOLS.HEARING_VENUE(vdkey) as hearing_venue",
             "staff.stafkey as user_id",
             :hearing_disp,
             :hearing_pkseq,
             :hearing_date,
             :hearing_type,
             :notes1,
             :folder_nr,
             :vdkey,
             :aod,
             :holddays,
             :tranreq,
             :sattyid)
        .joins("left outer join vacols.staff on staff.sattyid = board_member")
        .where(hearing_type: HEARING_TYPES.keys)
    end
  end

  # :nocov:
end
