# frozen_string_literal: true

class VACOLS::DecisionQualityReview < VACOLS::Record
  self.table_name = "#{Rails.application.config.vacols_db_name}.qrdecs"
end
