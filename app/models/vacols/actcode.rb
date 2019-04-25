# frozen_string_literal: true

class VACOLS::Actcode < VACOLS::Record
  self.table_name = "#{Rails.application.config.vacols_db_name}.actcode"
  self.primary_key = "actckey"
end
