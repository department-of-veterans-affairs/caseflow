class VACOLS::Folder < VACOLS::Record
  self.table_name = "vacols.folder"
  self.primary_key = "ticknum"

  has_one :outcoder, foreign_key: :slogid, primary_key: :tiocuser, class_name: "Staff"
end
