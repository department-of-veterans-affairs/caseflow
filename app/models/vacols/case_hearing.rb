class VACOLS::CaseHearing < VACOLS::Record
  self.table_name = "vacols.hearsched"
  self.primary_key = "stafkey"

  HEARING_TYPES = {
    V: :video,
    T: :travel,
    C: :central_office
  }.freeze

end
