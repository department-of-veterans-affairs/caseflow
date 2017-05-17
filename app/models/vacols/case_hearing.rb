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

  def self.for_judge(vacols_user_id)
    id = connection.quote(vacols_user_id)

    select("VACOLS.HEARING_VENUE(vdkey) as hearing_venue",
           :hearing_disp,
           :hearing_pkseq,
           :hearing_date,
           :hearing_type,
           :notes1,
           :folder_nr,
           :sattyid)
    .joins(:staff)
    .where("stafkey = #{id}")
  end
end
