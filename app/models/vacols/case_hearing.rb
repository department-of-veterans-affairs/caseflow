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
  def self.upcoming_for_judge(vacols_user_id, date_diff: 7.days)
    id = connection.quote(vacols_user_id)

    select("VACOLS.HEARING_VENUE(vdkey) as hearing_venue",
           :hearing_disp,
           :hearing_pkseq,
           :hearing_date,
           :hearing_type,
           :notes1,
           :folder_nr,
           :vdkey,
           :sattyid)
      .joins(:staff)
      .where("staff.stafkey = #{id}")
      .where(WITHOUT_DISPOSITION_OR_AFTER_DATE,
             relative_vacols_date(date_diff).to_formatted_s(:oracle_date))
      .where(NOT_MASTER_RECORD)
  end
  # :nocov:
end
