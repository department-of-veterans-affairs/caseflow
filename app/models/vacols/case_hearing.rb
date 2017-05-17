class VACOLS::CaseHearing < VACOLS::Record
  self.table_name = "vacols.hearsched"
  self.primary_key = "hearing_pkseq"

  has_one :staff, foreign_key: :sattyid, primary_key: :board_member

  HEARING_TYPES = {
    V: :video,
    T: :travel,
    C: :central_office
  }.freeze

  def self.for_judge(vacols_user_id)
    id = connection.quote(vacols_user_id)
    joins(:staff).where("stafkey = #{id}")
  end
end
