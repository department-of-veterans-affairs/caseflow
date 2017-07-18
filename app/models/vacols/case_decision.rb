class VACOLS::CaseDecision < VACOLS::Record
  self.table_name "vacols.decass"
  self.primary_key = "defolder"

  has_one :case, foreign_key: :bfkey
end