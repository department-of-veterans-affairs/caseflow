# frozen_string_literal: true

class VACOLS::Diary < VACOLS::Record
  self.table_name = "assign"
  self.primary_key = "tsktknm"
end
