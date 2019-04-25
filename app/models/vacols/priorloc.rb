# frozen_string_literal: true

class VACOLS::Priorloc < VACOLS::Record
  self.table_name = "#{Rails.application.config.vacols_db_name}.priorloc"
  self.primary_key = "lockey"
end
