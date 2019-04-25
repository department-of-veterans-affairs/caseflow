# frozen_string_literal: true

class VACOLS::Vftypes < VACOLS::Record
  self.table_name = "#{Rails.application.config.vacols_db_name}.vftypes"
  self.primary_key = "ftkey"
end
