# frozen_string_literal: true

class VACOLS::Diary < VACOLS::Record
  self.table_name = "vacols.assign"
  self.primary_key = "tsktknm"
end
