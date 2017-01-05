class VACOLS::Issues < VACOLS::Record
  self.table_name = "vacols.issues"
  self.sequence_name = "vacols.issseq"
  self.primary_key = "isskey"


  GRANT_TYPE = {
    "1" => "Full",
    "3" => "Remand"
  }.freeze
end
