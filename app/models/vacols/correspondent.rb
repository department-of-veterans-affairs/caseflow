# frozen_string_literal: true

class VACOLS::Correspondent < VACOLS::Record
  self.table_name = "corres"
  self.primary_key = "stafkey"

  has_many :cases, foreign_key: :bfcorkey
end
