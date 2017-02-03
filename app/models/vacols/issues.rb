class VACOLS::Issues < VACOLS::Record
  self.table_name = "vacols.issues"
  self.sequence_name = "vacols.issseq"
  self.primary_key = "isskey"

  DISPOSITION_CODE = {
    "1" => "Grant",
    "3" => "Remand"
  }.freeze
end
